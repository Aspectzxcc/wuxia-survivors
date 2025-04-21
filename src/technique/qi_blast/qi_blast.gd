extends Area2D

# Stats received from the activation strategy
var final_damage: float = 0.0
var final_knockback: float = 0.0
var final_area_size: float = 1.0 # Multiplier
var final_speed: float = 300.0
var final_piercing: int = 1
var direction: Vector2 = Vector2.RIGHT
var final_hitbox_delay: float = 0.0
var final_crit_chance: float = 0.0
var final_crit_multiplier: float = 2.0
var final_effect_chance: float = 0.0

@export var visual_size_multiplier: float = 1.0 # Adjust base visual scale independently

# Internal state
var hits_remaining: int = 1
var lifetime: float = 3.0 # How many seconds the blast lasts

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D # Assuming you have a Sprite2D child named Sprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer # Assuming you have a Timer child named LifetimeTimer

const StatType = Enums.StatType # Use unified StatType

# Helper to get stats from dictionary
func _get_stat(stats: Dictionary, stat_type: StatType, default_value):
	return stats.get(stat_type, default_value)

# Called by the activation strategy
# --- UPDATED SIGNATURE ---
func initialize(calculated_stats: Dictionary, _direction: Vector2):
# --- END UPDATED SIGNATURE ---
	# Get stats from the pre-calculated dictionary
	final_damage = _get_stat(calculated_stats, StatType.TECHNIQUE_DAMAGE, 5.0)
	final_knockback = _get_stat(calculated_stats, StatType.TECHNIQUE_KNOCKBACK, 50.0)
	final_speed = _get_stat(calculated_stats, StatType.TECHNIQUE_SPEED, 300.0)
	final_area_size = max(0.01, _get_stat(calculated_stats, StatType.TECHNIQUE_AREA_SIZE, 1.0)) # Ensure positive
	final_piercing = _get_stat(calculated_stats, StatType.TECHNIQUE_PIERCING, 1)
	final_hitbox_delay = max(0.0, _get_stat(calculated_stats, StatType.TECHNIQUE_HITBOX_DELAY, 0.0))
	final_crit_chance = clampf(_get_stat(calculated_stats, StatType.TECHNIQUE_CRIT_CHANCE, 0.0), 0.0, 1.0)
	final_crit_multiplier = max(1.0, _get_stat(calculated_stats, StatType.TECHNIQUE_CRIT_MULTIPLIER, 2.0))
	final_effect_chance = clampf(_get_stat(calculated_stats, StatType.TECHNIQUE_EFFECT_CHANCE, 0.0), 0.0, 1.0)
	# Note: Duration/Lifetime is handled by the timer in this scene, not passed directly

	direction = _direction.normalized() # Ensure direction is normalized
	hits_remaining = final_piercing

func _ready():
	# Ensure connections are made (can also be done in the editor)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not lifetime_timer.is_connected("timeout", Callable(self, "queue_free")):
		lifetime_timer.timeout.connect(queue_free)

	# Apply area size scaling
	var area_scale_factor = sqrt(final_area_size)

	if is_instance_valid(sprite):
		var final_visual_scale = area_scale_factor * visual_size_multiplier
		sprite.scale = Vector2(final_visual_scale, final_visual_scale)
	else:
		printerr(self.name, ": Sprite2D node not found or invalid!")

	if is_instance_valid(collision_shape):
		collision_shape.scale = Vector2(area_scale_factor, area_scale_factor)
		collision_shape.disabled = true
		if final_hitbox_delay > 0.0:
			var delay_timer = get_tree().create_timer(final_hitbox_delay)
			if is_instance_valid(self):
				await delay_timer.timeout
				if is_instance_valid(self) and is_instance_valid(collision_shape):
					collision_shape.disabled = false
		else:
			collision_shape.disabled = false
	else:
		printerr(self.name, ": CollisionShape2D node not found or invalid!")
		queue_free() # Cannot function without collision
		return

	rotation = direction.angle()

	if is_instance_valid(lifetime_timer):
		lifetime_timer.wait_time = lifetime
		lifetime_timer.start()
	else:
		printerr(self.name, ": LifetimeTimer node not found or invalid!")


func _physics_process(delta: float):
	global_position += direction * final_speed * delta


func _on_body_entered(body: Node2D):
	if hits_remaining <= 0:
		return
	if body is Enemy:
		var enemy = body as Enemy

		if enemy.has_method("handle_hit"):
			var knockback_direction = (enemy.global_position - global_position).normalized()
			if knockback_direction == Vector2.ZERO:
				knockback_direction = direction

			# --- IMPLEMENT CRIT ---
			var damage_to_deal = final_damage
			if randf() < final_crit_chance:
				damage_to_deal *= final_crit_multiplier
				print("Qi Blast: CRITICAL HIT!") # Add visual feedback later
			# --- END CRIT ---

			# --- IMPLEMENT EFFECT CHANCE (Placeholder) ---
			if randf() < final_effect_chance:
				if enemy.has_method("apply_status_effect"):
					# Replace "BURN" and duration/potency with actual effect logic
					enemy.apply_status_effect("BURN", 3.0)
					print("Qi Blast: Applied status effect!")
			# --- END EFFECT CHANCE ---

			# Call handle_hit with potentially modified damage
			enemy.handle_hit(damage_to_deal, final_knockback, knockback_direction)

			hits_remaining -= 1
			if hits_remaining <= 0:
				queue_free()
