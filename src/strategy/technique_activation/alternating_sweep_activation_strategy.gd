class_name AlternatingSweepActivationStrategy
extends TechniqueActivationStrategy

const StatType = Enums.StatType # Use unified StatType
@export var horizontal_offset: float = 40.0 # How far to offset the sweep horizontally

# Overrides the base activate method
func activate(player: Player, calculated_stats: Dictionary, technique_data: TechniqueData) -> void:
	if not is_instance_valid(player):
		printerr("AlternatingSweep: Invalid Player node provided.")
		return
	if not is_instance_valid(technique_data) or not technique_data.effect_scene:
		printerr("AlternatingSweep: Technique data or effect scene not set!")
		return

	# Get stats from the pre-calculated dictionary
	var damage = _get_stat(calculated_stats, StatType.TECHNIQUE_DAMAGE, 10.0)
	var knockback = _get_stat(calculated_stats, StatType.TECHNIQUE_KNOCKBACK, 100.0)
	var area_size = _get_stat(calculated_stats, StatType.TECHNIQUE_AREA_SIZE, 1.0)
	var duration = _get_stat(calculated_stats, StatType.TECHNIQUE_DURATION, 0.5)
	var amount = _get_stat(calculated_stats, StatType.TECHNIQUE_AMOUNT, 1) # How many sweeps per activation
	var interval = _get_stat(calculated_stats, StatType.TECHNIQUE_INTERVAL, 0.1) # Time between sweeps if amount > 1
	var hitbox_delay = _get_stat(calculated_stats, StatType.TECHNIQUE_HITBOX_DELAY, 0.0)
	var crit_chance = _get_stat(calculated_stats, StatType.TECHNIQUE_CRIT_CHANCE, 0.0)
	var crit_multiplier = _get_stat(calculated_stats, StatType.TECHNIQUE_CRIT_MULTIPLIER, 2.0)
	var effect_chance = _get_stat(calculated_stats, StatType.TECHNIQUE_EFFECT_CHANCE, 0.0)

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
			return

		# Add to the scene tree (important for timers etc.)
		player.get_tree().current_scene.add_child(instance)
		
		# Calculate offset position based on current_attack_direction
		var offset = Vector2(horizontal_offset * current_attack_direction, 0)
		instance.global_position = player.global_position + offset

		instance.scale.x = current_attack_direction # Flip the instance to match the direction

		# Call initialize
		if instance.has_method("initialize"):
			instance.initialize(
				damage,
				knockback,
				area_size,
				duration,
				hitbox_delay,
				crit_chance,
				crit_multiplier,
				effect_chance
			)
		else:
			printerr("AlternatingSweep: Instantiated scene '%s' is missing initialize method." % technique_data.effect_scene.resource_path)

		# Flip direction for the *next* sweep in this activation
		current_attack_direction *= -1

		# If multiple sweeps, delay the next one
		if amount > 1 and i < amount - 1:
			# Check if player is still valid before creating timer
			if not is_instance_valid(player):
				printerr("AlternatingSweep: Player became invalid during multi-sweep delay.")
				return

			# Simple delay using await and a scene tree timer
			await player.get_tree().create_timer(interval).timeout

			# Check again after await, in case player or scene changed during the delay
			if not is_instance_valid(player):
				printerr("AlternatingSweep: Player became invalid after multi-sweep delay.")
				return
