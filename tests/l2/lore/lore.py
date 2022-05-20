from starkware.starknet.business_logic.state.state import BlockInfo
from starkware.starknet.testing.starknet import Starknet, StarknetContract
from starkware.starknet.services.api.contract_definition import ContractDefinition
from starkware.starknet.compiler.compile import compile_starknet_files
import pytest
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, from_uint, felt_to_str
import time
from scripts.binary_converter import map_realm
from tests.conftest import set_block_timestamp

signer = Signer(123456789987654321)

# @pytest.mark.asyncio
# async def test_create_entity():


@pytest.mark.asyncio
async def test_create_entity():
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()

    first_account = await starknet.deploy(
        source="openzeppelin/account/Account.cairo",
        constructor_calldata=[signer.public_key]
    )

    # Deploy the contract.
    contract = await starknet.deploy(
      source="contracts/l2/modules/lore/lore.cairo",
      constructor_calldata=[
        first_account.contract_address,
        # 0
      ]
    )

    res = await signer.send_transaction(
      account=first_account,
      to=contract.contract_address,
      selector_name="whitelist_kinds",
      calldata=[
        2,
        1, 1, # poi id=1
        2, 1  # poi id=2
      ]
    )

    res = await signer.send_transaction(
      account=first_account,
      to=contract.contract_address,
      selector_name="whitelist_pois",
      calldata=[
        4,
        1, 1, # tag id=1
        2, 1,
        3, 1,
        4, 1
      ]
    )

    res = await signer.send_transaction(
      account=first_account,
      to=contract.contract_address,
      selector_name="whitelist_props",
      calldata=[
        2,
        1, 1, # tag id=1
        2, 1
      ]
    )

    await signer.send_transaction(
      account=first_account,
      to=contract.contract_address,
      selector_name="create_entity",
      calldata=[
        101, 102, # content link parts
        0, # kind
        2, # pois count
        1, 1, 0, # poi #1
        2, 1, 0, # poi #1
        2, # props count
        1, 1, # prop #1
        2, 1 # prop #1
      ]
    )

    res = await signer.send_transaction(
      account=first_account,
      to=contract.contract_address,
      selector_name="add_revision",
      calldata=[
        1, # entity_id
        102, 103,
        2, # pois count
        1, 2, 0, # poi #1
        3, 1, 0, # poi #1
      ]
    )

    res = await signer.send_transaction(
      account=first_account,
      to=contract.contract_address,
      selector_name="add_revision",
      calldata=[
        1, # entity_id
        104, 105,
        3, # pois count
        1, 2, 0, # poi #1
        3, 1, 0, # poi #1
        4, 1, 0
      ]
    )

    res = await contract.get_entity(entity_id=1, revision_id=1).call()

    # print(res)
    # print("-======================")

    assert res.result.owner == first_account.contract_address
    assert res.result.content.Part1 == 101
    assert res.result.content.Part2 == 102
    assert res.result.kind == 0
    assert res.result.pois[0].id == 1
    assert res.result.pois[0].asset_id.low == 1
    assert res.result.pois[0].asset_id.high == 0
    assert res.result.pois[1].id == 2
    assert res.result.pois[1].asset_id.low == 1
    assert res.result.pois[1].asset_id.high == 0
    assert res.result.props[0].id == 1
    assert res.result.props[0].value == 1
    assert res.result.props[1].id == 2
    assert res.result.props[1].value == 1

    res2 = await contract.get_entity(entity_id=1, revision_id=2).call()

    # print(res2)
    # print("-======================")

    assert res2.result.content.Part1 == 102
    assert res2.result.content.Part2 == 103
    assert res2.result.kind == 0
    assert len(res2.result.pois) == 2
    assert res2.result.pois[0].id == 1
    assert res2.result.pois[0].asset_id.low == 2
    assert res2.result.pois[0].asset_id.high == 0
    assert res2.result.pois[1].id == 3
    assert res2.result.pois[1].asset_id.low == 1
    assert res2.result.pois[1].asset_id.high == 0

    res3 = await contract.get_entity(entity_id=1, revision_id=3).call()

    # print(res3)
    # print("-======================")

    assert res3.result.content.Part1 == 104
    assert res3.result.content.Part2 == 105
    assert res3.result.kind == 0
    assert len(res3.result.pois) == 3
    assert res3.result.pois[0].id == 1
    assert res3.result.pois[0].asset_id.low == 2
    assert res3.result.pois[0].asset_id.high == 0
    assert res3.result.pois[1].id == 3
    assert res3.result.pois[1].asset_id.low == 1
    assert res3.result.pois[1].asset_id.high == 0
    assert res3.result.pois[2].id == 4
    assert res3.result.pois[2].asset_id.low == 1
    assert res3.result.pois[2].asset_id.high == 0

    # assert res == 1