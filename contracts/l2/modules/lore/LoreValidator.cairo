# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.messages import send_message_to_l1
from starkware.starknet.common.syscalls import (get_caller_address, get_contract_address)
from starkware.cairo.common.math import assert_not_zero, assert_le
from starkware.cairo.common.math_cmp import is_not_zero, is_in_range
from starkware.cairo.common.uint256 import (Uint256, uint256_le, uint256_eq)

from openzeppelin.utils.constants import TRUE, FALSE
from openzeppelin.access.ownable import (
    Ownable_initializer,
    Ownable_only_owner
)

##########################
## Constructor
##########################
@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        owner: felt
    ):
    Ownable_initializer(owner)
    return ()
end

##########################
## Interface implementation
##########################
@external
func validate_poi{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        poi_id: felt,
        asset_id: Uint256
    ) -> (ok: felt):
    alloc_locals

    # Realms
    if poi_id == 1000:
        return is_in_range(asset_id.low, 1, 8001)
    end

    return (FALSE)
end