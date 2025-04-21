extends Node

# --- Configuration ---
const MOVE_AMOUNT = Vector2(0, -50) # How far up it moves (pixels)
const DURATION = 0.7 # How long the animation lasts (seconds)
const SPREAD = 30 # Random horizontal offset range (pixels)
const FONT_SIZE = 40 # Adjust as needed
const CRIT_FONT_SIZE_MULTIPLIER = 1.4 # How much bigger crits are
const REGULAR_COLOR = Color.WHITE
const CRIT_COLOR = Color(1.0, 0.8, 0.2) # Yellowish-orange for crits
const TOP_Z_INDEX = 100 # Ensure this is higher than enemy/player Z-indices

# Optional: Preload a font if there is a specific one
# const DAMAGE_FONT = preload("res://path/to/your/font.ttf")

# Call this function from anywhere to show a damage number
func show_damage_number(damage_amount: float, position: Vector2, is_crit: bool = false) -> void:
    # Get the main scene tree's root node
    var main_scene = get_tree().current_scene
    if not is_instance_valid(main_scene):
        printerr("DamageNumberSpawner: Could not get current scene!")
        return

    # --- Create Nodes Dynamically ---
    var root_node = Node2D.new() # Root node for positioning and tweening
    root_node.z_index = TOP_Z_INDEX # Set Z-index to draw on top
    var label = Label.new()

    # --- Configure Label ---
    label.text = str(int(round(damage_amount)))
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.set_anchors_preset(Control.PRESET_CENTER) # Helps with centering text origin

    # Font settings (adjust as needed)
    label.add_theme_font_size_override("font_size", FONT_SIZE)
    # If using a specific font:
    # if DAMAGE_FONT:
    #     label.add_theme_font_override("font", DAMAGE_FONT)

    # Style based on crit status
    if is_crit:
        label.modulate = CRIT_COLOR
        label.scale = Vector2(1, 1) * CRIT_FONT_SIZE_MULTIPLIER # Scale for size increase
    else:
        label.modulate = REGULAR_COLOR
        label.scale = Vector2(1, 1)

    # --- Assemble and Position ---
    root_node.add_child(label)
    main_scene.add_child(root_node) # Add root to the scene

    # Apply random horizontal spread to the root node's position
    var final_position = position + Vector2(randf_range(-SPREAD / 2.0, SPREAD / 2.0), 0)
    root_node.global_position = final_position

    # --- Create Animation Tween ---
    var tween = create_tween()
    # Make root node invisible initially if fading in (optional)
    # root_node.modulate.a = 0.0
    # tween.tween_property(root_node, "modulate:a", 1.0, 0.1) # Quick fade-in

    tween.set_parallel(true) # Run move and fade simultaneously
    tween.set_trans(Tween.TRANS_QUINT) # Use an easing function for smoother movement
    tween.set_ease(Tween.EASE_OUT)

    # Move upwards (animate the root node)
    tween.tween_property(root_node, "position", root_node.position + MOVE_AMOUNT, DURATION).from_current()

    # Fade out (animate the label's alpha) - start fade slightly later if desired
    tween.tween_property(label, "modulate:a", 0.0, DURATION * 0.8).set_delay(DURATION * 0.2).from(label.modulate.a)

    # Queue free the root node when the tween finishes
    tween.chain().tween_callback(root_node.queue_free)
