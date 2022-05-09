# Declare this file as a StarkNet contract and set the required
# builtins.
%lang starknet

from starkware.cairo.common.uint256 import (Uint256, uint256_le, uint256_eq)

@contract_interface
namespace ILoreValidator:
    func check_poi(poi_id: felt, asset_id: Uint256) -> (ok: felt):
    end
end
