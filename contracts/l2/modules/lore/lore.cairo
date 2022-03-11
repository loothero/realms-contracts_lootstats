# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import assert_not_zero, unsigned_div_rem
from starkware.cairo.common.uint256 import (Uint256, uint256_le)

from contracts.token.IERC20 import IERC20
# from contracts.token.IERC721 import IERC721

# Supports Arweave and IPFS identifiers by keeping up to 93 character strings
# Arweave uses 43 characters 
# IPFS uses 64 (v1)
struct Scroll:
    member Owner: felt
    
    member LinkPart1: felt
    member LinkPart2: felt
    # member LinkPart3: felt
end

struct ScrollPOI:
    member module_id: felt # Scroll POI Kind from pois list
    member asset_id: Uint256 # For L1 <-> L2 compatibility 
end

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
func scrolls(id: felt) -> (value: Scroll):
end

@storage_var
func pois(id: felt) -> (poi: felt):
end

@storage_var
func scrolls_to_pois(scroll_id: felt, poi_index: felt) -> (value: ScrollPOI):
end

@storage_var
func scroll_pois_counter(scroll_id: felt) -> (value: felt):
end

# Counter
@storage_var
func scrolls_counter() -> (value: felt):
end

##########################
## $LORDS requirements
##########################
@storage_var
func lords_amount_for_creating() -> (amount: felt):
end

@storage_var
func lords_amount_for_voting() -> (amount: felt):
end

##########################
## Voting
##########################
@storage_var
func scroll_votes(id: felt) -> (votes: felt):
end

@storage_var
func scroll_voters(id: felt, voter: felt) -> (voted: felt):
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
        module_controller_addr: felt
    ):    
    module_controller_address.write(module_controller_addr)
    return ()
end

@external
func create_scroll{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_meta: Scroll,
        scroll_pois_len: felt,
        scroll_pois: ScrollPOI*
    ) -> (scroll_id: felt):
    alloc_locals

    # Check that it's the person who calls is actually an owner that will be written
    let (caller) = get_caller_address()
    assert scroll_meta.Owner = caller

    # TODO: Check for Realms ID?

    # Checking for at least two (Arweave)
    assert_not_zero(scroll_meta.LinkPart1)
    assert_not_zero(scroll_meta.LinkPart2)

    # Get controller
    let (module_controller_addr) = module_controller_address.read()

    # Get next index + update index counter per token_id
    let (scroll_id) = scrolls_counter.read()
    scrolls_counter.write(scroll_id + 1)

    # Check $LORDS amount for adding scrolls?
    # let (lords_amount) = lords_amount_for_creating.read()
    # let (caller_lords_amount) = IERC20.balanceOf(caller)
    # assert_le(lords_amount, caller_lords_amount)  
    
    # Save the Scroll
    scrolls.write(scroll_id, scroll_meta)

    # Save Scroll's POIs
    save_pois_loop(scroll_id, 0, scroll_pois_len, scroll_pois)
    scroll_pois_counter.write(scroll_id, scroll_pois_len)

    return (scroll_id)
end

@external
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
    let (poi) = pois.read(scroll_poi.kind)
    assert_not_zero(poi)

    scrolls_to_pois.write(scroll_id, poi_index, scroll_pois[poi_index])

    save_pois_loop(scroll_id, poi_index + 1, scroll_pois_len - 1, scroll_pois)

    return ()
end

# TODO: add Ownable checking
@external
func update_poi{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        id: felt,
        name: felt
    ) -> ():
    alloc_locals

    # Check that it's the person who calls is actually an owner that will be written
    # let (caller) = get_caller_address()
    # assert scroll_meta.Owner = caller

    pois.write(id, name)

    return ()
end

@view
func get_scrolls_count{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
    ) -> (res: felt):
    let (count) = scrolls_counter.read()
    
    return (count)
end

@view
func get_scroll{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_id: felt
    ) -> (scroll: Scroll):
    alloc_locals

    let (scroll) = scrolls.read(scroll_id)
    
    return (scroll)
end

@view
func get_scroll_pois{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_id: felt
    ) -> (pois_len: felt, pois: ScrollPOI*):
    alloc_locals

    let (pois_count) = scroll_pois_counter.read(scroll_id)

    let (pois: ScrollPOI*) = alloc()
    
    get_scroll_pois_loop(scroll_id, 0, pois_count, pois)
    
    return (pois_count, pois)
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

# @external
# func vote_for_scroll{
#         syscall_ptr : felt*,
#         pedersen_ptr : HashBuiltin*,
#         range_check_ptr
#     } (
#         scroll_id: felt
#     ):
#     alloc_locals

#     let (caller) = get_caller_address()

#     # Get controller
#     let (module_controller_addr) = module_controller_address.read()

#     # Check $LORDS amount for voting
#     # let (lords_contract_address) = IModuleController.get()
#     let (lords_amount) = lords_amount_for_voting.read()
#     let (caller_lords_amount) = IERC20.balanceOf(lords_contract_address, caller)
#     assert_le(lords_amount, caller_lords_amount)

#     # Check if the user previously voted + update voting
#     let (already_voted) = scroll_voters.read(scroll_id)
#     assert already_voted = 0
#     scroll_voters.write(scroll_id, caller, 1)

#     # Increase votes
#     let (votes) = scroll_voters.read(scroll_id)
#     scroll_votes.write(scroll_id, votes + 1)

#     return ()
# end