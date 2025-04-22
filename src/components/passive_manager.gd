class_name PassiveManager
extends Node

# Format: Array[PassiveData]
var active_passives: Array[PassiveData] = []

# Adds a new passive. Assumes the passive's internal level is already set (e.g., to 1).
# Returns true if successful, false otherwise.
func add_passive(passive_data: PassiveData) -> bool:
	if not is_instance_valid(passive_data):
		printerr("PassiveManager: Tried to add invalid passive data!")
		return false

	if not active_passives.has(passive_data):
		active_passives.append(passive_data)
		print("PassiveManager: Added passive '", passive_data.passive_name, "' at Level ", passive_data.level)
		return true
	else:
		printerr("PassiveManager: Tried to add passive '", passive_data.passive_name, "' which is already active.")
		return false

# Levels up an existing passive by incrementing its internal level.
# Returns true if successful, false otherwise.
func level_up_passive(passive_data: PassiveData) -> bool:
	if not is_instance_valid(passive_data):
		printerr("PassiveManager: Tried to level up invalid passive data!")
		return false

	if active_passives.has(passive_data):
		var current_level = passive_data.level
		var max_level = passive_data.get_max_level_from_upgrades()

		if current_level < max_level:
			passive_data.level += 1
			print("PassiveManager: Leveled up passive '", passive_data.passive_name, "' to Level ", passive_data.level)
			return true
		else:
			printerr("PassiveManager: Passive '", passive_data.passive_name, "' is already at max level (", max_level, ").")
			return false
	else:
		printerr("PassiveManager: Tried to level up passive '", passive_data.passive_name, "' which is not active.")
		return false

# Returns the array containing all active passive data resources.
func get_active_passives() -> Array[PassiveData]:
	# Returns the full array [PassiveData, PassiveData, ...]
	return active_passives