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

# Events
@event
func scroll_created(id: felt):
end

# Supports Arweave
# Arweave uses 43 characters
struct ScrollContent:
    member ContentLinkPart1: felt
    member ContentLinkPart2: felt
end

struct ScrollPOI:
    member poi_id: felt # Scroll POI Kind from pois list
    member asset_id: Uint256 # For L1 <-> L2 compatibility 
end

struct Scrollprop:
    member prop_id: felt # Scroll POI Kind from pois list
    member prop_value: felt
end

# struct ScrollQueryResult:
#     member Owner: felt
    
#     member ContentLinkPart1: felt
#     member ContentLinkPart2: felt

#     member POIs: ScrollPOI*
#     member props: Scrollprop* 
# end

##########################
## Module Controller
##########################
# One Ring to Rule Them All
@storage_var
func module_controller_address() -> (address: felt):
end

##########################
## Scroll
##########################
@storage_var
func scroll_contents(id: felt, revision_index: felt) -> (value: ScrollContent):
end

@storage_var
func scroll_owners(id: felt) -> (owner: felt):
end

# Counter for sequential IDs
@storage_var
func scroll_ids() -> (value: felt):
end

@storage_var
func scroll_revisions_counter(scroll_id: felt) -> (value: felt):
end

##########################
## POIs
##########################
@storage_var
func whitelisted_pois(id: felt) -> (is_whitelisted: felt):
end

@storage_var
func scrolls_to_pois(scroll_id: felt, poi_index: felt) -> (poi: ScrollPOI):
end

@storage_var
func scroll_pois_counter(scroll_id: felt) -> (value: felt):
end

##########################
## props (for Eras, etc.)
##########################
@storage_var
func whitelisted_props(id: felt) -> (is_whitelisted: felt):
end

@storage_var
func scrolls_to_props(scroll_id: felt, prop_index: felt) -> (prop: Scrollprop):
end

@storage_var
func scroll_props_counter(scroll_id: felt) -> (value: felt):
end

##########################
## $LORDS requirements
##########################
@storage_var
func lords_amount_for_creating() -> (amount: felt):
end

##########################
## Voting
##########################
# @storage_var
# func scroll_votes(id: felt) -> (votes: felt):
# end

# @storage_var
# func scroll_voters(id: felt, voter: felt) -> (voted: felt):
# end

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
## Scrolls
##########################
@external
func create_scroll{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_content: ScrollContent,
        scroll_pois_len: felt,
        scroll_pois: ScrollPOI*,
        scroll_props_len: felt,
        scroll_props: Scrollprop*
    ) -> (scroll_id: felt):
    alloc_locals

    # Checking for at least two (Arweave)
    assert_not_zero(scroll_content.ContentLinkPart1)
    assert_not_zero(scroll_content.ContentLinkPart2)

    # Get controller

    # Get next index + update index counter per token_id
    # Start with 1 instead of 0
    let (last_id) = scroll_ids.read()
    local new_scroll_id = last_id + 1
    scroll_ids.write(new_scroll_id)

    # Write the owner
    let (caller) = get_caller_address()
    scroll_owners.write(new_scroll_id, caller)

    # Check $LORDS amount for adding scrolls?
    # let (module_controller_addr) = module_controller_address.read()
    # let (lords_amount) = lords_amount_for_creating.read()
    # let (caller_lords_amount) = IERC20.balanceOf(caller)
    # assert_le(lords_amount, caller_lords_amount)  
    
    # Save the Scroll with revision 0
    scroll_contents.write(new_scroll_id, 0, scroll_content)

    # Save Scroll's POIs
    save_pois_loop(new_scroll_id, 0, scroll_pois_len, scroll_pois)
    scroll_pois_counter.write(new_scroll_id, scroll_pois_len)

    # Save Scroll's props
    save_props_loop(new_scroll_id, 0, scroll_props_len, scroll_props)
    scroll_props_counter.write(new_scroll_id, scroll_props_len)

    # Emit the event
    scroll_created.emit(new_scroll_id)

    return (new_scroll_id)
end

func save_pois_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_id: felt,
        poi_index: felt,
        scroll_pois_len: felt,
        scroll_pois: ScrollPOI*
    ) -> ():
    alloc_locals

    if scroll_pois_len == 0:
        return ()
    end

    # Check if POI kind is in list
    let scroll_poi = scroll_pois[poi_index]

    # Protect
    let (is_whitelisted) = whitelisted_pois.read(scroll_poi.poi_id)
    assert is_whitelisted = 1

    scrolls_to_pois.write(scroll_id, poi_index, scroll_poi)

    save_pois_loop(scroll_id, poi_index + 1, scroll_pois_len - 1, scroll_pois)

    return ()
end

func save_props_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_id: felt,
        prop_index: felt,
        scroll_props_len: felt,
        scroll_props: Scrollprop*
    ) -> ():
    alloc_locals

    if scroll_props_len == 0:
        return ()
    end

    # Check if POI kind is in list
    let scroll_prop = scroll_props[prop_index]

    # Protect
    let (is_whitelisted) = whitelisted_props.read(scroll_prop.prop_id)
    assert is_whitelisted = 1

    scrolls_to_props.write(scroll_id, prop_index, scroll_prop)

    save_props_loop(scroll_id, prop_index + 1, scroll_props_len - 1, scroll_props)

    return ()
end

@external
func add_revision{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_id: felt,
        scroll_content: ScrollContent,
        scroll_pois_len: felt,
        scroll_pois: ScrollPOI*,
        scroll_props_len: felt,
        scroll_props: Scrollprop*
    ) -> (revision_index: felt):
    alloc_locals

    return (0)
end

##########################
## POIs Whitelisting
##########################
@external
func add_whitelisted_pois{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        poi_ids_len: felt,
        poi_ids: felt*
    ) -> ():
    Ownable_only_owner()

    add_whitelisted_pois_loop(poi_ids_len, poi_ids)

    return ()
end

func add_whitelisted_pois_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        poi_ids_len: felt,
        poi_ids: felt*
    ) -> ():

    if poi_ids_len == 0:
        return ()
    end

    let id = [poi_ids]

    whitelisted_pois.write(id, 1)

    add_whitelisted_pois_loop(poi_ids_len - 1, poi_ids + 1)

    return ()
end

##########################
## props Whitelisting
##########################
@external
func add_whitelisted_props{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        prop_ids_len: felt,
        prop_ids: felt*
    ) -> ():
    Ownable_only_owner()

    add_whitelisted_props_loop(prop_ids_len, prop_ids)

    return ()
end

func add_whitelisted_props_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        prop_ids_len: felt,
        prop_ids: felt*
    ) -> ():

    if prop_ids_len == 0:
        return ()
    end

    let id = [prop_ids]

    whitelisted_props.write(id, 1)

    add_whitelisted_pois_loop(prop_ids_len - 1, prop_ids + 1)

    return ()
end

@view
func get_scroll_last_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
    ) -> (res: felt):
    let (last_id) = scroll_ids.read()
    
    return (last_id)
end

##########################
## Get Scroll
##########################
@view
func get_scroll{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_id: felt,
        revision_id: felt
    ) -> (owner: felt, content: ScrollContent, pois_len: felt, pois: ScrollPOI*, props_len: felt, props: Scrollprop*):
    alloc_locals

    # Get owner
    let (scroll_owner) = scroll_owners.read(scroll_id)
    assert_not_zero(scroll_owner)

    # Get Content
    let (scroll_content) = scroll_contents.read(scroll_id, revision_id)

    # Get POIs
    let (pois_count) = scroll_pois_counter.read(scroll_id)
    let (pois: ScrollPOI*) = alloc()
    get_scroll_pois_loop(scroll_id, 0, pois_count, pois)

    # Get props
    let (props_count) = scroll_props_counter.read(scroll_id)
    let (props: Scrollprop*) = alloc()
    get_scroll_props_loop(scroll_id, 0, props_count, props)
    
    return (scroll_owner, scroll_content, pois_count, pois, props_count, props)
end

func get_scroll_pois_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_id: felt,
        poi_index: felt,
        pois_count: felt,
        pois: ScrollPOI*
    ) -> ():
    alloc_locals

    if pois_count == 0:
        return ()
    end

    let (poi) = scrolls_to_pois.read(scroll_id, poi_index)
    assert pois[poi_index] = poi # Strange way of assigning values to array

    get_scroll_pois_loop(scroll_id, poi_index + 1, pois_count - 1, pois)

    return ()
end

func get_scroll_props_loop{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_id: felt,
        prop_index: felt,
        props_count: felt,
        props: Scrollprop*
    ) -> ():
    alloc_locals

    if props_count == 0:
        return ()
    end

    let (prop) = scrolls_to_props.read(scroll_id, prop_index)
    assert props[prop_index] = prop # Strange way of assigning values to array

    get_scroll_props_loop(scroll_id, prop_index + 1, props_count - 1, props)

    return ()
end