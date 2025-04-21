extends Area2D

@export var visual_size_multiplier: float = 2.5 # Base visual scale adjustment
@export var base_hitbox_width: float = 50.0 # The width of the collision shape at scale 1.0
@export var base_hitbox_length: float = 100.0 # The length of the collision shape at scale 1.0

# --- Stats received from activation strategy ---
var final_damage: float = 0.0
var final_knockback: float = 0.0
var final_area_size_multiplier: float = 1.0 # The calculated area multiplier
var final_strike_duration: float = 0.15
var final_hitbox_delay: float = 0.0
var final_crit_chance: float = 0.0
var final_crit_multiplier: float = 2.0
var final_effect_chance: float = 0.0
# --- END STATS ---

var bodies_hit_this_sweep: Array = []

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var effect_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var duration_timer: Timer = $DurationTimer

const StatType = Enums.StatType # Use unified StatType

# --- UPDATED SIGNATURE ---
func initialize(calculated_stats: Dictionary):
# --- END UPDATED SIGNATURE ---
    # Get stats from the pre-calculated dictionary
    final_damage = calculated_stats.get(StatType.TECHNIQUE_DAMAGE, 10.0)
    final_knockback = calculated_stats.get(StatType.TECHNIQUE_KNOCKBACK, 100.0)
    final_area_size_multiplier = max(0.01, calculated_stats.get(StatType.TECHNIQUE_AREA_SIZE, 1.0)) # Store multiplier, ensure > 0
    final_strike_duration = calculated_stats.get(StatType.TECHNIQUE_DURATION, 0.5)
    final_hitbox_delay = max(0.0, calculated_stats.get(StatType.TECHNIQUE_HITBOX_DELAY, 0.0))
    final_crit_chance = clampf(calculated_stats.get(StatType.TECHNIQUE_CRIT_CHANCE, 0.0), 0.0, 1.0) # Ensure 0-1 range
    final_crit_multiplier = max(1.0, calculated_stats.get(StatType.TECHNIQUE_CRIT_MULTIPLIER, 2.0)) # Ensure multiplier is at least 1x
    final_effect_chance = clampf(calculated_stats.get(StatType.TECHNIQUE_EFFECT_CHANCE, 0.0), 0.0, 1.0) # Ensure 0-1 range

    # print(self.name, ": Initialized with Damage: ", final_damage, ", Knockback: ", final_knockback, ", AreaSizeMult: ", final_area_size_multiplier, ", Strike Duration: ", final_strike_duration, ", CritChance: ", final_crit_chance)

func _ready():
    if not is_instance_valid(collision_shape):
        printerr(self.name, ": ERROR - CollisionShape not found after ready!")
        queue_free()
        return

    # --- MODIFIED: Calculate final dimensions from area size multiplier ---
    var scale_factor = sqrt(final_area_size_multiplier)

    var final_width = base_hitbox_width * scale_factor
    var final_length = base_hitbox_length * scale_factor

    if collision_shape.shape is RectangleShape2D:
        collision_shape.shape.size = Vector2(final_length, final_width)
    else:
        printerr(self.name, ": CollisionShape is not a RectangleShape2D! Cannot set size.")

    if is_instance_valid(effect_sprite):
        var sprite_scale_x = scale_factor * visual_size_multiplier
        var sprite_scale_y = scale_factor * visual_size_multiplier
        effect_sprite.scale = Vector2(sprite_scale_x, sprite_scale_y)

    duration_timer.wait_time = final_strike_duration
    duration_timer.one_shot = true

    if not duration_timer.is_connected("timeout", Callable(self, "_on_duration_timer_timeout")):
        duration_timer.timeout.connect(_on_duration_timer_timeout)
    if not self.is_connected("body_entered", Callable(self, "_on_body_entered")):
        self.body_entered.connect(_on_body_entered)

    _start_sweep()

func _start_sweep() -> void:
    bodies_hit_this_sweep.clear()
    collision_shape.disabled = true # Start disabled

    # --- IMPLEMENT HITBOX DELAY ---
    if final_hitbox_delay > 0.0:
        var delay_timer = get_tree().create_timer(final_hitbox_delay)
        # Use await safely with a check
        if is_instance_valid(self):
            await delay_timer.timeout
            # Check again after await
            if not is_instance_valid(self):
                return # Node was freed during delay
        else:
            return # Node was freed before delay started
    # --- END HITBOX DELAY ---

    # Enable collision and start animation/timer *after* potential delay
    if is_instance_valid(collision_shape):
        collision_shape.disabled = false
    else:
        printerr(self.name, ": CollisionShape became invalid after hitbox delay!")
        queue_free()
        return

    duration_timer.start()
    if is_instance_valid(effect_sprite):
        effect_sprite.play("default")
        effect_sprite.show()


func _on_body_entered(body: Node2D) -> void:
    if body is Enemy and not body in bodies_hit_this_sweep:
        bodies_hit_this_sweep.append(body)
        var enemy = body as Enemy

        if enemy.has_method("handle_hit"):
            var knockback_direction = (enemy.global_position - global_position).normalized()
            # If directly on top, push away randomly
            if knockback_direction == Vector2.ZERO:
                knockback_direction = Vector2.RIGHT.rotated(randf() * TAU)

            # --- IMPLEMENT CRIT ---
            var damage_to_deal = final_damage
            if randf() < final_crit_chance:
                damage_to_deal *= final_crit_multiplier
                print("Wanderer's Strike: CRITICAL HIT!") # Add visual feedback later
            # --- END CRIT ---

            # --- IMPLEMENT EFFECT CHANCE (Placeholder) ---
            if randf() < final_effect_chance:
                if enemy.has_method("apply_status_effect"):
                    # Replace "SLOW" and duration/potency with actual effect logic
                    enemy.apply_status_effect("SLOW", 1.0)
                    print("Wanderer's Strike: Applied status effect!")
                else:
                    printerr("Wanderer's Strike: Enemy ", enemy.name, " is missing apply_status_effect method.")
            # --- END EFFECT CHANCE ---

            # Call the body's handle_hit method with potentially modified damage
            enemy.handle_hit(damage_to_deal, final_knockback, knockback_direction)

func _on_duration_timer_timeout() -> void:
    collision_shape.disabled = true
    if is_instance_valid(effect_sprite):
        effect_sprite.hide()
    queue_free()
