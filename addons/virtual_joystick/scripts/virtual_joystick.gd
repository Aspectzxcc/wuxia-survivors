@tool
extends Node2D

signal analogic_change(move: Vector2)
signal analogic_just_pressed
signal analogic_released

@export_group("Settings")
@export var normalized: bool = true
@export var zero_at_touch: bool = false:
	set(value):
		zero_at_touch = value
		if Engine.is_editor_hint(): return # Don't run visibility logic in editor
		if zero_at_touch and is_inside_tree():
			hide() # Start hidden if zero_at_touch is true
		elif is_inside_tree():
			show() # Ensure visible otherwise

@export_group("Sprites")
@export var border: Texture2D:
	set(value):
		border = value
		_draw()
		
@export var stick: Texture2D:
	set(value):
		stick = value
		_draw()

@export var stick_pressed: Texture2D

var joystick = Sprite2D.new()
var touch = TouchScreenButton.new()
var radius := Vector2(32, 32)
var boundary := 64
var ongoing_drag := -1
var return_accel := 20
var threshold := 10
var is_pressed = false
var default_global_position: Vector2 # Store initial position

func _draw() -> void:	
	if get_child_count() == 0:
		add_child(joystick)
		
	if joystick.get_child_count() == 0:
		joystick.add_child(touch)	
		
	joystick.texture = border if is_instance_valid(border) else preload("res://addons/virtual_joystick/sprites/joystick.png")
	touch.texture_normal = stick if is_instance_valid(stick) else preload("res://addons/virtual_joystick/sprites/stick.png")


func _ready() -> void:	
	default_global_position = global_position # Store initial position here
	touch.position = -radius
	touch.released.connect(analogic_released.emit)

	if ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"):
		printerr("The Project Setting 'emulate_mouse_from_touch' should be set to False")
	if not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"):
		printerr("The Project Setting 'emulate_touch_from_mouse' should be set to True")
	
	if stick_pressed == null:
		stick_pressed = preload("res://addons/virtual_joystick/sprites/stick_pressed.png")
	
	# Set initial visibility based on zero_at_touch
	if zero_at_touch:
		hide()
	else:
		show()

func _process(delta: float) -> void:
	# Only return joystick if not zero_at_touch and not being dragged
	if not zero_at_touch and ongoing_drag == -1:
		var pos_difference = (Vector2.ZERO - radius) - touch.position
		# Only animate return if not already centered
		if pos_difference.length_squared() > 0.1:
			touch.position += pos_difference * return_accel * delta * 2
		else:
			touch.position = -radius # Snap to center
		

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		# Handle new touch
		if ongoing_drag == -1: # Only process if not already dragging another finger
			if zero_at_touch:
				# --- Zero At Touch Logic ---
				# 1. Move the entire joystick base to the touch location
				global_position = event.position
				# 2. Reset the inner stick sprite to the center of the base
				touch.position = -radius
				# 3. Make the joystick visible
				show()
				# 4. Set state variables
				is_pressed = true
				ongoing_drag = event.get_index()
				# 5. Update texture and emit signal
				touch.texture_normal = stick_pressed
				emit_signal("analogic_just_pressed")
				# 6. Process the initial touch position relative to the new center
				#    (This will calculate the initial offset if the finger isn't exactly centered)
				#    We pass the same event.position which _handle_drag uses
				_handle_drag(event.position)
				# --- End Zero At Touch Logic ---
			else:
				# --- Fixed Position Logic ---
				var event_dist_from_center = (event.position - global_position).length()
				if event_dist_from_center <= boundary * global_scale.x:
					is_pressed = true
					ongoing_drag = event.get_index()
					touch.texture_normal = stick_pressed
					emit_signal("analogic_just_pressed")
					# Process initial position and emit change
					_handle_drag(event.position)
				# --- End Fixed Position Logic ---

	elif event is InputEventScreenDrag:
		# Handle ongoing drag
		if event.get_index() == ongoing_drag:
			# Ensure visibility if it somehow got hidden (belt-and-suspenders)
			if zero_at_touch and not is_visible_in_tree():
				show()
			_handle_drag(event.position)

	elif event is InputEventScreenTouch and not event.is_pressed():
		# Handle touch release
		if event.get_index() == ongoing_drag:
			ongoing_drag = -1
			is_pressed = false
			analogic_change.emit(Vector2.ZERO)
			emit_signal("analogic_released") # Emit released signal
			touch.texture_normal = stick if is_instance_valid(stick) else preload("res://addons/virtual_joystick/sprites/stick.png")

			if zero_at_touch:
				hide() # Hide joystick
				# Reset touch position for next appearance
				touch.position = -radius
				# Optional: Reset global_position back to default if desired,
				# but hiding it is usually enough.
				# global_position = default_global_position
			else:
				# Let _process handle the return animation for fixed joystick
				pass # global_position remains default_global_position


# Helper function to handle position update and signal emission during drag
func _handle_drag(event_position: Vector2) -> void:
	# Calculate where the stick sprite *should* be globally based on finger position
	var target_stick_global_pos = event_position - radius * global_scale
	# Convert that global position to the local position relative to the joystick base
	touch.global_position = target_stick_global_pos

	# Clamp touch position (relative to base) within boundary
	var button_pos = get_button_pos() # This is touch.position + radius
	if button_pos.length() > boundary:
		# Calculate the clamped position relative to the base center
		var clamped_relative_pos = button_pos.normalized() * boundary
		# Set the touch sprite's position relative to the base
		touch.position = clamped_relative_pos - radius

	# Emit the value
	var value = get_value()
	if not normalized:
		# Use the potentially clamped position's length for magnitude scaling
		value *= min(get_button_pos().length() / boundary, 1.0)
	analogic_change.emit(value)

func get_button_pos() -> Vector2:
	return touch.position + radius
	
func get_value() -> Vector2:
	if get_button_pos().length() > threshold:
		return get_button_pos().normalized()
		
	return Vector2.ZERO

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			# When the game pauses (and this node is pausable), reset the joystick state.
			# This handles the case where the pause happens mid-drag or touch.
			if ongoing_drag != -1 or is_pressed:
				reset_state()
		# NOTIFICATION_UNPAUSED:
			# Usually no action needed here, reset on pause is sufficient.
			# pass

# Make sure the reset_state function exists and works correctly
# (Should be present from previous attempts)
func reset_state() -> void:
	if ongoing_drag != -1 or is_pressed: # Only reset if it was actually active
		ongoing_drag = -1
		is_pressed = false
		analogic_change.emit(Vector2.ZERO) # Crucial: Emit zero vector
		# Don't emit analogic_released here, as the touch didn't technically release normally

		# Reset visual state
		touch.texture_normal = stick if is_instance_valid(stick) else preload("res://addons/virtual_joystick/sprites/stick.png")
		touch.position = -radius

		if zero_at_touch:
			# If it's zero_at_touch, hide it on reset
			hide()
		# else: # For fixed joystick, just reset input state, don't hide/move


