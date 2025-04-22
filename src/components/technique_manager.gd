class_name TechniqueManager
extends Node

# Format: { TechniqueDataResource: {"level": int, "cooldown_progress": float} }
var active_techniques: Dictionary = {}

# Reference to the player node (needed for stat calculations)
var player_node: Player

const StatType = Enums.StatType # Use unified StatType

func _ready() -> void:
	# Attempt to get the player node (assuming TechniqueManager is a child of Player)
	player_node = get_owner() as Player
	if not is_instance_valid(player_node):
		printerr("TechniqueManager: Could not find valid Player owner!")
		# Handle error appropriately, maybe disable the manager?
		set_process(false)
		return

	player_node.player_stats_updated.connect(_on_player_stats_updated)

func add_technique(technique_data: TechniqueData) -> bool:
	if not is_instance_valid(technique_data):
		printerr("TechniqueManager: Tried to add invalid technique data!")
		return false
		
	if not active_techniques.has(technique_data):
		active_techniques[technique_data] = {"level": 1, "cooldown_progress": 0.0}
		print("TechniqueManager: Added technique '", technique_data.technique_name, "' at Level 1.")
		# Calculate initial stats using the player reference
		_update_technique_stats(technique_data)
		return true
	return false

func level_up_technique(technique_data: TechniqueData) -> bool:
	if not is_instance_valid(technique_data):
		printerr("TechniqueManager: Tried to level up invalid technique data!")
		return false

	if active_techniques.has(technique_data):
		var state = active_techniques[technique_data]
		state["level"] += 1
		print("TechniqueManager: Leveled up '", technique_data.technique_name, "' to Level ", state["level"])
		# Recalculate stats after level up
		_update_technique_stats(technique_data)
		return true
	else:
		printerr("TechniqueManager: Tried to level up technique '", technique_data.technique_name, "' which is not active.")
		return false

func get_active_techniques() -> Dictionary:
	# Returns the full dictionary { TechniqueData: {"level": int, "cooldown_progress": float} }
	return active_techniques

func _process(delta: float) -> void:
	for technique_data in active_techniques.keys():
		if not is_instance_valid(technique_data):
			printerr("TechniqueManager: Invalid technique data found in active list during process. Removing.")
			active_techniques.erase(technique_data)
			continue
		if not technique_data is TechniqueData:
			printerr("TechniqueManager: Non-TechniqueData found in active list. Type: ", typeof(technique_data))
			continue

		var state = active_techniques[technique_data]

		state["cooldown_progress"] -= delta

		if state["cooldown_progress"] <= 0:
			# Call trigger_technique correctly (level is not needed anymore)
			trigger_technique(technique_data, state["level"]) # Pass level for cooldown calc below

			# Calculate cooldown based on current level stats
			var current_cooldown_variant = StatCalculator.calculate_technique_stat(player_node, technique_data, StatType.TECHNIQUE_COOLDOWN, state["level"])

			var current_cooldown: float
			if typeof(current_cooldown_variant) in [TYPE_FLOAT, TYPE_INT]:
				current_cooldown = float(current_cooldown_variant)
			else:
				printerr("TechniqueManager: Invalid cooldown type calculated for '", technique_data.technique_name, "' (Level ", state["level"], "). Received: ", current_cooldown_variant)
				current_cooldown = 1.0

			if current_cooldown <= 0.01:
				current_cooldown = 0.01

			# Add the full cooldown duration back to the progress
			state["cooldown_progress"] += current_cooldown

func trigger_technique(technique_data: TechniqueData, _level: int) -> void: # _level is unused now
	if not is_instance_valid(technique_data) or not is_instance_valid(technique_data.activation_strategy):
		printerr("TechniqueManager: Invalid TechniqueData or missing activation strategy for trigger.")
		return

	if not is_instance_valid(player_node) or not player_node is Node2D:
		printerr("TechniqueManager: Owner is not a valid Node2D (Player). Cannot trigger technique.")
		return

	# Get the pre-calculated stats stored in the state
	if not active_techniques.has(technique_data):
		printerr("TechniqueManager: Cannot trigger technique, state not found for: ", technique_data.technique_name)
		return
	var state = active_techniques[technique_data]
	var calculated_stats = state.get("calculated_stats", {})

	# Activate the technique, passing the player and calculated stats
	# --- UPDATED: Pass technique_data to activate ---
	technique_data.activation_strategy.activate(player_node, calculated_stats, technique_data)
	# --- END UPDATED ---

# Recalculates and stores the final stats for a given technique
func _update_technique_stats(technique_data: TechniqueData) -> void:
	if not active_techniques.has(technique_data):
		printerr("TechniqueManager: Trying to update stats for inactive technique: ", technique_data.technique_name)
		return
	if not is_instance_valid(player_node):
		printerr("TechniqueManager: Cannot update stats, Player node is invalid.")
		return

	var state = active_techniques[technique_data]
	var current_level = state["level"]
	var calculated_stats: Dictionary = {}

	# Iterate through all possible TECHNIQUE stats and calculate them
	for stat_type_value in StatType.values():
		var stat_type: StatType = stat_type_value # Explicitly type hint
		# Only calculate TECHNIQUE stats
		if not StatType.keys()[stat_type].begins_with("TECHNIQUE_"):
			continue
		calculated_stats[stat_type] = StatCalculator.calculate_technique_stat(player_node, technique_data, stat_type, current_level)
		# print("  - Calculated %s: %s" % [StatType.keys()[stat_type], str(calculated_stats[stat_type])]) # Debug

	# Store the calculated stats in the technique's state
	state["calculated_stats"] = calculated_stats


func _on_player_stats_updated() -> void:
	# Recalculate all active techniques when player stats are updated
	for technique_data in active_techniques.keys():
		if not is_instance_valid(technique_data):
			printerr("TechniqueManager: Invalid technique data found in active list during stats update. Removing.")
			active_techniques.erase(technique_data)
			continue
		if not technique_data is TechniqueData:
			printerr("TechniqueManager: Non-TechniqueData found in active list. Type: ", typeof(technique_data))
			continue

		_update_technique_stats(technique_data)
		
