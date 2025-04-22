class_name PassiveManager
extends Node

# Format: { PassiveDataResource: {"level": int} }
var active_passives: Dictionary = {}

# Adds a new passive at level 1.
# Returns true if successful, false otherwise.
func add_passive(passive_data: PassiveData) -> bool:
    if not is_instance_valid(passive_data):
        printerr("PassiveManager: Tried to add invalid passive data!")
        return false

    if not active_passives.has(passive_data):
        active_passives[passive_data] = {"level": 1}
        print("PassiveManager: Added passive '", passive_data.passive_name, "' at Level 1.")
        return true
    else:
        printerr("PassiveManager: Tried to add passive '", passive_data.passive_name, "' which is already active.")
        return false

# Levels up an existing passive.
# Returns true if successful, false otherwise.
func level_up_passive(passive_data: PassiveData) -> bool:
    if not is_instance_valid(passive_data):
        printerr("PassiveManager: Tried to level up invalid passive data!")
        return false

    if active_passives.has(passive_data):
        var current_level = active_passives[passive_data]["level"]
        var max_level = passive_data.get_max_level_from_upgrades()

        if current_level < max_level:
            active_passives[passive_data]["level"] += 1
            print("PassiveManager: Leveled up passive '", passive_data.passive_name, "' to Level ", active_passives[passive_data]["level"])
            return true
        else:
            printerr("PassiveManager: Passive '", passive_data.passive_name, "' is already at max level (", max_level, ").")
            return false
    else:
        printerr("PassiveManager: Tried to level up passive '", passive_data.passive_name, "' which is not active.")
        return false

# Returns the dictionary containing all active passives and their levels.
func get_active_passives() -> Dictionary:
    # Returns the full dictionary { PassiveData: {"level": int} }
    return active_passives