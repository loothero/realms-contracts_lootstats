import pytest
import asyncio
import json
from openzeppelin.tests.utils import Signer, uint, str_to_felt, from_uint, felt_to_str
import time
from enum import IntEnum

# ACCOUNTS
NUM_SIGNING_ACCOUNTS = 2


@pytest.mark.asyncio
@pytest.mark.parametrize('account_factory', [dict(num_signers=NUM_SIGNING_ACCOUNTS)], indirect=True)
async def test_lore(lore_factory):
    ctx = lore_factory
    

    print(ctx)
