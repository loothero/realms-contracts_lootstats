# maps_test.py - Test for maps data structure used for dungeon layout, enemies, etc. 
# TODO: Convert to the proper test format in the rest of the repo
#
# MIT License
import os
import asyncio
import pytest


from starkware.starknet.testing.starknet import Starknet
from starkware.starkware_utils.error_handling import StarkException

# path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../../../", "contracts/settling_game/utils/maps.cairo")

@pytest.mark.asyncio
async def test_set_bit():
    starknet = await Starknet.empty()

    # Deploy the utils contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )
   
    # Single Felt Length: Set a valid bit (within 1-250)
    layout = await contract.set_bit(size=5, map=[1], position=215).call()
    assert layout.result == ([1],)

    # Multi-Felt Length: Set a valid bit (within 252-502 for a 2-length array)
    # Multi-Felt Length: Set an invalid bit (outside 252-502 for a 2-length array)

@pytest.mark.asyncio
async def test_set_bit_exceptions():
    with pytest.raises(StarkException):
        starknet = await Starknet.empty()

        # Deploy the utils contract.
        contract = await starknet.deploy(
            source=CONTRACT_FILE,
        )
    
        # Single Felt Length: Set an invalid bit (outside of 1-250)
        layout = await contract.set_bit(size=5, map=[1], position=255).call()
        assert layout.result == ([1],)

@pytest.mark.asyncio
async def test_calc_size():
    starknet = await Starknet.empty()

    # Deploy the utils contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    # Get size of a contract that is < 1 felt (1)
    size = await contract.calc_size(size=5).call()
    assert size.result == (1,)

    # Get size of a contract that is == 1 felt (1)
    # This is not possible (maps are 6x6->25x25 so will never be exactly one felt)

    # Get size of a contract that is > 1 felt (2)
    size = await contract.calc_size(size=25).call()
    assert size.result == (3,)

