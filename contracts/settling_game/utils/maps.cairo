# Helper contract for maps (dungeons, etc)
#    Dynamically sizes 2D arrays of felts to accomodate many sizes of maps
#
# MIT License

# TODO - Delete @external once we deploy.

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin, BitwiseBuiltin
from starkware.cairo.common.bitwise import (
    bitwise_and,
    bitwise_or)
from starkware.cairo.common.pow import pow
from starkware.cairo.common.math import (
    assert_nn_le,
    unsigned_div_rem)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy

# Writes a bit (1) on a position within the map
@external
func set_bit{
    syscall_ptr : felt*, bitwise_ptr : BitwiseBuiltin*, range_check_ptr
}(size : felt, map_len : felt, map : felt*, position : felt) -> (layout_len : felt, layout : felt*):
    alloc_locals
    # Determine which felt in the array we should modify
    let (local quotient, local remainder) = unsigned_div_rem(size*size, 251)  # Grab quotient (to figure out which felt we should bitshift) and remainder (to figure out which bit we should mask)
    assert_nn_le(position, 251 + (quotient * 251))    # Make sure the position fits inside our array(s)

    # Create a mask to apply a bitwise OR
    let (local mask) = pow(2, position)  
    let (local masked) = bitwise_or(map[quotient], mask)    # Or the two so we write a '1' at the mask index

    # Create a new array (because modifying existing ones causes an assert error)
    let (layout) = alloc()

    if quotient == 0:
        # If array is only 1 felt long, just replace it.
        layout[0] = masked
    else:
        # Shove our changed felt into an array
        let (tmp) = alloc()
        tmp[0] = masked
        memcpy(layout, tmp, 1)
    end


    

    # memcpy(layout, map, map_len)

    # assert[layout + quotient] = masked 

    return(map_len, layout)
end

# Calculates the number of felts needed based on the size of a map (e.g. 8x8 -> 1)
@external   
func calc_size{
    syscall_ptr : felt*, range_check_ptr
}(size : felt) -> (length : felt):
    let (quotient, _) = unsigned_div_rem(size*size, 251) # Figure out how many felts (251 bits) we need as one bit is one map tile
    return(quotient+1)
end