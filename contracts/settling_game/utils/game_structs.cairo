# Game Structs
#   A struct that holds the Realm statistics.
#   Each module will need to add a struct with their metadata.
#
# MIT License

%lang starknet

namespace TraitsIds:
    const Region = 1
    const City = 2
    const Harbour = 3
    const River = 4
end

struct RealmData:
    member regions : felt
    member cities : felt
    member harbours : felt
    member rivers : felt
    member resource_number : felt
    member resource_1 : felt
    member resource_2 : felt
    member resource_3 : felt
    member resource_4 : felt
    member resource_5 : felt
    member resource_6 : felt
    member resource_7 : felt
    member wonder : felt
    member order : felt
end

struct RealmBuildings:
    member House : felt
    member StoreHouse : felt
    member Granary : felt
    member Farm : felt
    member FishingVillage : felt
    member Barracks : felt
    member MageTower : felt
    member ArcherTower : felt
    member Castle : felt
end

namespace RealmBuildingsIds:
    const House = 1
    const StoreHouse = 2
    const Granary = 3
    const Farm = 4
    const FishingVillage = 5
    const Barracks = 6
    const MageTower = 7
    const ArcherTower = 8
    const Castle = 9
end

# square meters
namespace RealmBuildingsSize:
    const House = 2
    const StoreHouse = 3
    const Granary = 3
    const Farm = 3
    const FishingVillage = 3
    const Barracks = 6
    const MageTower = 6
    const ArcherTower = 6
    const Castle = 12
end

namespace BuildingsFood:
    const House = 2
    const StoreHouse = 3
    const Granary = 3
    const Farm = 3
    const FishingVillage = 3
    const Barracks = 6
    const MageTower = 6
    const ArcherTower = 6
    const Castle = 12
end

namespace BuildingsCulture:
    const House = 2
    const StoreHouse = 3
    const Granary = 3
    const Farm = 3
    const FishingVillage = 3
    const Barracks = 6
    const MageTower = 6
    const ArcherTower = 6
    const Castle = 12
end

namespace BuildingsPopulation:
    const House = 2
    const StoreHouse = 3
    const Granary = 3
    const Farm = 3
    const FishingVillage = 3
    const Barracks = 6
    const MageTower = 6
    const ArcherTower = 6
    const Castle = 12
end

namespace BuildingsIntegrityLength:
    const House = 1000
    const StoreHouse = 2000
    const Granary = 2000
    const Farm = 2000
    const FishingVillage = 2000
    const Barracks = 3000
    const MageTower = 3000
    const ArcherTower = 3000
    const Castle = 9000
end

namespace BuildingsTroopIndustry:
    const House = 0
    const StoreHouse = 0
    const Granary = 0
    const Farm = 0
    const FishingVillage = 0
    const Barracks = 2
    const MageTower = 2
    const ArcherTower = 2
    const Castle = 4
end

namespace BuildingsDecaySlope:
    const House = 400
    const StoreHouse = 400
    const Granary = 400
    const Farm = 400
    const FishingVillage = 400
    const Barracks = 400
    const MageTower = 400
    const ArcherTower = 400
    const Castle = 200
end

namespace ArmyCap:
    const House = 2
    const StoreHouse = 3
    const Granary = 3
    const Farm = 3
    const FishingVillage = 3
    const Barracks = 6
    const MageTower = 6
    const ArcherTower = 6
    const Castle = 12
end

namespace ModuleIds:
    # TODO: refactor the code to drop the Lnn_ prefix
    const L01_Settling = 1
    const L02_Resources = 2
    const L03_Buildings = 3
    const L04_Calculator = 4
    const L05_Wonders = 5
    const L06_Combat = 6
    const L07_Crypts = 7
    const L08_Crypts_Resources = 8
    const L09_Relics = 12
    const L10_Food = 13
    const GoblinTown = 14
end

namespace ExternalContractIds:
    const Lords = 1
    const Realms = 2
    const S_Realms = 3
    const Resources = 4
    const Treasury = 5
    const Storage = 6
    const Crypts = 7
    const S_Crypts = 8
end

struct CryptData:
    member resource : felt  # uint256 - resource generated by this dungeon (23-28)
    member environment : felt  # uint256 - environment of the dungeon (1-6)
    member legendary : felt  # uint256 - flag if dungeon is legendary (0/1)
    member size : felt  # uint256 - size (e.g. 6x6) of dungeon. (6-25)
    member num_doors : felt  # uint256 - number of doors (0-12)
    member num_points : felt  # uint256 - number of points (0-12)
    member affinity : felt  # uint256 - affinity of the dungeon (0, 1-58)
    # member name : felt  # string - name of the dungeon
end

# struct holding the different environments for Crypts and Caverns dungeons
# we'll use this to determine how many resources to grant during staking
namespace EnvironmentIds:
    const DesertOasis = 1
    const StoneTemple = 2
    const ForestRuins = 3
    const MountainDeep = 4
    const UnderwaterKeep = 5
    const EmbersGlow = 6
end

namespace EnvironmentProduction:
    const DesertOasis = 170
    const StoneTemple = 90
    const ForestRuins = 80
    const MountainDeep = 60
    const UnderwaterKeep = 25
    const EmbersGlow = 10
end

namespace ResourceIds:
    # Realms Resources
    const Wood = 1
    const Stone = 2
    const Coal = 3
    const Copper = 4
    const Obsidian = 5
    const Silver = 6
    const Ironwood = 7
    const ColdIron = 8
    const Gold = 9
    const Hartwood = 10
    const Diamonds = 11
    const Sapphire = 12
    const Ruby = 13
    const DeepCrystal = 14
    const Ignium = 15
    const EtherealSilica = 16
    const TrueIce = 17
    const TwilightQuartz = 18
    const AlchemicalSilver = 19
    const Adamantine = 20
    const Mithral = 21
    const Dragonhide = 22
    # Crypts and Caverns Resources
    const DesertGlass = 23
    const DivineCloth = 24
    const CuriousSpore = 25
    const UnrefinedOre = 26
    const SunkenShekel = 27
    const Demonhide = 28
    # IMPORTANT: if you're adding to this enum
    # make sure the SIZE is one greater than the
    # maximal value; certain algorithms depend on that
    const wheat = 10000
    const fish = 10001
    const SIZE = 31
end

namespace TroopId:
    const Skirmisher = 1
    const Longbow = 2
    const Crossbow = 3
    const Pikeman = 4
    const Knight = 5
    const Paladin = 6
    const Ballista = 7
    const Mangonel = 8
    const Trebuchet = 9
    const Apprentice = 10
    const Mage = 11
    const Arcanist = 12
    # IMPORTANT: if you're adding to this enum
    # make sure the SIZE is one greater than the
    # maximal value; certain algorithms depend on that
    const SIZE = 13
end

namespace TroopType:
    const RangedNormal = 1
    const RangedMagic = 2
    const Melee = 3
    const Siege = 4
end

struct Troop:
    member id : felt  # TroopId
    member type : felt  # TroopType
    member tier : felt
    member building : felt  # RealmBuildingsIds, the troop's production building
    member agility : felt
    member attack : felt
    member armor : felt
    member vitality : felt
    member wisdom : felt
end

namespace TroopProps:
    namespace Type:
        const Skirmisher = TroopType.RangedNormal
        const Longbow = TroopType.RangedNormal
        const Crossbow = TroopType.RangedNormal
        const Pikeman = TroopType.Melee
        const Knight = TroopType.Melee
        const Paladin = TroopType.Melee
        const Ballista = TroopType.Siege
        const Mangonel = TroopType.Siege
        const Trebuchet = TroopType.Siege
        const Apprentice = TroopType.RangedMagic
        const Mage = TroopType.RangedMagic
        const Arcanist = TroopType.RangedMagic
    end

    namespace Tier:
        const Skirmisher = 1
        const Longbow = 2
        const Crossbow = 3
        const Pikeman = 1
        const Knight = 2
        const Paladin = 3
        const Ballista = 1
        const Mangonel = 2
        const Trebuchet = 3
        const Apprentice = 1
        const Mage = 2
        const Arcanist = 3
    end

    namespace Building:
        const Skirmisher = RealmBuildingsIds.ArcherTower
        const Longbow = RealmBuildingsIds.ArcherTower
        const Crossbow = RealmBuildingsIds.ArcherTower
        const Pikeman = RealmBuildingsIds.Barracks
        const Knight = RealmBuildingsIds.Barracks
        const Paladin = RealmBuildingsIds.Barracks
        const Ballista = RealmBuildingsIds.Castle
        const Mangonel = RealmBuildingsIds.Castle
        const Trebuchet = RealmBuildingsIds.Castle
        const Apprentice = RealmBuildingsIds.MageTower
        const Mage = RealmBuildingsIds.MageTower
        const Arcanist = RealmBuildingsIds.MageTower
    end

    namespace Agility:
        const Skirmisher = 2
        const Longbow = 4
        const Crossbow = 6
        const Pikeman = 7
        const Knight = 9
        const Paladin = 9
        const Ballista = 4
        const Mangonel = 4
        const Trebuchet = 4
        const Apprentice = 7
        const Mage = 7
        const Arcanist = 7
    end

    namespace Attack:
        const Skirmisher = 7
        const Longbow = 7
        const Crossbow = 9
        const Pikeman = 4
        const Knight = 7
        const Paladin = 9
        const Ballista = 11
        const Mangonel = 10
        const Trebuchet = 12
        const Apprentice = 7
        const Mage = 9
        const Arcanist = 11
    end

    namespace Armor:
        const Skirmisher = 2
        const Longbow = 3
        const Crossbow = 4
        const Pikeman = 5
        const Knight = 8
        const Paladin = 9
        const Ballista = 4
        const Mangonel = 5
        const Trebuchet = 6
        const Apprentice = 2
        const Mage = 2
        const Arcanist = 2
    end

    namespace Vitality:
        const Skirmisher = 53
        const Longbow = 53
        const Crossbow = 53
        const Pikeman = 53
        const Knight = 79
        const Paladin = 106
        const Ballista = 53
        const Mangonel = 53
        const Trebuchet = 53
        const Apprentice = 53
        const Mage = 53
        const Arcanist = 53
    end

    namespace Wisdom:
        const Skirmisher = 2
        const Longbow = 3
        const Crossbow = 4
        const Pikeman = 1
        const Knight = 2
        const Paladin = 3
        const Ballista = 2
        const Mangonel = 3
        const Trebuchet = 4
        const Apprentice = 8
        const Mage = 9
        const Arcanist = 10
    end
end

# one packed troop fits into 2 bytes (troop ID + vitality)
# one felt is ~31 bytes -> can hold 15 troops
# ==> the whole Squad can be packed into a single felt
struct Squad:
    # tier 1 troops
    member t1_1 : Troop
    member t1_2 : Troop
    member t1_3 : Troop
    member t1_4 : Troop
    member t1_5 : Troop
    member t1_6 : Troop
    member t1_7 : Troop
    member t1_8 : Troop
    member t1_9 : Troop

    # tier 2 troops
    member t2_1 : Troop
    member t2_2 : Troop
    member t2_3 : Troop
    member t2_4 : Troop
    member t2_5 : Troop

    # tier 3 troop
    member t3_1 : Troop
end

struct SquadStats:
    member agility : felt
    member attack : felt
    member armor : felt
    member vitality : felt
    member wisdom : felt
end

# this struct holds everything related to a Realm & combat
# a Realm can have two squads, one used for attacking
# and another used for defending; this struct holds them
struct RealmCombatData:
    member attacking_squad : felt  # packed Squad
    member defending_squad : felt  # packed Squad
    member last_attacked_at : felt
end

# struct holding how much resources does it cost to build/buy a thing
struct Cost:
    # the count of unique ResourceIds necessary
    member resource_count : felt
    # how many bits are the packed members packed into
    member bits : felt
    # packed IDs of the necessary resources
    member packed_ids : felt
    # packed amounts of each resource
    member packed_amounts : felt
end

struct ResourceOutput:
    member resource_1 : felt
    member resource_2 : felt
    member resource_3 : felt
    member resource_4 : felt
    member resource_5 : felt
    member resource_6 : felt
    member resource_7 : felt
end

# Packed Military Buildings
struct PackedBuildings:
    member military : felt
    member economic : felt
    member housing : felt
end

# Farm Harvest Types
namespace HarvestType:
    const Export = 1
    const Store = 2
end

struct FoodBuildings:
    member number_built : felt
    member collections_left : felt
    member update_time : felt
end
