extends Node

# Generates upgrade options based on the player's current state
func generate_upgrade_options(player: Node, num_options: int = 3) -> Array[Dictionary]:
	if not is_instance_valid(player):
		printerr("UpgradeGenerator: Invalid player node provided.")
		return []

	var technique_manager = player.get_node_or_null("TechniqueManager")
	var passive_manager = player.get_node_or_null("PassiveManager") # Get the PassiveManager

	if not is_instance_valid(technique_manager):
		printerr("UpgradeGenerator: Player does not have a TechniqueManager node.")
		# Decide if you want to return [] or continue without technique options
	if not is_instance_valid(passive_manager):
		printerr("UpgradeGenerator: Player does not have a PassiveManager node.")
		# Decide if you want to return [] or continue without passive options

	var possible_options: Array[Dictionary] = []
	# Assume get_active_techniques/passives now return Array[TechniqueData] / Array[PassiveData]
	var active_techs: Array[TechniqueData] = []
	var active_passives: Array[PassiveData] = []

	if is_instance_valid(technique_manager):
		active_techs = technique_manager.get_active_techniques()
	if is_instance_valid(passive_manager):
		active_passives = passive_manager.get_active_passives()

	# --- Option Type 1: Upgrade Existing Techniques ---
	if is_instance_valid(technique_manager):
		for tech_data in active_techs:
			# Assume TechniqueManager has a method to get the current level
			var current_level: int = tech_data.level
			var next_level_upgrade = tech_data.get_upgrade_for_level(current_level + 1)
			if next_level_upgrade:
				possible_options.append({
					"name": "Upgrade %s (L%d)" % [tech_data.technique_name, current_level + 1],
					"description": next_level_upgrade.description,
					"icon": tech_data.icon,
					"type": Enums.UpgradeType.TECHNIQUE_UPGRADE,
					"resource": tech_data # Store the resource itself
				})

	# --- Option Type 2: Learn New Techniques ---
	if is_instance_valid(technique_manager):
		for tech_data in GameData.get_all_techniques():
			# Check if the TechniqueData resource itself is in the active array
			if not active_techs.has(tech_data):
				possible_options.append({
					"name": "Learn %s" % tech_data.technique_name,
					"description": tech_data.description,
					"icon": tech_data.icon,
					"type": Enums.UpgradeType.NEW_TECHNIQUE,
					"resource": tech_data # Store the resource itself
				})

	# --- Option Type 3: Upgrade Existing Passives ---
	if is_instance_valid(passive_manager):
		for passive_data in active_passives:
			# Assume PassiveManager has a method to get the current level
			var current_level: int = passive_data.level
			var next_level_upgrade = passive_data.get_upgrade_for_level(current_level + 1)
			if next_level_upgrade:
				possible_options.append({
					"name": "Upgrade %s (L%d)" % [passive_data.passive_name, current_level + 1],
					"description": next_level_upgrade.description,
					"icon": passive_data.icon,
					"type": Enums.UpgradeType.PASSIVE_UPGRADE,
					"resource": passive_data # Store the resource itself
				})

	# --- Option Type 4: Learn New Passives ---
	if is_instance_valid(passive_manager):
		for passive_data in GameData.get_all_passives():
			# Check if the PassiveData resource itself is in the active array
			if not active_passives.has(passive_data):
				var level_1_upgrade = passive_data.get_upgrade_for_level(1)
				if level_1_upgrade:
					possible_options.append({
						"name": "Learn %s" % passive_data.passive_name,
						"description": passive_data.description,
						"icon": passive_data.icon,
						"type": Enums.UpgradeType.NEW_PASSIVE,
						"resource": passive_data # Store the resource itself
					})

	# --- Select and Return ---
	possible_options.shuffle()

	# Ensure we don't offer more options than available
	num_options = min(num_options, possible_options.size())

	if possible_options.size() > num_options:
		possible_options.resize(num_options)

	return possible_options
