class_name TechniqueManager
extends Node

# Store active technique instances directly in an array
var active_techniques: Array[TechniqueData] = []

# Reference to the player node (needed for stat calculations)
var player_node: Player

const StatType = Enums.StatType # Use unified StatType
const UpgradeType = Enums.UpgradeType

func _ready() -> void:
	# Attempt to get the player node (assuming TechniqueManager is a child of Player)
	player_node = get_owner() as Player
	if not is_instance_valid(player_node):
		printerr("TechniqueManager: Could not find valid Player owner!")
		# Handle error appropriately, maybe disable the manager?
		set_process(false)
		return

	player_node.player_stats_updated.connect(_on_player_stats_updated)
	GlobalEvents.upgrade_selected.connect(_on_upgrade_selected)

func add_technique(technique_data: TechniqueData) -> bool:
	if not is_instance_valid(technique_data):
		printerr("TechniqueManager: Tried to add invalid technique data!")
		return false
		
	if not active_techniques.has(technique_data):
		active_techniques.append(technique_data)
		print("TechniqueManager: Added technique '", technique_data.technique_name, "' at Level 1.")
		# Calculate initial stats using the player reference
		_update_technique_stats(technique_data)
		return true
	return false

func level_up_technique(technique_data: TechniqueData) -> bool:
	if not is_instance_valid(technique_data):
		printerr("TechniqueManager: Tried to level up invalid technique data resource!")
		return false

	var technique_instance = _find_active_technique(technique_data.resource_path)
	if technique_instance != null:
		technique_instance.level += 1
		print("TechniqueManager: Leveled up '", technique_instance.technique_name, "' to Level ", technique_instance.level)
		# Recalculate stats after level up
		_update_technique_stats(technique_instance)
		return true
	else:
		printerr("TechniqueManager: Tried to level up technique '", technique_data.technique_name, "' which is not active.")
		return false

func get_active_techniques() -> Array[TechniqueData]:
	# Returns the array of active TechniqueData instances
	return active_techniques

# Helper function to find an active technique instance by its resource path
func _find_active_technique(resource_path: String) -> TechniqueData:
	for technique in active_techniques:
		if is_instance_valid(technique) and technique.resource_path == resource_path:
			return technique
	return null

func _process(delta: float) -> void:
	# Iterate backwards for safe removal if needed (though validation should prevent most issues)
	for i in range(active_techniques.size() - 1, -1, -1):
		var technique_instance = active_techniques[i]

		if not is_instance_valid(technique_instance):
			printerr("TechniqueManager: Invalid technique instance found in active list during process. Removing.")
			active_techniques.remove_at(i)
			continue
		if not technique_instance is TechniqueData:
			printerr("TechniqueManager: Non-TechniqueData found in active list. Type: ", typeof(technique_instance), ". Removing.")
			active_techniques.remove_at(i)
			continue

		# Access state directly from the instance
		technique_instance.cooldown_progress -= delta

		if technique_instance.cooldown_progress <= 0:
			# Trigger the specific instance
			trigger_technique(technique_instance)

			# Calculate cooldown based on the instance's current level stats
			var current_cooldown_variant = StatCalculator.calculate_technique_stat(player_node, technique_instance, StatType.TECHNIQUE_COOLDOWN, technique_instance.level)

			var current_cooldown: float
			if typeof(current_cooldown_variant) in [TYPE_FLOAT, TYPE_INT]:
				current_cooldown = float(current_cooldown_variant)
			else:
				printerr("TechniqueManager: Invalid cooldown type calculated for '", technique_instance.technique_name, "' (Level ", technique_instance.level, "). Received: ", current_cooldown_variant)
				current_cooldown = 1.0 # Default cooldown on error

			if current_cooldown <= 0.01: # Prevent division by zero or excessively fast triggers
				current_cooldown = 0.01

			# Add the full cooldown duration back to the instance's progress
			technique_instance.cooldown_progress += current_cooldown

func trigger_technique(technique_instance: TechniqueData) -> void: # Now takes the instance directly
	if not is_instance_valid(technique_instance) or not is_instance_valid(technique_instance.activation_strategy):
		printerr("TechniqueManager: Invalid TechniqueData instance or missing activation strategy for trigger.")
		return

	if not is_instance_valid(player_node) or not player_node is Node2D:
		printerr("TechniqueManager: Owner is not a valid Node2D (Player). Cannot trigger technique.")
		return

	# Get the pre-calculated stats stored in the instance
	var calculated_stats = technique_instance.calculated_stats

	# Activate the technique, passing the player, calculated stats, and the instance itself
	technique_instance.activation_strategy.activate(player_node, calculated_stats, technique_instance)

# Recalculates and stores the final stats for a given technique instance
func _update_technique_stats(technique_instance: TechniqueData) -> void:
	if not is_instance_valid(technique_instance):
		printerr("TechniqueManager: Trying to update stats for an invalid technique instance.")
		return
	if not active_techniques.has(technique_instance): # Check if it's actually in our active list
		printerr("TechniqueManager: Trying to update stats for technique '", technique_instance.technique_name, "' which is not managed by this manager.")
		return
	if not is_instance_valid(player_node):
		printerr("TechniqueManager: Cannot update stats, Player node is invalid.")
		return

	var current_level = technique_instance.level
	var calculated_stats: Dictionary = {}

	# Iterate through all possible TECHNIQUE stats and calculate them
	for stat_type_value in StatType.values():
		var stat_type: StatType = stat_type_value # Explicitly type hint
		# Only calculate TECHNIQUE stats
		var stat_name = StatType.keys()[stat_type]
		if not stat_name.begins_with("TECHNIQUE_"):
			continue

		calculated_stats[stat_type] = StatCalculator.calculate_technique_stat(player_node, technique_instance, stat_type, current_level)
		# print("  - Calculated %s: %s" % [stat_name, str(calculated_stats[stat_type])]) # Debug

	# Store the calculated stats directly in the technique's instance
	technique_instance.calculated_stats = calculated_stats

func _on_player_stats_updated() -> void:
	# Recalculate all active techniques when player stats are updated
	for technique_instance in active_techniques:
		_update_technique_stats(technique_instance)

func _on_upgrade_selected(selected_upgrade_data: Dictionary) -> void: 
	var upgrade_type: UpgradeType = selected_upgrade_data.get("type", UpgradeType.UNKNOWN) 
	if UpgradeType.keys()[upgrade_type].contains("TECHNIQUE") == false:
		return

	var upgrade_resource: TechniqueData = selected_upgrade_data.get("resource")

	match upgrade_type: 
		UpgradeType.TECHNIQUE_UPGRADE:
			level_up_technique(upgrade_resource)
		UpgradeType.NEW_TECHNIQUE:
			add_technique(upgrade_resource)
