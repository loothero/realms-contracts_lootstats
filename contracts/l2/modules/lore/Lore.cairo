# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_eq

from openzeppelin.utils.constants import TRUE, FALSE
from openzeppelin.access.ownable import Ownable_initializer, Ownable_only_owner

from contracts.l2.modules.lore.ILoreValidator import ILoreValidator
from contracts.l2.modules.lore.ILoreRestrictor import ILoreRestrictor

from openzeppelin.upgrades.library import (
    Proxy_initializer,
    Proxy_only_admin,
    Proxy_set_implementation,
)

##########################
# # Events
##########################
@event
func entity_created(id : felt):
end

@event
func entity_revision_created(entity_id : felt, revision_id : felt):
end

##########################
# # Structs
##########################
# Supports Arweave
# Arweave uses 43 characters
struct EntityContentLink:
    member Part1 : felt
    member Part2 : felt
end

struct EntityPOI:
    member id : felt  # Entity POI Kind from pois list
    member asset_id : Uint256  # For L1 <-> L2 compatibility
end

struct EntityProp:
    member id : felt  # Entity POI Kind from pois list
    member value : felt
end

struct WhitelistElem:
    member id : felt
    member is_whitelisted : felt
end

##########################
# # Module Controller
##########################
# One Ring to Rule Them All
@storage_var
func module_controller_address() -> (address : felt):
end

##########################
# # Infrastructure
##########################
# Validates POIs ranges
# Replaceable for new logic
@storage_var
func validator_address() -> (address : felt):
end

# Restrict creating Entity by some rules defined in the future
# Replaceable for new logic
@storage_var
func restrictor_address() -> (address : felt):
end

##########################
# # Entity
##########################
# Counter for sequential IDs
@storage_var
func last_entity_id() -> (last_entity_id : felt):
end

@storage_var
func entity_content_links(id : felt, revision_id : felt) -> (value : EntityContentLink):
end

@storage_var
func entity_owners(id : felt) -> (owner : felt):
end

@storage_var
func last_entity_revision(entity_id : felt) -> (value : felt):
end

##########################
# # Kinds
##########################
# Arbitrary
# 0 - scroll
# 1 - drawing/canvas
# 2 - song
# 3 - etc.
@storage_var
func whitelisted_kinds(id : felt) -> (is_whitelisted : felt):
end

@storage_var
func entity_kinds(entity_id : felt) -> (kind : felt):
end

##########################
# # POIs
##########################
@storage_var
func whitelisted_pois(id : felt) -> (is_whitelisted : felt):
end

# append only - works in tandem with entity_revision_pois_mapping
@storage_var
func entities_to_pois(entity_id : felt, poi_index : felt) -> (poi : EntityPOI):
end

# starts with 0
@storage_var
func entity_pois_length(entity_id : felt) -> (value : felt):
end

@storage_var
func pois_to_remove_from_revision(entity_id : felt, revision_id : felt, poi_index : felt) -> (
    is_removed : felt
):
end

##########################
# # Props (for Eras, etc.)
##########################
@storage_var
func whitelisted_props(id : felt) -> (is_whitelisted : felt):
end

@storage_var
func entities_to_props(entity_id : felt, prop_index : felt) -> (prop : EntityProp):
end

@storage_var
func entity_props_length(entity_id : felt) -> (value : felt):
end

@storage_var
func props_to_remove_from_revision(entity_id : felt, revision_id : felt, prop_index : felt) -> (
    is_removed : felt
):
end

###############
# CONSTRUCTOR #
###############

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proxy_admin : felt
):
    Ownable_initializer(proxy_admin)
    Proxy_initializer(proxy_admin)
    return ()
end

@external
func upgrade{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation : felt
):
    Proxy_only_admin()
    Proxy_set_implementation(new_implementation)
    return ()
end

##########################
# # Entities
##########################

@external
func create_entity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    content_link : EntityContentLink,
    kind : felt,
    pois_len : felt,
    pois : EntityPOI*,
    props_len : felt,
    props : EntityProp*,
) -> (id : felt):
    alloc_locals

    # Checking for at least two (Arweave)
    assert_not_zero(content_link.Part1)
    assert_not_zero(content_link.Part2)

    # Get next index + update index counter per token_id
    # Starting with 1 for user friendliness
    let (last_id) = last_entity_id.read()
    tempvar new_entity_id = last_id + 1
    last_entity_id.write(new_entity_id)

    # Write the owner
    let (caller) = get_caller_address()
    entity_owners.write(new_entity_id, caller)

    # Check $LORDS amount for adding entities?
    # let (restrictor_addr) = restrictor_address.read()
    # if restrictor_addr != 0:
    #     let (ok) = ILoreRestrictor.check(restrictor_addr, caller)
    #     assert ok = TRUE
    # end

    if kind != 0:
        let (is_kind_whitelisted) = whitelisted_kinds.read(kind)
        assert is_kind_whitelisted = TRUE
        entity_kinds.write(new_entity_id, kind)
    end

    # Save the Entity with revision 1
    tempvar new_revision_id = 1
    last_entity_revision.write(new_entity_id, new_revision_id)

    # Save link
    entity_content_links.write(new_entity_id, new_revision_id, content_link)

    # Save Entity's POIs
    save_pois_loop(new_entity_id, 0, pois_len, pois)
    entity_pois_length.write(new_entity_id, pois_len)

    # Save Entity's props
    save_props_loop(new_entity_id, 0, props_len, props)
    entity_props_length.write(new_entity_id, props_len)

    # Emit the event
    entity_created.emit(new_entity_id)

    return (new_entity_id)
end

##########################
# # Revisions
##########################

# ) -> (to_add_len: felt, to_add: EntityPOI*, to_remove_len: felt, to_remove: EntityPOI*):
# ) -> (len: felt, len1: felt):
@external
func add_revision{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt,
    content_link : EntityContentLink,
    pois_len : felt,
    pois : EntityPOI*,
    props_len : felt,
    props : EntityProp*,
) -> (revision_id : felt):
    alloc_locals

    # Checking for at least two (Arweave)
    assert_not_zero(content_link.Part1)
    assert_not_zero(content_link.Part2)

    # Check Owner
    let (owner) = entity_owners.read(entity_id)
    let (caller) = get_caller_address()
    assert owner = caller

    # Get new revision ID
    let (last_revision_id) = last_entity_revision.read(entity_id)
    tempvar new_revision_id = last_revision_id + 1
    last_entity_revision.write(entity_id, new_revision_id)

    # Write content links
    entity_content_links.write(entity_id, new_revision_id, content_link)

    # Handle new POIs
    let (all_pois_len, all_pois) = get_all_pois(entity_id)

    # # POIs to add
    let (pois_to_add_len, pois_to_add) = poi_diff(pois_len, pois, all_pois_len, all_pois)
    save_pois_loop(entity_id, all_pois_len, pois_to_add_len, pois_to_add)
    entity_pois_length.write(entity_id, all_pois_len + pois_to_add_len)
    # # To remove
    let (pois_to_remove_len, pois_to_remove) = poi_diff(all_pois_len, all_pois, pois_len, pois)
    remove_pois_for_revision(
        entity_id, new_revision_id, all_pois_len, all_pois, pois_to_remove_len, pois_to_remove
    )

    # Handle new Props
    let (all_props_len, all_props) = get_all_props(entity_id)

    # # Props to add
    let (props_to_add_len, props_to_add) = prop_diff(props_len, props, all_props_len, all_props)
    save_props_loop(entity_id, all_props_len, props_to_add_len, props_to_add)

    # # Props to remove
    let (props_to_remove_len, props_to_remove) = prop_diff(
        all_props_len, all_props, props_len, props
    )
    remove_props_for_revision(
        entity_id, new_revision_id, all_props_len, all_props, props_to_remove_len, props_to_remove
    )

    entity_revision_created.emit(entity_id, new_revision_id)

    return (new_revision_id)
end

##########################
# # POIs helpers
##########################
func save_pois_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt, last_poi_index : felt, len : felt, pois : EntityPOI*
) -> ():
    alloc_locals

    if len == 0:
        return ()
    end

    # Check if POI kind is in list
    let poi = [pois]

    # Whitelisting protection
    let (is_whitelisted) = whitelisted_pois.read(poi.id)
    assert is_whitelisted = TRUE

    # Asset ID protection
    let (ok) = validate_poi(poi)
    assert ok = TRUE

    entities_to_pois.write(entity_id, last_poi_index, poi)

    return save_pois_loop(entity_id, last_poi_index + 1, len - 1, pois + EntityPOI.SIZE)
end

func validate_poi{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    poi : EntityPOI
) -> (ok : felt):
    alloc_locals

    let (validator_addr) = validator_address.read()

    if validator_addr == 0:
        return (TRUE)
    end

    let (ok) = ILoreValidator.check_poi(validator_addr, poi.id, poi.asset_id)
    return (ok)
end

func remove_pois_for_revision{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt,
    revision_id : felt,
    all_pois_len : felt,
    all_pois : EntityPOI*,
    pois_to_remove_len : felt,
    pois_to_remove : EntityPOI*,
) -> ():
    alloc_locals

    if pois_to_remove_len == 0:
        return ()
    end

    let poi = [pois_to_remove]

    let (index) = poi_find_index(poi, 0, all_pois_len, all_pois)

    pois_to_remove_from_revision.write(entity_id, revision_id, index, 1)

    return remove_pois_for_revision(
        entity_id,
        revision_id,
        all_pois_len,
        all_pois,
        pois_to_remove_len - 1,
        pois_to_remove + EntityPOI.SIZE,
    )
end

func get_all_pois{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt
) -> (len : felt, arr : EntityPOI*):
    alloc_locals

    let (len) = entity_pois_length.read(entity_id)

    let (arr : EntityPOI*) = alloc()
    get_all_pois_loop(entity_id, 0, len, arr)

    return (len, arr)
end

func get_all_pois_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt, index : felt, arr_len : felt, arr : EntityPOI*
) -> ():
    alloc_locals

    if arr_len == 0:
        return ()
    end

    let (elem) = entities_to_pois.read(entity_id, index)

    assert arr[index] = elem

    return get_all_pois_loop(entity_id, index + 1, arr_len - 1, arr)
end

func poi_diff{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    a_len : felt, a : EntityPOI*, b_len : felt, b : EntityPOI*
) -> (diff_len : felt, diff : EntityPOI*):
    alloc_locals

    let (diff : EntityPOI*) = alloc()
    let (diff_len) = poi_diff_loop(a_len, a, b_len, b, 0, 0, diff)

    return (diff_len, diff)
end

func poi_diff_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    a_len : felt,
    a : EntityPOI*,
    b_len : felt,
    b : EntityPOI*,
    diff_index : felt,
    diff_len : felt,
    diff : EntityPOI*,
) -> (diff_len : felt):
    alloc_locals

    if a_len == 0:
        return (diff_len)
    end

    let a_elem = [a]

    let (local found) = poi_find_occurrence(a_elem, b_len, b)

    if found == 0:
        assert diff[diff_index] = a_elem
        return poi_diff_loop(
            a_len - 1, a + EntityPOI.SIZE, b_len, b, diff_index + 1, diff_len + 1, diff
        )
    end

    return poi_diff_loop(a_len - 1, a + EntityPOI.SIZE, b_len, b, diff_index, diff_len, diff)
end

func poi_find_occurrence{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to_find : EntityPOI, arr_len : felt, arr : EntityPOI*
) -> (found : felt):
    alloc_locals

    if arr_len == 0:
        return (0)
    end

    let poi = [arr]

    if poi.id == to_find.id:
        let (assets_eq) = uint256_eq(poi.asset_id, to_find.asset_id)
        if assets_eq == TRUE:
            tempvar range_check_ptr = range_check_ptr
            return (1)
        else:
            tempvar range_check_ptr = range_check_ptr
        end
    else:
        tempvar range_check_ptr = range_check_ptr
    end

    return poi_find_occurrence(to_find, arr_len - 1, arr + EntityPOI.SIZE)
end

func poi_find_index{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to_find : EntityPOI, index : felt, arr_len : felt, arr : EntityPOI*
) -> (index : felt):
    alloc_locals

    if arr_len == 0:
        return (0)
    end

    let poi = [arr]

    if poi.id == to_find.id:
        let (assets_eq) = uint256_eq(poi.asset_id, to_find.asset_id)
        if assets_eq == TRUE:
            tempvar range_check_ptr = range_check_ptr
            return (index)
        else:
            tempvar range_check_ptr = range_check_ptr
        end
    else:
        tempvar range_check_ptr = range_check_ptr
    end

    return poi_find_index(to_find, index + 1, arr_len - 1, arr + EntityPOI.SIZE)
end

##########################
# # Props
##########################
func save_props_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt, last_prop_index : felt, props_len : felt, props : EntityProp*
) -> ():
    alloc_locals

    if props_len == 0:
        return ()
    end

    # Check if POI kind is in list
    let prop = [props]

    # Protect
    let (is_whitelisted) = whitelisted_props.read(prop.id)
    assert is_whitelisted = TRUE

    entities_to_props.write(entity_id, last_prop_index, prop)

    return save_props_loop(entity_id, last_prop_index + 1, props_len - 1, props + EntityProp.SIZE)
end

func get_all_props{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt
) -> (len : felt, arr : EntityProp*):
    alloc_locals

    let (len) = entity_props_length.read(entity_id)

    let (arr : EntityProp*) = alloc()
    get_all_props_loop(entity_id, 0, len, arr)

    return (len, arr)
end

func get_all_props_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt, index : felt, arr_len : felt, arr : EntityProp*
) -> ():
    alloc_locals

    if arr_len == 0:
        return ()
    end

    let (elem) = entities_to_props.read(entity_id, index)

    assert arr[index] = elem

    return get_all_props_loop(entity_id, index + 1, arr_len - 1, arr)
end

func prop_diff{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    a_len : felt, a : EntityProp*, b_len : felt, b : EntityProp*
) -> (diff_len : felt, diff : EntityProp*):
    alloc_locals

    let (diff : EntityProp*) = alloc()
    let (diff_len) = prop_diff_loop(a_len, a, b_len, b, 0, 0, diff)

    return (diff_len, diff)
end

func prop_diff_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    a_len : felt,
    a : EntityProp*,
    b_len : felt,
    b : EntityProp*,
    diff_index : felt,
    diff_len : felt,
    diff : EntityProp*,
) -> (diff_len : felt):
    alloc_locals

    if a_len == 0:
        return (diff_len)
    end

    let a_elem = [a]

    let (local found) = prop_find_occurrence(a_elem, b_len, b)

    if found == 0:
        assert diff[diff_index] = a_elem
        return prop_diff_loop(
            a_len - 1, a + EntityProp.SIZE, b_len, b, diff_index + 1, diff_len + 1, diff
        )
    end

    return prop_diff_loop(a_len - 1, a + EntityProp.SIZE, b_len, b, diff_index, diff_len, diff)
end

func prop_find_occurrence{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to_find : EntityProp, arr_len : felt, arr : EntityProp*
) -> (found : felt):
    alloc_locals

    if arr_len == 0:
        return (0)
    end

    let poi = [arr]

    if poi.id == to_find.id:
        if poi.value == to_find.value:
            tempvar range_check_ptr = range_check_ptr
            return (1)
        else:
            tempvar range_check_ptr = range_check_ptr
        end
    else:
        tempvar range_check_ptr = range_check_ptr
    end

    return prop_find_occurrence(to_find, arr_len - 1, arr + EntityProp.SIZE)
end

func prop_find_index{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    to_find : EntityProp, index : felt, arr_len : felt, arr : EntityProp*
) -> (index : felt):
    alloc_locals

    if arr_len == 0:
        return (0)
    end

    let poi = [arr]

    if poi.id == to_find.id:
        if poi.value == to_find.value:
            tempvar range_check_ptr = range_check_ptr
            return (index)
        else:
            tempvar range_check_ptr = range_check_ptr
        end
    else:
        tempvar range_check_ptr = range_check_ptr
    end

    return prop_find_index(to_find, index + 1, arr_len - 1, arr + EntityProp.SIZE)
end

func remove_props_for_revision{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt,
    revision_id : felt,
    all_props_len : felt,
    all_props : EntityProp*,
    props_to_remove_len : felt,
    props_to_remove : EntityProp*,
) -> ():
    alloc_locals

    if props_to_remove_len == 0:
        return ()
    end

    let poi = [props_to_remove]

    let (index) = prop_find_index(poi, 0, all_props_len, all_props)

    props_to_remove_from_revision.write(entity_id, revision_id, index, 1)

    return remove_props_for_revision(
        entity_id,
        revision_id,
        all_props_len,
        all_props,
        props_to_remove_len - 1,
        props_to_remove + EntityProp.SIZE,
    )
end

##########################
# # Addresses
##########################
@external
func update_validator{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_address : felt
) -> ():
    Ownable_only_owner()

    validator_address.write(new_address)

    return ()
end

@external
func update_restrictor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_address : felt
) -> ():
    Ownable_only_owner()

    restrictor_address.write(new_address)

    return ()
end

##########################
# # Whitelisting
##########################
@external
func whitelist_kinds{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    kinds_len : felt, kinds : WhitelistElem*
) -> ():
    Ownable_only_owner()

    whitelist_kinds_loop(kinds_len, kinds)

    return ()
end

func whitelist_kinds_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    kinds_len : felt, kinds : WhitelistElem*
) -> ():
    if kinds_len == 0:
        return ()
    end

    let elem = [kinds]

    whitelisted_kinds.write(elem.id, elem.is_whitelisted)

    whitelist_kinds_loop(kinds_len - 1, kinds + WhitelistElem.SIZE)

    return ()
end

##########################
# # POIs Whitelisting
##########################
@external
func whitelist_pois{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    pois_len : felt, pois : WhitelistElem*
) -> ():
    Ownable_only_owner()

    whitelist_pois_loop(pois_len, pois)

    return ()
end

func whitelist_pois_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    pois_len : felt, pois : WhitelistElem*
) -> ():
    if pois_len == 0:
        return ()
    end

    let elem = [pois]

    whitelisted_pois.write(elem.id, elem.is_whitelisted)

    whitelist_pois_loop(pois_len - 1, pois + WhitelistElem.SIZE)

    return ()
end

##########################
# # props Whitelisting
##########################
@external
func whitelist_props{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    props_len : felt, props : WhitelistElem*
) -> ():
    Ownable_only_owner()

    whitelist_props_loop(props_len, props)

    return ()
end

func whitelist_props_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    props_len : felt, props : WhitelistElem*
) -> ():
    if props_len == 0:
        return ()
    end

    let elem = [props]

    whitelisted_props.write(elem.id, elem.is_whitelisted)

    whitelist_props_loop(props_len - 1, props + WhitelistElem.SIZE)

    return ()
end

##########################
# # Views for Entity
##########################
@view
func get_last_entity_id{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    last_entity_id : felt
):
    let (last_id) = last_entity_id.read()

    return (last_id)
end

@view
func get_entity{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt, revision_id : felt
) -> (
    owner : felt,
    content : EntityContentLink,
    kind : felt,
    pois_len : felt,
    pois : EntityPOI*,
    props_len : felt,
    props : EntityProp*,
):
    alloc_locals

    # Get owner
    let (entity_owner) = entity_owners.read(entity_id)
    assert_not_zero(entity_owner)

    # Get Content
    let (entity_content) = entity_content_links.read(entity_id, revision_id)

    # Get Kind
    let (entity_kind) = entity_kinds.read(entity_id)

    # Get POIs
    let (entity_pois_len) = entity_pois_length.read(entity_id)
    let (pois : EntityPOI*) = alloc()
    let (pois_len) = get_entity_pois_loop(entity_id, revision_id, 0, entity_pois_len, 0, pois)

    # Get props
    let (entity_props_len) = entity_props_length.read(entity_id)
    let (props : EntityProp*) = alloc()
    get_entity_props_loop(entity_id, 0, entity_props_len, props)

    return (entity_owner, entity_content, entity_kind, pois_len, pois, entity_props_len, props)
end

func get_entity_pois_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt,
    revision_id : felt,
    all_pois_index : felt,
    all_pois_len : felt,
    pois_index : felt,
    pois : EntityPOI*,
) -> (index : felt):
    alloc_locals

    if all_pois_len == 0:
        return (pois_index)
    end

    let (poi) = entities_to_pois.read(entity_id, all_pois_index)

    let (removed) = pois_to_remove_from_revision.read(entity_id, revision_id, all_pois_index)

    if removed == 0:
        assert pois[pois_index] = poi
        return get_entity_pois_loop(
            entity_id, revision_id, all_pois_index + 1, all_pois_len - 1, pois_index + 1, pois
        )
    end

    return get_entity_pois_loop(
        entity_id, revision_id, all_pois_index + 1, all_pois_len - 1, pois_index, pois
    )
end

func get_entity_props_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    entity_id : felt, prop_index : felt, props_len : felt, props : EntityProp*
) -> ():
    alloc_locals

    if props_len == 0:
        return ()
    end

    let (prop) = entities_to_props.read(entity_id, prop_index)
    assert props[prop_index] = prop

    get_entity_props_loop(entity_id, prop_index + 1, props_len - 1, props)

    return ()
end
