# maps_test.py - Test for maps data structure used for dungeon layout, enemies, etc. 
#
# MIT License
import os
import asyncio
import pytest


from starkware.starknet.testing.starknet import Starknet

# path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../../../", "contracts/settling_game/utils/maps.cairo")

@pytest.mark.asyncio
async def test_calc_size():
    starknet = await Starknet.empty()

    # Deploy the utils contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    ## Get size of a contract that is < 1 felt (1)
    # Make sure calc_size returns correctly
    size = await contract.calc_size(size=5).call()
    assert size.result == (1,)

    # Get size of a contract that is == 1 felt (1)
    # This is not possible (maps are 6x6->25x25 so will never be exactly one felt)

    # Get size of a contract that is > 1 felt (2)
    size = await contract.calc_size(size=25).call()
    assert size.result == (3,)

