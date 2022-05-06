
# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import (is_not_zero)
from starkware.cairo.common.uint256 import (Uint256, uint256_le)

from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner
)

##########################
## Events
##########################
@event
func entity_created(id: felt):
end

##########################
## Structs
##########################
# Supports Arweave
# Arweave uses 43 characters
struct EntityContentLink:
    member Part1: felt
    member Part2: felt
end

struct EntityPOI:
    member id: felt # Entity POI Kind from pois list
    member asset_id: Uint256 # For L1 <-> L2 compatibility 
end

struct EntityProp:
    member id: felt # Entity POI Kind from pois list
    member value: felt
end

struct WhitelistElem:
    member id: felt
    member is_whitelisted: felt
end

##########################
## Module Controller
##########################
# One Ring to Rule Them All
@storage_var
func module_controller_address() -> (address: felt):
end

##########################
## Infrastructure
##########################
# Validates POIs ranges
# Replaceable for new logic
@storage_var
func validator_address() -> (address: felt):
end

# Restrict creating Entity by some rules defined in the future
# Replaceable for new logic
@storage_var
func restrictor_address() -> (address: felt):
end

##########################
## Entity
##########################
# Counter for sequential IDs
@storage_var
func last_entity_id() -> (last_entity_id: felt):
end

@storage_var
func entity_content_links(id: felt, revision_id: felt) -> (value: EntityContentLink):
end

@storage_var
func entity_owners(id: felt) -> (owner: felt):
end

@storage_var
func last_entity_revision(entity_id: felt) -> (value: felt):
end

##########################
## Kinds
##########################
# Arbitrary
# 0 - scroll
# 1 - drawing/canvas
# 2 - song
# 3 - etc.
@storage_var
func whitelisted_kinds(id: felt) -> (is_whitelisted: felt):
end

@storage_var
func entity_kinds(entity_id: felt) -> (kind: felt):
end

##########################
## POIs
##########################
@storage_var
func whitelisted_pois(id: felt) -> (is_whitelisted: felt):
end

# append only - works in tandem with entity_revision_pois_mapping
@storage_var
func entities_to_pois(entity_id: felt, poi_index: felt) -> (poi: EntityPOI):
end

# starts with 0
@storage_var
func entity_pois_length(entity_id: felt) -> (value: felt):
end

@storage_var
func entity_revision_pois_mapping(entity_id: felt, revision_id: felt, poi_index: felt) -> (is_removed: felt):
end

##########################
## Props (for Eras, etc.)
##########################
@storage_var
func whitelisted_props(id: felt) -> (is_whitelisted: felt):
end

@storage_var
func entities_to_props(entity_id: felt, prop_index: felt) -> (prop: EntityProp):
end

@storage_var
func entity_props_length(entity_id: felt) -> (value: felt):
end

@storage_var
func entity_revision_props_mapping(entity_id: felt, revision_id: felt, poi_index: felt) -> (is_removed: felt):
end

##########################
## Constructor
##########################
@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owner: felt,
        module_controller_addr: felt
    ):
    Ownable_initializer(owner)
    module_controller_address.write(module_controller_addr)
    return ()
end

##########################
## Entities
##########################
@external
func create_entity{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        content_link: EntityContentLink,
        kind: felt,
        pois_len: felt,
        pois: EntityPOI*,
        props_len: felt,
        props: EntityProp*
    ) -> (id: felt):
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

    if kind != 0:
        let (is_kind_whitelisted) = whitelisted_kinds.read(kind)
        assert is_kind_whitelisted = 1
        entity_kinds.write(new_entity_id, kind)
    end
    
    # Save the Entity with revision 1
    tempvar new_revision_id = 1
    # last_entity_revision.write(new_entity_id, new_revision_id)

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

func save_pois_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        entity_id: felt,
        last_poi_index: felt,
        pois_len: felt,
        pois: EntityPOI*
    ) -> ():
    alloc_locals

    if pois_len == 0:
        return ()
    end

    # Check if POI kind is in list
    let poi = [pois]

    # Protect
    let (is_whitelisted) = whitelisted_pois.read(poi.id)
    assert is_whitelisted = 1

    entities_to_pois.write(entity_id, last_poi_index, poi)

    return save_pois_loop(entity_id, last_poi_index + 1, pois_len - 1, pois + EntityPOI.SIZE)
end

func save_props_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        entity_id: felt,
        last_prop_index: felt,
        props_len: felt,
        props: EntityProp*
    ) -> ():
    alloc_locals

    if props_len == 0:
        return ()
    end

    # Check if POI kind is in list
    let prop = [props]

    # Protect
    let (is_whitelisted) = whitelisted_props.read(prop.id)
    assert is_whitelisted = 1

    entities_to_props.write(entity_id, last_prop_index, prop)

    return save_props_loop(entity_id, last_prop_index + 1, props_len - 1, props + EntityProp.SIZE)
end

##########################
## Revisions
##########################
@external
func add_revision{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        entity_id: felt,
        content_link: EntityContentLink,
        pois_len: felt,
        pois: EntityPOI*,
        props_len: felt,
        props: EntityProp*
    ) -> (revision_id: felt):
    alloc_locals

    # Checking for at least two (Arweave)
    assert_not_zero(content_link.Part1)
    assert_not_zero(content_link.Part2)

    # Check Owner
    let (owner) = entity_owners.read(entity_id)
    let (caller) = get_caller_address()
    assert owner = caller

    # TODO: write it using mapping method
    return (0)
end

##########################
## Addresses
##########################
@external
func update_validator{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        new_address: felt
    ) -> ():
    Ownable_only_owner()

    validator_address.write(new_address)

    return ()
end

@external
func update_restrictor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        new_address: felt
    ) -> ():
    Ownable_only_owner()

    restrictor_address.write(new_address)

    return ()
end

##########################
## Whitelisting
##########################
@external
func whitelist_kinds{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        kinds_len: felt,
        kinds: WhitelistElem*
    ) -> ():
    Ownable_only_owner()

    whitelist_kinds_loop(kinds_len, kinds)

    return ()
end

func whitelist_kinds_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        kinds_len: felt,
        kinds: WhitelistElem*,
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
## POIs Whitelisting
##########################
@external
func whitelist_pois{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        pois_len: felt,
        pois: WhitelistElem*
    ) -> ():
    Ownable_only_owner()

    whitelist_pois_loop(pois_len, pois)

    return ()
end

func whitelist_pois_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        pois_len: felt,
        pois: WhitelistElem*
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
## props Whitelisting
##########################
@external
func whitelist_props{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        props_len: felt,
        props: WhitelistElem*
    ) -> ():
    Ownable_only_owner()

    whitelist_props_loop(props_len, props)

    return ()
end

func whitelist_props_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        props_len: felt,
        props: WhitelistElem*
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
## Views for Entity
##########################
@view
func get_last_entity_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
    ) -> (last_entity_id: felt):
    let (last_id) = last_entity_id.read()

    return (last_id)
end

@view
func get_entity{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        entity_id: felt,
        revision_id: felt
    ) -> (owner: felt, content: EntityContentLink, kind: felt, pois_len: felt, pois: EntityPOI*, props_len: felt, props: EntityProp*):
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
    let (pois: EntityPOI*) = alloc()
    get_entity_pois_loop(entity_id, 0, entity_pois_len, pois)

    # Get props
    let (entity_props_len) = entity_props_length.read(entity_id)
    let (props: EntityProp*) = alloc()
    get_entity_props_loop(entity_id, 0, entity_props_len, props)
    
    return (entity_owner, entity_content, entity_kind, entity_pois_len, pois, entity_props_len, props)
end

func get_entity_pois_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        entity_id: felt,
        poi_index: felt,
        pois_len: felt,
        pois: EntityPOI*
    ) -> ():
    alloc_locals

    if pois_len == 0:
        return ()
    end

    let (poi) = entities_to_pois.read(entity_id, poi_index)
    assert pois[poi_index] = poi # Strange way of assigning values to array

    return get_entity_pois_loop(entity_id, poi_index + 1, pois_len - 1, pois)
end

func get_entity_props_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        entity_id: felt,
        prop_index: felt,
        props_len: felt,
        props: EntityProp*
    ) -> ():
    alloc_locals

    if props_len == 0:
        return ()
    end

    let (prop) = entities_to_props.read(entity_id, prop_index)
    assert props[prop_index] = prop # Strange way of assigning values to array

    get_entity_props_loop(entity_id, prop_index + 1, props_len - 1, props)

    return ()
end