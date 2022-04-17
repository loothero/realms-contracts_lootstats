# Helper contract for maps (dungeons, etc)
#    Dynamically sizes 2D arrays of felts to accomodate many sizes of maps
#
# MIT License

# TODO - Delete @external once we deploy.

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import bitwise_and
from starkware.cairo.common.pow import pow
from starkware.cairo.common.math import (
    assert_nn_le,
    unsigned_div_rem)

# Writes a bit (1) on a position within the map
@external
func set_bit{
    syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}(size : felt, map_len : felt, map : felt*, position : felt) -> (map_len : felt, map : felt*):
    alloc_locals
    let (local quotient, remainder) = unsigned_div_rem(size*size, 251)
    assert_nn_le(position, 251 + (quotient * 251))    # Make sure the position fits inside our array(s)
    let (mask) = pow(2, position)
    let (masked) = bitwise_and(map[quotient], mask)
    map[quotient] = masked

    return(map_len, map)
end

# Calculates the number of felts needed based on the size of a map (e.g. 8x8 -> 1)
@external   
func calc_size{
    syscall_ptr : felt*, range_check_ptr
}(size : felt) -> (length : felt):
    let (quotient, _) = unsigned_div_rem(size*size, 251) # Figure out how many felts (251 bits) we need as one bit is one map tile
    return(quotient+1)
end