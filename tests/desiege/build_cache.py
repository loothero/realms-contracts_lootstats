import pytest

# A stub test that serves no other purpose than to use the ctx_factory
# fixture which is defined in conftest.py in order to cache it.
@pytest.mark.asyncio
async def test_ctx_factory(ctx_factory_desiege):
    ctx = ctx_factory_desiege()
    assert 1 == 1