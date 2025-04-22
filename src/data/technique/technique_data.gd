class_name TechniqueData extends Resource

# --- Runtime State (Not saved in the resource file) ---
# These are managed by the TechniqueManager when an instance is active
var level: int = 1
var cooldown_progress: float = 0.0
var calculated_stats: Dictionary = {} # Stores stats calculated based on current level and player stats

# --- Configuration (Saved in the resource file) ---
@export var technique_name: String = "Unnamed Technique"
@export var description: String = ""
@export var icon: Texture
@export var effect_scene: PackedScene # The visual/hitbox scene for the technique

# --- Base Stats (Level 1) ---
# These should generally align with the MINIMUM values in the VS table for level 1
@export_group("Base Stats (Level 1)")
@export var base_cooldown: float = 3.0      # Lower is better
@export var base_damage: float = 10.0
@export var base_area_size: float = 1.0     # Multiplier (1.0 = 100%)
@export var base_duration: float = 0.5      # How long effect/hitbox lasts
@export var base_attack_count: int = 1      # How many separate instances/activations per cooldown cycle
@export var base_knockback: float = 1.0
@export var base_speed: float = 300.0 # Relevant mainly for projectiles
@export var base_piercing: int = 1          # Relevant mainly for projectiles (1 = hits 1 enemy)
@export var base_amount: int = 1            # Projectiles/hits per attack_count (e.g. knives per throw)
@export var base_interval: float = 0.1      # Delay between 'Amount' hits (Lower is better)
@export var base_hitbox_delay: float = 0.0  # Delay before hitbox activates (Lower is better)
@export var base_crit_chance: float = 0.0   # Base crit chance % (0.0 to 1.0)
@export var base_crit_multiplier: float = 2.0 # Multiplier on crit (e.g., 2.0 = 2x damage)
@export var base_effect_chance: float = 0.0 # Base status effect chance % (0.0 to 1.0)
@export var base_blockable: bool = false     # Whether the technique can be blocked by obstacles
@export var base_rarity: float = 1.0 	    # Technique rarity, 1.0 = 100% chance to be selected

@export_group("Behavior & Meta")
@export var activation_strategy: TechniqueActivationStrategy # How the technique is triggered/aimed
# @export var pool_limit: int = 100 # Example: How often it can appear (Handled by UpgradeGenerator/GameData)

@export_group("Level Upgrades")
@export var level_upgrades: Array[UpgradeData]

# --- Functions ---
func get_max_level_from_upgrades() -> int:
	var max_defined_level = 0
	if level_upgrades == null: return 1
	for upgrade in level_upgrades:
		if upgrade is UpgradeData:
			if upgrade.level > max_defined_level:
				max_defined_level = upgrade.level
	return max(1, max_defined_level)

func get_upgrade_for_level(target_level: int) -> UpgradeData:
	if level_upgrades == null: return null
	for upgrade in level_upgrades:
		if upgrade is UpgradeData:
			if upgrade.level == target_level:
				return upgrade
	return null

# Helper to get a specific base stat value by enum
# Needed by StatCalculator
const StatType = Enums.StatType # Use unified StatType

func get_base_stat_value(stat_type: StatType) -> Variant:
	match stat_type:
		StatType.TECHNIQUE_COOLDOWN: return base_cooldown
		StatType.TECHNIQUE_DAMAGE: return base_damage
		StatType.TECHNIQUE_AREA_SIZE: return base_area_size
		StatType.TECHNIQUE_DURATION: return base_duration
		StatType.TECHNIQUE_ATTACK_COUNT: return base_attack_count
		StatType.TECHNIQUE_KNOCKBACK: return base_knockback
		StatType.TECHNIQUE_SPEED: return base_speed
		StatType.TECHNIQUE_PIERCING: return base_piercing
		StatType.TECHNIQUE_AMOUNT: return base_amount
		StatType.TECHNIQUE_INTERVAL: return base_interval
		StatType.TECHNIQUE_HITBOX_DELAY: return base_hitbox_delay
		StatType.TECHNIQUE_CRIT_CHANCE: return base_crit_chance
		StatType.TECHNIQUE_CRIT_MULTIPLIER: return base_crit_multiplier
		StatType.TECHNIQUE_EFFECT_CHANCE: return base_effect_chance
		StatType.TECHNIQUE_BLOCKABLE: return base_blockable
		StatType.TECHNIQUE_RARITY: return base_rarity
		_:
			# Check if it's a player stat being requested erroneously
			if StatType.keys()[stat_type].begins_with("PLAYER_"):
				printerr("TechniqueData: Tried to get a PLAYER base stat ('%s') from a TechniqueData." % StatType.keys()[stat_type])
			else:
				printerr("TechniqueData: Tried to get unhandled base stat: ", StatType.keys()[stat_type])
			# Return a default based on expected type (using StatCalculator helper)
			return StatCalculator.get_default_value_for_stat(stat_type)
