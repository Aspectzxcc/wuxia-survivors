extends Area2D

@export var visual_size_multiplier: float = 1.0 # Base visual scale adjustment
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

    var final_width = base_hitbox_width * final_area_size_multiplier
    var final_length = base_hitbox_length * final_area_size_multiplier

    if collision_shape.shape is RectangleShape2D:
        collision_shape.shape.size = Vector2(final_length, final_width)
    else:
        printerr(self.name, ": CollisionShape is not a RectangleShape2D! Cannot set size.")

    if is_instance_valid(effect_sprite):
        # --- Non-Uniform Scaling based on Hitbox ---
        # This scales the sprite non-uniformly to match the final hitbox dimensions,
        # adjusted by visual_size_multiplier. It will stretch/squash the texture.

        # 1. Get the sprite's base texture size (size at scale 1,1)
        #    Assumes animation "default" and frame 0 exist. Change if needed.
        var frame_texture = effect_sprite.sprite_frames.get_frame_texture("default", 0)
        if frame_texture:
            var base_sprite_size = frame_texture.get_size()
            if base_sprite_size.x > 0 and base_sprite_size.y > 0: # Avoid division by zero
                # 2. Calculate the target visual dimensions based on the hitbox
                #    Assuming sprite's X maps to hitbox length, Y maps to hitbox width.
                var target_visual_length = final_length * visual_size_multiplier
                var target_visual_width = final_width * visual_size_multiplier

                # 3. Calculate the required scale factors independently
                var required_scale_x = target_visual_length / base_sprite_size.x
                var required_scale_y = target_visual_width / base_sprite_size.y

                effect_sprite.scale = Vector2(required_scale_x, required_scale_y)
            else:
                printerr(self.name, ": Base sprite size is zero, cannot calculate non-uniform scale. Falling back.")
                # Fallback to previous uniform scaling as a safety measure
                var uniform_scale = final_area_size_multiplier * visual_size_multiplier
                effect_sprite.scale = Vector2(uniform_scale, uniform_scale)
        else:
            printerr(self.name, ": Could not get frame texture 'default', frame 0 for scaling. Falling back.")
            # Fallback to previous uniform scaling as a safety measure
            var uniform_scale = final_area_size_multiplier * visual_size_multiplier
            effect_sprite.scale = Vector2(uniform_scale, uniform_scale)
        # --- End Non-Uniform Scaling ---

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
