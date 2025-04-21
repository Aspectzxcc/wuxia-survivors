class_name StatCalculator
extends RefCounted

const StatType = Enums.StatType
const ModifierType = Enums.ModifierType

# Calculates the approximate experience points needed to reach the next level.
# Based on a generalized power curve similar to Vampire Survivors, but not exact.
# Formula: XP ≈ 5 * (current_level ^ 1.25)
static func get_xp_for_next_level(current_level: int) -> int:
	if current_level <= 0:
		# XP needed to reach level 1 from level 0 (or initial state)
		return 5 
	
	# Use float for pow calculation
	var required_xp_float = 5.0 * pow(float(current_level), 1.25)
	
	# Round to nearest integer and ensure a minimum XP requirement
	return max(1, int(round(required_xp_float)))

static func calculate_player_stat(player: Player, stat_type: StatType) -> Variant:
	if not is_instance_valid(player):
		printerr("StatCalculator: Invalid Player provided for player stat calculation.")
		return get_default_value_for_stat(stat_type)

	var base_value = player.base_stats.get(stat_type, get_default_value_for_stat(stat_type))
	var modifiers = player.get_modifiers_for_stat(stat_type)

	return apply_modifiers(base_value, modifiers, stat_type)


static func calculate_technique_stat(player: Player, technique_data: TechniqueData, stat_type: StatType, level: int) -> Variant:
	if not is_instance_valid(technique_data):
		printerr("StatCalculator: Invalid TechniqueData provided.")
		return get_default_value_for_stat(stat_type)
	if not is_instance_valid(player):
		printerr("StatCalculator: Invalid Player provided for technique stat calculation.")
		return get_default_value_for_stat(stat_type)

	level = max(1, level)

	var base_value: Variant = technique_data.get_base_stat_value(stat_type)

	var relevant_modifiers: Array[StatModifier] = []

	# 1. Collect modifiers from Technique Upgrades (Levels 2 to current)
	if level > 1 and technique_data.level_upgrades != null:
		for i in range(2, level + 1):
			var upgrade_data: UpgradeData = technique_data.get_upgrade_for_level(i)
			if is_instance_valid(upgrade_data):
				if upgrade_data.has_method("get_modifications"):
					var mods_this_level: Array = upgrade_data.get_modifications()
					if mods_this_level is Array:
						for modifier in mods_this_level:
							if modifier is StatModifier and \
							StatType.keys()[modifier.stat].begins_with("TECHNIQUE_") and \
							modifier.stat == stat_type:
								relevant_modifiers.append(modifier)
					else:
						printerr("StatCalculator: UpgradeData.get_modifications() did not return an Array for ", technique_data.technique_name, " L", i)
				else:
					printerr("StatCalculator: UpgradeData is missing get_modifications() method for ", technique_data.technique_name, " L", i)

	# 2. Apply technique-specific modifiers first
	var value_after_technique_mods = apply_modifiers(base_value, relevant_modifiers, stat_type)

	# 3. Apply relevant GLOBAL player stats as final multipliers/additives
	var final_value = value_after_technique_mods

	var global_stat_map = {
		StatType.TECHNIQUE_DAMAGE: StatType.PLAYER_DAMAGE,
		StatType.TECHNIQUE_AREA_SIZE: StatType.PLAYER_AREA_SIZE,
		StatType.TECHNIQUE_DURATION: StatType.PLAYER_DURATION,
		StatType.TECHNIQUE_SPEED: StatType.PLAYER_SPEED,
		StatType.TECHNIQUE_AMOUNT: StatType.PLAYER_AMOUNT,
		StatType.TECHNIQUE_COOLDOWN: StatType.PLAYER_COOLDOWN,
	}

	if global_stat_map.has(stat_type):
		var player_stat = global_stat_map[stat_type]
		if stat_type == StatType.TECHNIQUE_AMOUNT:
			final_value = int(final_value) + player.final_stats.get(player_stat, 0)
		else:
			var multiplier = player.final_stats.get(player_stat, 1.0)
			final_value = float(final_value) * multiplier

	return _convert_to_stat_type(final_value, stat_type)

# Applies an array of StatModifiers to a base value according to VS logic.
# VS typically applies bonuses as: (Base + FlatAdd) * Product_of_Multipliers * (1 + Sum_of_PercentageAdds)
# SET overrides everything.
static func apply_modifiers(base_value: Variant, modifiers: Array, stat_type: StatType) -> Variant:
	var is_int_stat = _is_integer_stat(stat_type)
	var current_value_float : float = float(base_value)

	var flat_addition: float = 0.0
	var multiplier_product: float = 1.0
	var percentage_addition_sum: float = 0.0
	var set_value: Variant = null

	for modifier in modifiers:
		if not modifier is StatModifier:
			printerr("StatCalculator: Encountered non-StatModifier item in modifiers list: ", modifier)
			continue

		if modifier.stat != stat_type:
			printerr("StatCalculator: Modifier stat type mismatch for stat ", StatType.keys()[stat_type], ". Modifier is for ", StatType.keys()[modifier.stat])
			continue

		match modifier.type:
			ModifierType.ADD:
				flat_addition += modifier.value
			ModifierType.MULTIPLY:
				multiplier_product *= modifier.value
			ModifierType.ADD_PERCENTAGE:
				percentage_addition_sum += modifier.value
			ModifierType.SET:
				set_value = modifier.value # SET overrides others, take the last one encountered
			_:
				printerr("StatCalculator: Unknown modifier type encountered: ", modifier.type)

	var final_value_variant: Variant
	if set_value != null:
		final_value_variant = set_value
	else:
		# Apply formula: (Base + FlatAdd) * MultiplierProduct * (1 + PercentageAddSum)
		var calculated_float = (current_value_float + flat_addition) * multiplier_product * (1.0 + percentage_addition_sum)

		if stat_type == StatType.TECHNIQUE_COOLDOWN:
			calculated_float = max(0.1, calculated_float)
		elif stat_type == StatType.PLAYER_COOLDOWN:
			calculated_float = max(0.1, calculated_float)

		if is_int_stat:
			final_value_variant = int(round(calculated_float))
		else:
			final_value_variant = calculated_float

	return _convert_to_stat_type(final_value_variant, stat_type)


# Determines if a stat should fundamentally be an integer.
static func _is_integer_stat(stat_type: StatType) -> bool:
	match stat_type:
		StatType.PLAYER_MAX_HEALTH, StatType.PLAYER_ARMOR, StatType.PLAYER_AMOUNT:
			return true
		StatType.TECHNIQUE_ATTACK_COUNT, StatType.TECHNIQUE_PIERCING, StatType.TECHNIQUE_AMOUNT:
			return true
		_:
			return false

# Gets a sensible default value for a stat if none is defined.
static func get_default_value_for_stat(stat_type: StatType) -> Variant:
	match stat_type:
		StatType.PLAYER_DAMAGE, StatType.PLAYER_MOVE_SPEED, StatType.PLAYER_QI_GAIN, StatType.PLAYER_LUCK, \
		StatType.PLAYER_GREED, StatType.PLAYER_AREA_SIZE, StatType.PLAYER_DURATION, StatType.PLAYER_SPEED, \
		StatType.PLAYER_COOLDOWN, StatType.PLAYER_CURSE, StatType.TECHNIQUE_RARITY, \
		StatType.TECHNIQUE_AREA_SIZE, StatType.TECHNIQUE_CRIT_MULTIPLIER, StatType.TECHNIQUE_COOLDOWN, \
		StatType.PLAYER_CRIT_CHANCE:
			return 1.0
		StatType.PLAYER_MAX_HEALTH:
			return 100.0
		StatType.PLAYER_MAGNET:
			return 64.0
		StatType.TECHNIQUE_DAMAGE, StatType.TECHNIQUE_KNOCKBACK, StatType.TECHNIQUE_SPEED, \
		StatType.TECHNIQUE_DURATION, StatType.TECHNIQUE_INTERVAL, StatType.TECHNIQUE_HITBOX_DELAY, \
		StatType.TECHNIQUE_CRIT_CHANCE, StatType.TECHNIQUE_EFFECT_CHANCE, StatType.PLAYER_DEFANG, \
		StatType.PLAYER_RECOVERY, StatType.PLAYER_ARMOR:
			return 0.0
		StatType.PLAYER_REVIVAL, StatType.PLAYER_REROLL, StatType.PLAYER_SKIP, StatType.PLAYER_BANISH, StatType.PLAYER_CHARM, \
		StatType.PLAYER_SEAL, StatType.PLAYER_AMOUNT:
			return 0			
		StatType.TECHNIQUE_ATTACK_COUNT, StatType.TECHNIQUE_AMOUNT, StatType.TECHNIQUE_PIERCING:
			return 1
		StatType.TECHNIQUE_BLOCKABLE:
			return false
		_:
			printerr("StatCalculator: Unknown StatType requested for default value: ", Enums.StatType.keys()[stat_type])
			return 0

# Converts a calculated Variant value to the appropriate type for the stat.
static func _convert_to_stat_type(value: Variant, stat_type: StatType) -> Variant:
	if _is_integer_stat(stat_type):
		if typeof(value) == TYPE_FLOAT:
			return int(round(value))
		elif typeof(value) == TYPE_INT:
			return value
		else:
			var int_val = int(value)
			if typeof(int_val) == TYPE_INT:
				return int_val
			else:
				var stat_name = StatType.keys()[stat_type]
				printerr("StatCalculator: Could not convert value '", value, "' to int for stat ", stat_name)
				return 0
	else:
		if typeof(value) == TYPE_INT:
			return float(value)
		elif typeof(value) == TYPE_FLOAT:
			return value
		else:
			var float_val = float(value)
			if typeof(float_val) == TYPE_FLOAT:
				return float_val
			else:
				var stat_name = StatType.keys()[stat_type]
				printerr("StatCalculator: Could not convert value '", value, "' to float for stat ", stat_name)
				return 0.0
