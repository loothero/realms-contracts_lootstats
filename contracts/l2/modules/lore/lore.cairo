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

# from contracts.token.IERC20 import IERC20
# from contracts.token.IERC721 import IERC721

# Supports Arweave and IPFS identifiers by keeping up to 93 character strings
# Arweave uses 43 characters 
# IPFS uses 64 (v1)
struct ScrollMeta:
    member Owner: felt
    
    member LinkPart1: felt
    member LinkPart2: felt
    member LinkPart3: felt

    member RealmId: Uint256
    member OrderId: felt # 1-16
    member ResourceId: felt # 1-22
    member WonderId: felt # 1 - 50
    member ModuleId: felt # 1..N <- supports Caverns, and other modules
    member ModuleTokenId: felt # 1..N <- supports Caverns, and other modules
end

# One Ring to Rule Them All
@storage_var
func module_controller_address() -> (address: felt):
end

# Counter
@storage_var
func scrolls_counter() -> (value: felt):
end

# Indexed list of all backstories
@storage_var
func scrolls(id: felt) -> (meta: ScrollMeta):
end

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
        scroll_meta: ScrollMeta
    ):
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
    let (lords_amount) = lords_amount_for_creating.read()
    let (caller_lords_amount) = IERC20.balanceOf(caller)
    assert_le(lords_amount, caller_lords_amount)  
    
    scrolls.write(scroll_id, scroll_meta)

    return (scroll_id)
end

@external
func vote_for_scroll{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        scroll_id: felt
    ):
    alloc_locals

    let (caller) = get_caller_address()

    # Get controller
    let (module_controller_addr) = module_controller_address.read()

    # Check $LORDS amount for voting
    # let (lords_contract_address) = IModuleController.get()
    let (lords_amount) = lords_amount_for_voting.read()
    let (caller_lords_amount) = IERC20.balanceOf(lords_contract_address, caller)
    assert_le(lords_amount, caller_lords_amount)

    # Check if the user previously voted + update voting
    let (already_voted) = scroll_voters.read(scroll_id)
    assert already_voted = 0
    scroll_voters.write(scroll_id, caller, 1)

    # Increase votes
    let (votes) = scroll_voters.read(scroll_id)
    scroll_votes.write(scroll_id, votes + 1)

    return ()
end