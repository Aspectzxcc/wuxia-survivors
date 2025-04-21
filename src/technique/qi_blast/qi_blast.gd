extends Area2D

# Stats received from the activation strategy
var final_damage: float = 0.0
var final_knockback: float = 0.0
var final_area_size: float = 1.0 # Multiplier
var final_speed: float = 300.0
var final_piercing: int = 1
var direction: Vector2 = Vector2.RIGHT
# --- NEW STATS ---
var final_hitbox_delay: float = 0.0
var final_crit_chance: float = 0.0
var final_crit_multiplier: float = 2.0
var final_effect_chance: float = 0.0
# --- END NEW STATS ---


@export var visual_size_multiplier: float = 1.0 # Adjust base visual scale independently

# Internal state
var hits_remaining: int = 1
var lifetime: float = 3.0 # How many seconds the blast lasts

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D # Assuming you have a Sprite2D child named Sprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer # Assuming you have a Timer child named LifetimeTimer

# Called by the activation strategy
# --- UPDATED SIGNATURE ---
func initialize(
    _damage: float,
    _knockback: float,
    _area_size: float,
    _speed: float,
    _piercing: int,
    _direction: Vector2,
    _hitbox_delay: float,
    _crit_chance: float,
    _crit_multiplier: float,
    _effect_chance: float
):
# --- END UPDATED SIGNATURE ---
    final_damage = _damage
    final_knockback = _knockback
    final_area_size = max(0.01, _area_size) # Ensure area size is positive
    final_speed = _speed
    final_piercing = _piercing
    direction = _direction.normalized() # Ensure direction is normalized
    hits_remaining = final_piercing
    # --- STORE NEW STATS ---
    final_hitbox_delay = max(0.0, _hitbox_delay)
    final_crit_chance = clampf(_crit_chance, 0.0, 1.0) # Ensure 0-1 range
    final_crit_multiplier = max(1.0, _crit_multiplier) # Ensure multiplier is at least 1x
    final_effect_chance = clampf(_effect_chance, 0.0, 1.0) # Ensure 0-1 range
    # --- END STORE NEW STATS ---
    
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
