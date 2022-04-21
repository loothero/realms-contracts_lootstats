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
async def test_get_bit():
    starknet = await Starknet.empty()

    # Deploy the utils contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )
   
    ## Single Felt Length: Get a valid bit (within 1-250) from an empty location
    position = 0
    size = 5

    layout = 0 | (1 << (5))

    value = await contract.get_bit(size=size, map=[layout], position=position).call()

    # Expected value: 0.
    expected = 0


    ## Single Felt Length: Get a valid bit (within 1-250) from a 'set' location
    position = 5
    size = 5

    layout = 0 | (1 << (5))

    value = await contract.get_bit(size=size, map=[layout], position=position).call()

    # Expected value: 0.
    expected = 1

    
    assert value.result == (expected,)


    ## Multi-felt length: Get a valid bit (within 1-250) from a 'set' location
    position = 5
    size = 25

    layout = 0 | (1 << (5))

    value = await contract.get_bit(size=size, map=[layout], position=position).call()

    # Expected value: 0.
    expected = 1

    
    assert value.result == (expected,)

"""
@pytest.mark.asyncio
async def test_set_bit():
    starknet = await Starknet.empty()

    # Deploy the utils contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )
   
    ## Single Felt Length: Set a valid bit (within 1-250)
    position = 5
    size = 5

    layout = await contract.set_bit(size=size, map=[0], position=position).call()
    # Expected value: an array containing a single felt that has a single bit set at 2^215.
    # x = 0x00
    expected = 0 | (1 << (position))
    assert layout.result == ([expected],)

    ## Multi-Felt Length: Set a valid bit (within 1-252 for a 2-length array)
    position = 150
    size = 20

    layout = await contract.set_bit(size=size, map=[0,5], position=position).call()

    expected = 0 | (1 << (position))

    assert layout.result == ([expected, 5],)

    # Multi-Felt Length: Set a valid bit (within 252-502 for a 2-length array)
    position = 260
    size = 20

    layout = await contract.set_bit(size=size, map=[0,5], position=position).call()

    expected = 5 | (1 << (position))

    assert layout.result == ([0, expected],)

    # Multi-Felt Length: Set an invalid bit (outside 252-502 for a 2-length array)

@pytest.mark.asyncio
async def test_set_bit_exceptions():
    with pytest.raises(StarkException):
        starknet = await Starknet.empty()

        # Deploy the utils contract.
        contract = await starknet.deploy(
            source=CONTRACT_FILE,
        )
    
        # Single Felt Length: Set an invalid bit (outside of 0-250)
        position = 255
        size = 5
        layout = await contract.set_bit(size=size, map=[1], position=position).call()
        assert layout.result == ([1],)

        # Multi-Felt Length: Set an invalid bit (outside 0-502 for a 2-length array)
        position = 510
        size = 20

        layout = await contract.set_bit(size=size, map=[0,5], position=position).call()

        expected = 5 | (1 << (position))

        assert layout.result == ([0, expected],)
"""
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

