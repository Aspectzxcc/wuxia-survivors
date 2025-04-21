extends Resource
class_name PassiveData

@export var passive_name: String = "Passive Name"
@export var description: String = "Passive Description"
@export var icon: Texture2D

@export var level_upgrades: Array[UpgradeData]

func get_max_level_from_upgrades() -> int:
    var max_defined_level = 0
    if level_upgrades:
        for upgrade in level_upgrades:
            if upgrade is UpgradeData and upgrade.level > max_defined_level:
                max_defined_level = upgrade.level
    return max(1, max_defined_level)

func get_upgrade_for_level(target_level: int) -> UpgradeData:
    if level_upgrades:
        for upgrade in level_upgrades:
            if upgrade is UpgradeData and upgrade.level == target_level:
                return upgrade
    return null
