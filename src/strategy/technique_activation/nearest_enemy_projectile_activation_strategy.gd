class_name NearestEnemyProjectileActivationStrategy
extends TechniqueActivationStrategy

const StatType = Enums.StatType # Use unified StatType

# Overrides the base activate method
func activate(player: Player, calculated_stats: Dictionary, technique_data: TechniqueData) -> void:
	if not is_instance_valid(player):
		printerr("NearestEnemyProjectile: Invalid Player node provided.")
		return
	if not is_instance_valid(technique_data) or not technique_data.effect_scene:
		printerr("NearestEnemyProjectile: Technique data or effect scene not set!")
		return

	# Get stats from the pre-calculated dictionary
	var damage = _get_stat(calculated_stats, StatType.TECHNIQUE_DAMAGE, 5.0)
	var knockback = _get_stat(calculated_stats, StatType.TECHNIQUE_KNOCKBACK, 50.0)
	var speed = _get_stat(calculated_stats, StatType.TECHNIQUE_SPEED, 300.0)
	var area_size = _get_stat(calculated_stats, StatType.TECHNIQUE_AREA_SIZE, 1.0)
	var piercing = _get_stat(calculated_stats, StatType.TECHNIQUE_PIERCING, 1)
	var amount = _get_stat(calculated_stats, StatType.TECHNIQUE_AMOUNT, 1) # How many projectiles
	var interval = _get_stat(calculated_stats, StatType.TECHNIQUE_INTERVAL, 0.1) # Time between projectiles if amount > 1
	# --- NEW STATS ---
	var hitbox_delay = _get_stat(calculated_stats, StatType.TECHNIQUE_HITBOX_DELAY, 0.0)
	var crit_chance = _get_stat(calculated_stats, StatType.TECHNIQUE_CRIT_CHANCE, 0.0)
	var crit_multiplier = _get_stat(calculated_stats, StatType.TECHNIQUE_CRIT_MULTIPLIER, 2.0)
	var effect_chance = _get_stat(calculated_stats, StatType.TECHNIQUE_EFFECT_CHANCE, 0.0)
	# --- END NEW STATS ---

	# Find the single nearest enemy
	var target_enemy = _find_nearest_enemy(player)

	if not is_instance_valid(target_enemy):
		return

	# Fire 'amount' projectiles towards the single nearest enemy
	for i in range(amount):
		# Check validity again inside loop in case something changes between shots? Unlikely but safe.
		if not is_instance_valid(target_enemy):
			break # Stop firing if target disappears

		var instance = technique_data.effect_scene.instantiate()
		if not instance is Node2D:
			printerr("NearestEnemyProjectile: Instantiated scene is not a Node2D!")
			continue # Skip this projectile

		# Add to scene tree
		player.get_tree().current_scene.add_child(instance)
		instance.global_position = player.global_position

		# Calculate direction
		var direction = (target_enemy.global_position - player.global_position).normalized()

		# Configure the projectile (assuming it has these methods/properties)
		# --- UPDATED: Use initialize instead of set_stats ---
		if instance.has_method("initialize"):
			# Pass all relevant stats, including new ones
			instance.initialize(
				damage,
				knockback,
				area_size,
				speed,
				piercing,
				direction,
				hitbox_delay,
				crit_chance,
				crit_multiplier,
				effect_chance
				# Note: Duration is often handled internally by the projectile's timer,
				# but pass it if your initialize method needs it.
				# If the projectile scene manages its own lifetime via a Timer (like QiBlast),
				# you might not need to pass 'duration' here. Adjust as needed.
			)
		else:
			printerr("NearestEnemyProjectile: Instantiated scene '%s' is missing initialize method." % technique_data.effect_scene.resource_path)
		# --- END UPDATED ---

		# If multiple projectiles, delay the next one
		if amount > 1 and i < amount - 1:
			await player.get_tree().create_timer(interval).timeout

# Helper function to find the single nearest enemy
func _find_nearest_enemy(player: Player) -> Node2D: # Renamed and changed return type
	var nearest_enemy: Node2D = null
	var min_dist_sq: float = INF # Use infinity for initial minimum distance

	var all_nodes = player.get_tree().get_nodes_in_group("Enemy")

	for node in all_nodes:
		# Ensure it's a valid Enemy node and a Node2D
		if node is Enemy and is_instance_valid(node) and node is Node2D:
			var distance_sq = player.global_position.distance_squared_to(node.global_position)
			if distance_sq < min_dist_sq:
				min_dist_sq = distance_sq
				nearest_enemy = node # Update the nearest enemy found so far

	# Return the single nearest enemy found, or null if none were found/valid
	return nearest_enemy
