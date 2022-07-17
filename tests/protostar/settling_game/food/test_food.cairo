%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from contracts.settling_game.modules.food.library import Food

from contracts.settling_game.utils.constants import FARM_LENGTH, GENESIS_TIMESTAMP
from contracts.settling_game.utils.game_structs import RealmData, RealmBuildingsIds

from tests.protostar.settling_game.test_structs import (
    TEST_REALM_DATA,
    TEST_HAPPINESS,
    TEST_DAYS,
    TEST_MINT_PERCENTAGE,
)

const UPDATE_TIME = GENESIS_TIMESTAMP - (FARM_LENGTH * 10)

@external
func test_current_relic_holder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (total_farms, remainding_crops) = Food.calculate_harvest(UPDATE_TIME, GENESIS_TIMESTAMP)

    assert total_farms = 10

    return ()
end

@external
func test_create{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let realmData = RealmData(
        TEST_REALM_DATA.REGIONS,
        TEST_REALM_DATA.CITIES,
        TEST_REALM_DATA.HARBOURS,
        TEST_REALM_DATA.RIVERS,
        TEST_REALM_DATA.RESOURCE_NUMBER,
        TEST_REALM_DATA.RESOURCE_1,
        TEST_REALM_DATA.RESOURCE_2,
        TEST_REALM_DATA.RESOURCE_3,
        TEST_REALM_DATA.RESOURCE_4,
        TEST_REALM_DATA.RESOURCE_5,
        TEST_REALM_DATA.RESOURCE_6,
        TEST_REALM_DATA.RESOURCE_7,
        TEST_REALM_DATA.WONDER,
        TEST_REALM_DATA.ORDER,
    )

    # test can build farms
    let (farm) = Food.create(TEST_REALM_DATA.RIVERS, RealmBuildingsIds.Farm, realmData)

    assert farm = 1000

    let (fish) = Food.create(TEST_REALM_DATA.HARBOURS, RealmBuildingsIds.FishingVillage, realmData)

    assert fish = 1000

    return ()
end