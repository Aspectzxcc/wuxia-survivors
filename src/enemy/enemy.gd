class_name Enemy
extends CharacterBody2D

@onready var health: Health = $Health
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var max_despawn_distance : float = 1000.0 # Max distance from player before despawning
@export_range(0.0, 1.0) var base_qi_drop_chance: float = 0.7 # Base chance (0-1) to drop Qi orb

var enemy_data: EnemyData
var current_health: float

const State = Enums.EnemyState
var current_state: State = State.MOVING
var knockback_velocity: Vector2 = Vector2.ZERO
var max_despawn_distance_sq : float # Store squared distance for efficiency

func initialize(data: EnemyData) -> void:
	self.enemy_data = data

func _ready() -> void:
	if enemy_data == null:
		printerr(self.name, ": EnemyData was not provided before _ready(). Destroying.")
		queue_free()
		return

	max_despawn_distance_sq = max_despawn_distance * max_despawn_distance # Calculate squared distance once
		
	if health == null:
		printerr(self.name, ": HealthComponent node not found or path is incorrect! Check node name.")
		queue_free()
		return
		
	health.set_max_health(enemy_data.health)
	health.died.connect(_on_death)

func _physics_process(delta: float) -> void:
	if enemy_data == null or health == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- Despawn Check ---
	if PlayerTracker.is_player_valid:
		var player_pos = PlayerTracker.get_tracked_player_position()
		# Use distance_squared_to for better performance (avoids sqrt)
		if global_position.distance_squared_to(player_pos) > max_despawn_distance_sq:
			queue_free() # Despawn if too far
			return # Stop further processing for this frame
	# --- End Despawn Check ---

	match current_state:
		State.KNOCKED_BACK:
			if enemy_data:
				velocity = velocity.lerp(Vector2.ZERO, enemy_data.knockback_friction * delta)
			else:
				velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
				printerr(self.name, " is missing EnemyData during knockback!")
		
			if velocity.length_squared() < 1.0:
				current_state = State.MOVING
				velocity = Vector2.ZERO

		State.MOVING:
			if PlayerTracker.is_player_valid:
				var player_position = PlayerTracker.get_tracked_player_position()
				var direction = (player_position - global_position).normalized()
				velocity = direction * enemy_data.speed

				if sprite:
					if velocity.x > 0.1:
						sprite.flip_h = false
					elif velocity.x < -0.1:
						sprite.flip_h = true
			else:
				velocity = Vector2.ZERO

	move_and_slide()

func _on_death() -> void:
	GlobalEvents.enemy_killed.emit()

	if enemy_data == null: return

	# --- Calculate Drop Chance with Luck ---
	var final_drop_chance = base_qi_drop_chance
	if PlayerTracker.is_player_valid:
		var player = PlayerTracker.get_tracked_player_node()
		if player != null and player.final_stats.has(Enums.StatType.PLAYER_LUCK):
			var player_luck = player.final_stats.get(Enums.StatType.PLAYER_LUCK, 1.0)
			# Multiply base chance by luck, ensure it doesn't exceed 100% or go below 0%
			final_drop_chance = clamp(base_qi_drop_chance * player_luck, 0.0, 1.0)
		else:
			printerr("Enemy: Could not get valid player or luck stat for drop calculation.")
	# --- End Calculation ---

	# --- Check Drop Chance ---
	if enemy_data.qi_orb_scene != null and randf() < final_drop_chance:
		var qi_orb = enemy_data.qi_orb_scene.instantiate()

		if qi_orb.has_method("initialize"):
			qi_orb.initialize(enemy_data.qi_amount)

		# Use call_deferred to avoid issues if the parent is also being freed
		get_parent().call_deferred("add_child", qi_orb)
		qi_orb.global_position = global_position
	# --- End Check ---

	queue_free()

func apply_knockback(direction: Vector2, strength: float) -> void:
	if strength <= 0:
		return
		
	knockback_velocity = direction.normalized() * strength
	velocity = knockback_velocity
	current_state = State.KNOCKED_BACK

func handle_hit(damage: float, knockback_force: float, knockback_direction: Vector2) -> void:
	# Apply damage via the HealthComponent
	if is_instance_valid(health) and health.has_method("take_damage"):
		health.take_damage(damage)
	else:
		printerr(self.name, " has no valid HealthComponent or take_damage method!")

	# Play hit flash
	if animation_player and animation_player.has_animation("hit_flash"):
		animation_player.play("hit_flash")
	else:
		printerr(self.name, " has no valid AnimationPlayer or hit_flash animation!")

	# Play the hit sound using the SoundManager
	SoundManager.play_sound(Enums.SoundEffect.HIT_ENEMY)

	# Apply knockback using the existing method
	apply_knockback(knockback_direction, knockback_force)

	var spawn_position = global_position + Vector2(0, -20)
	DamageNumbers.show_damage_number(damage, spawn_position)
