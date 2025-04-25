class_name AlternatingSweepActivationStrategy
extends TechniqueActivationStrategy

const StatType = Enums.StatType # Use unified StatType

# Overrides the base activate method
func activate(player: Player, calculated_stats: Dictionary, technique_data: TechniqueData) -> void:
	if not is_instance_valid(player):
		printerr("AlternatingSweep: Invalid Player node provided.")
		return
	if not is_instance_valid(technique_data) or not technique_data.effect_scene:
		printerr("AlternatingSweep: Technique data or effect scene not set!")
		return

	# Get amount and interval for the loop, others are handled by the instance
	var amount = calculated_stats.get(StatType.TECHNIQUE_AMOUNT, 1) # How many sweeps per activation
	var interval = calculated_stats.get(StatType.TECHNIQUE_INTERVAL, 0.1) # Time between sweeps if amount > 1

	# --- Determine initial direction based on player sprite scale ---
	var current_attack_direction: float = 1.0 # Default to right
	if is_instance_valid(player) and is_instance_valid(player.sprite):
		current_attack_direction = player.sprite.scale.x
	else:
		printerr("AlternatingSweep: Player or player sprite is invalid, defaulting direction.")
	# --- End determine initial direction ---

	for i in range(amount):
		var instance = technique_data.effect_scene.instantiate()
		if not instance is Node2D:
			printerr("AlternatingSweep: Instantiated scene is not a Node2D!")
			# Clean up if instantiation failed partially
			if is_instance_valid(instance):
				instance.queue_free()
			return

		# Calculate offset position based on current_attack_direction
		var hitbox_size_multiplier = calculated_stats.get(StatType.TECHNIQUE_AREA_SIZE, 1.0)
		var hitbox_length = instance.base_hitbox_length * hitbox_size_multiplier

		var offset_x = (hitbox_length / 2) * current_attack_direction
		var offset = Vector2(offset_x, 0)
		instance.global_position = player.global_position + offset

		instance.scale.x = current_attack_direction # Flip the instance to match the direction

		# Call initialize, passing the whole dictionary
		if instance.has_method("initialize"):
			instance.initialize(calculated_stats) # Pass the dictionary
		else:
			printerr("AlternatingSweep: Instantiated scene '%s' is missing initialize method." % technique_data.effect_scene.resource_path)
			# Clean up if initialization is not possible
			if is_instance_valid(instance):
				instance.queue_free()
			return # Stop processing if initialization fails

		# Add to the scene tree (important for timers etc.)
		player.get_tree().current_scene.add_child(instance)

		# Flip direction for the *next* sweep in this activation
		current_attack_direction *= -1
		
		# If multiple sweeps, delay the next one
		if amount > 1 and i < amount - 1:
			# Check if player is still valid before creating timer
			if not is_instance_valid(player):
				printerr("AlternatingSweep: Player became invalid during multi-sweep delay.")
				return # Stop processing if player is gone

			# Simple delay using await and a scene tree timer
			# Ensure the tree is valid
			var tree = player.get_tree()
			if not is_instance_valid(tree):
				printerr("AlternatingSweep: Scene tree became invalid during multi-sweep delay.")
				return # Stop processing if tree is gone

			await tree.create_timer(interval).timeout

			# Check again after await, in case player or scene changed during the delay
			if not is_instance_valid(player):
				printerr("AlternatingSweep: Player became invalid after multi-sweep delay.")
				return # Stop processing if player is gone
