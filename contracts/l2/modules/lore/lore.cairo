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

from contracts.token.IERC20 import IERC20

from contracts.Ownable_base import (
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
struct EntityContent:
    member ContentLinkPart1: felt
    member ContentLinkPart2: felt
end

struct EntityPOI:
    member poi_id: felt # Entity POI Kind from pois list
    member asset_id: Uint256 # For L1 <-> L2 compatibility 
end

# struct EntityRevisionPOI:
#     member poi_id: felt # Entity POI Kind from pois list
#     member asset_id: Uint256 # For L1 <-> L2 compatibility
#     member add_or_remove: felt # 0 for adding and 1 for removing from previous revision 
# end

struct EntityProp:
    member prop_id: felt # Entity POI Kind from pois list
    member prop_value: felt
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
func entity_ids() -> (value: felt):
end

@storage_var
func entity_contents(id: felt, revision_id: felt) -> (value: EntityContent):
end

@storage_var
func entity_owners(id: felt) -> (owner: felt):
end

@storage_var
func last_entity_revision(entity_id: felt) -> (value: felt):
end

struct EntityRevisionPOI:
    member poi_id: felt
    member asset_id: Uint256
    member add_or_remove: felt # 0 for adding, 1 for removing
end

@storage_var
func entity_revision_pois(entity_id: felt, revision_id: felt) -> (revision_poi: EntityRevisionPOI):
end

##########################
## Kinds
##########################
# Arbitrary
# 0 - scroll
# 1 - drawing
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
func entity_pois_last_indexes(entity_id: felt) -> (index: felt):
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
func entity_props_last_indexes(entity_id: felt) -> (index: felt):
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
        entity_content: EntityContent,
        entity_kind: felt,
        entity_pois_len: felt,
        entity_pois: EntityPOI*,
        entity_props_len: felt,
        entity_props: EntityProp*
    ) -> (entity_id: felt):
    alloc_locals

    # Checking for at least two (Arweave)
    assert_not_zero(entity_content.ContentLinkPart1)
    assert_not_zero(entity_content.ContentLinkPart2)

    # Get controller

    # Get next index + update index counter per token_id
    # Start with 1 instead of 0
    let (last_id) = entity_ids.read()
    tempvar new_entity_id = last_id + 1
    entity_ids.write(new_entity_id)

    # Write the owner
    let (caller) = get_caller_address()
    entity_owners.write(new_entity_id, caller)

    # Check $LORDS amount for adding entities?
    # let (module_controller_addr) = module_controller_address.read()
    # let (lords_amount) = lords_amount_for_creating.read()
    # let (caller_lords_amount) = IERC20.balanceOf(caller)
    # assert_le(lords_amount, caller_lords_amount)  

    if entity_kind != 0:
        let (is_kind_whitelisted) = whitelisted_kinds.read(entity_kind)
        assert is_kind_whitelisted = 1
        entity_kinds.write(new_entity_id, entity_kind)
    end
    
    # Save the Entity with revision 1
    entity_contents.write(new_entity_id, 1, entity_content)

    # Save Entity's POIs
    tempvar last_pois_index = 0
    save_pois_loop(new_entity_id, last_pois_index, entity_pois_len, entity_pois)
    entity_pois_last_indexes.write(new_entity_id, last_pois_index)

    # Save Entity's props
    tempvar last_props_index = 0
    save_props_loop(new_entity_id, last_props_index, entity_props_len, entity_props)
    entity_props_last_indexes.write(new_entity_id, last_props_index)

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
        entity_pois_len: felt,
        entity_pois: EntityPOI*
    ) -> ():
    alloc_locals

    if entity_pois_len == 0:
        return ()
    end

    # Check if POI kind is in list
    let entity_poi = entity_pois[last_poi_index]

    # Protect
    let (is_whitelisted) = whitelisted_pois.read(entity_poi.poi_id)
    assert is_whitelisted = 1

    entities_to_pois.write(entity_id, last_poi_index, entity_poi)

    save_pois_loop(entity_id, last_poi_index + 1, entity_pois_len - 1, entity_pois)

    return ()
end

func save_props_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        entity_id: felt,
        prop_index: felt,
        entity_props_len: felt,
        entity_props: EntityProp*
    ) -> ():
    alloc_locals

    if entity_props_len == 0:
        return ()
    end

    # Check if POI kind is in list
    let entity_prop = entity_props[prop_index]

    # Protect
    let (is_whitelisted) = whitelisted_props.read(entity_prop.prop_id)
    assert is_whitelisted = 1

    entities_to_props.write(entity_id, prop_index, entity_prop)

    save_props_loop(entity_id, prop_index + 1, entity_props_len - 1, entity_props)

    return ()
end

@external
func add_revision{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        entity_id: felt,
        entity_content: EntityContent,
        entity_pois_len: felt,
        entity_pois: EntityPOI*,
        entity_props_len: felt,
        entity_props: EntityProp*
    ) -> (revision_index: felt):
    alloc_locals

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

    whitelist_kinds_loop(kinds_len - 1, kinds + 1)

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

    whitelist_pois_loop(pois_len - 1, pois + 1)

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

    whitelist_props_loop(props_len - 1, props + 1)

    return ()
end

##########################
## Views for Entity
##########################
@view
func get_last_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
    ) -> (res: felt):
    let (last_id) = entity_ids.read()
    
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
    ) -> (owner: felt, content: EntityContent, kind: felt, pois_len: felt, pois: EntityPOI*, props_len: felt, props: EntityProp*):
    alloc_locals

    # Get owner
    let (entity_owner) = entity_owners.read(entity_id)
    assert_not_zero(entity_owner)

    # Get Content
    let (entity_content) = entity_contents.read(entity_id, revision_id)

    # Get Kind
    let (entity_kind) = entity_kinds.read(entity_id)

    # Get POIs
    let (entity_pois_last_index) = entity_pois_last_indexes.read(entity_id)
    # local entity_pois_last_index = 0
    let (pois: EntityPOI*) = alloc()
    get_entity_pois_loop(entity_id, 0, entity_pois_last_index + 1, pois)

    # Get props
    let (entity_props_last_index) = entity_props_last_indexes.read(entity_id)
    let (props: EntityProp*) = alloc()
    get_entity_props_loop(entity_id, 0, entity_props_last_index + 1, props)
    
    return (entity_owner, entity_content, entity_kind, entity_pois_last_index + 1, pois, entity_props_last_index + 1, props)
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

    get_entity_pois_loop(entity_id, poi_index + 1, pois_len - 1, pois)

    return ()
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