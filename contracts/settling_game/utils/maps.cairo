# Helper contract for maps (dungeons, etc)
#    Dynamically sizes 2D arrays of felts to accomodate many sizes of maps
#
# MIT License

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.math import (unsigned_div_rem)

# Calculates the number of felts needed based on the size of a map (e.g. 8x8 -> 1)
# HACK - Delete @external once we deploy.
@external   
func calc_size{
    syscall_ptr : felt*, range_check_ptr
}(size : felt) -> (length : felt):
    let totalSize = size * size
    let (divisor, remainder) = unsigned_div_rem(totalSize, 251)
    return(divisor+1)
end