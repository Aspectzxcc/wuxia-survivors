extends Area2D
class_name IncenseBurner

var final_damage: float = 5.0
var final_cooldown: float = 1.0 # Time between damage ticks for enemies inside
var final_area_size: float = 1.0
# Add other stats if needed (crit, effect_chance, etc.)

var _enemies_in_area: Dictionary = {} # { EnemyNode: Boolean } - Value just indicates presence
@onready var damage_timer: Timer = $DamageTimer

const StatType = Enums.StatType # Assuming you have this Enum

# Called by the Activation Strategy
func initialize(calculated_stats: Dictionary) -> void:
    # Get stats using the helper method pattern (or directly if preferred)
    final_damage = calculated_stats.get(StatType.TECHNIQUE_DAMAGE, 5.0)
    final_cooldown = calculated_stats.get(StatType.TECHNIQUE_COOLDOWN, 1.0) # Cooldown now means damage tick rate
    final_area_size = calculated_stats.get(StatType.TECHNIQUE_AREA_SIZE, 1.0)
    # Get other stats like crit_chance, crit_multiplier, effect_chance if needed

    # Apply scaling based on area_size
    # Note: Scaling the Area2D also scales child nodes like CollisionShape2D and any visual Sprites/Shaders
    scale = Vector2(final_area_size, final_area_size)
    

func _ready() -> void:
    body_entered.connect(_on_body_entered)

    # Ensure the timer from the scene exists before connecting
    if not is_instance_valid(damage_timer):
        printerr("IncenseBurner: DamageTimer node not found in scene!")
        return

    # Connect the timeout signal from the scene's timer
    if not damage_timer.is_connected("timeout", Callable(self, "_on_damage_timer_timeout")):
         damage_timer.timeout.connect(_on_damage_timer_timeout)

    _setup_damage_timer()

func _setup_damage_timer() -> void:
    # This function now correctly uses the @onready damage_timer
    if is_instance_valid(damage_timer):
        if final_cooldown > 0:
            damage_timer.wait_time = final_cooldown
            # Ensure timer is stopped before starting to reset its interval correctly
            damage_timer.stop()
            damage_timer.start()
        else:
            damage_timer.stop() # Stop timer if cooldown is zero or less

func _on_body_entered(body: Node2D) -> void:
    if body is Enemy and not body in _enemies_in_area:
        # If the enemy enters, start tracking it
        var enemy = body as Enemy
        _enemies_in_area[body] = true

        _apply_damage(enemy)

func _on_damage_timer_timeout() -> void:
    # Iterate through enemies currently marked as inside
    # Use keys().duplicate() to avoid issues if dictionary is modified during iteration (e.g., enemy dies)
    for enemy in _enemies_in_area.keys().duplicate():
        if not is_instance_valid(enemy):
            # Enemy might have been destroyed, remove it
            _enemies_in_area.erase(enemy)
            continue

        # Double-check if the enemy is *still* physically overlapping
        # This prevents dealing damage if it exited exactly between timer ticks
        var is_still_overlapping = false
        for body in get_overlapping_bodies():
            if body == enemy:
                is_still_overlapping = true
                break

        if is_still_overlapping:
            _apply_damage(enemy)
        else:
            # Enemy is no longer overlapping, remove from tracking
            _enemies_in_area.erase(enemy)

func _apply_damage(enemy: Enemy) -> void:
    if enemy.has_method("handle_hit"):
        var knockback_direction = (enemy.global_position - global_position).normalized()
        # If directly on top, push away randomly
        if knockback_direction == Vector2.ZERO:
            knockback_direction = Vector2.RIGHT.rotated(randf() * TAU)

        var final_knockback = 0.0 # incense_burner doesn't apply knockback

        # Call the body's handle_hit method with potentially modified damage
        enemy.handle_hit(final_damage, final_knockback, knockback_direction)