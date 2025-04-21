extends CanvasLayer

# --- Node References ---
@onready var virtual_joystick: Node = $VirtualJoystick
@onready var fps_label: Label = $FPSLabel
@onready var timer_label: Label = $TimerLabel
@onready var kill_count_label: Label = $KillCountLabel
@onready var pause_button: Button = $PauseButton
@onready var level_up_ui: Control = $LevelUpUI
@onready var pause_menu: Control = $PauseMenu

# --- Internal Variables ---
var total_kills: int = 0

# --- Godot Functions ---
func _ready() -> void:
	# --- Virtual Joystick Setup ---
	if not is_instance_valid(virtual_joystick):
		printerr("LevelUI: Virtual Joystick node not found.")
	elif PlatformUtils.is_mobile():
		virtual_joystick.show()
		virtual_joystick.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		virtual_joystick.hide()
		virtual_joystick.process_mode = Node.PROCESS_MODE_DISABLED

	# --- Label Checks ---
	if not is_instance_valid(fps_label):
		printerr("LevelUI: FPS Label node not found.")
	if not is_instance_valid(timer_label):
		printerr("LevelUI: Timer Label node not found.")
	if not is_instance_valid(kill_count_label):
		printerr("LevelUI: Kill Count Label node not found.")
	if not is_instance_valid(level_up_ui):
		printerr("LevelUI: LevelUpUI node not found.")
	if not is_instance_valid(pause_menu):
		printerr("LevelUI: PauseMenu node not found as a child.")

	# --- Pause Button Setup ---
	if not is_instance_valid(pause_button):
		printerr("LevelUI: Pause Button node not found.")
	else:
		# Connect the button press to the pause menu's show function directly
		# Assuming pause_menu is the correct node to handle showing the pause screen
		if is_instance_valid(pause_menu):
			pause_button.pressed.connect(pause_menu.show_menu)
		else:
			printerr("LevelUI: Cannot connect Pause Button, PauseMenu node is invalid.")

	# --- Signal Connections ---
	if GameTimer:
		GameTimer.time_updated.connect(_on_game_timer_updated)
		_on_game_timer_updated(GameTimer.get_formatted_time(), GameTimer.get_elapsed_time()) # Initial set
	else:
		printerr("LevelUI: GameTimer Autoload not found!")

	GlobalEvents.enemy_killed.connect(_on_enemy_killed)

	# --- Initial State ---
	_update_kill_count_label()


func _process(delta: float) -> void:
	# Update FPS Label
	if is_instance_valid(fps_label):
		var current_fps = Performance.get_monitor(Performance.TIME_FPS)
		fps_label.text = "FPS: %d" % current_fps


func _unhandled_input(event: InputEvent) -> void:
	# Handle pause input (Escape key)
	if event.is_action_pressed("ui_cancel"):
		# Only toggle pause if neither the pause menu nor the level up UI is visible
		var pause_menu_visible = is_instance_valid(pause_menu) and pause_menu.visible
		var level_up_visible = is_instance_valid(level_up_ui) and level_up_ui.visible

		if not pause_menu_visible and not level_up_visible:
			pause_menu.show_menu()
			get_viewport().set_input_as_handled()


# --- UI Update Functions ---
func _on_game_timer_updated(formatted_time: String, _elapsed_seconds: float) -> void:
	if is_instance_valid(timer_label):
		timer_label.text = formatted_time

func _on_enemy_killed() -> void:
	total_kills += 1
	_update_kill_count_label()

func _update_kill_count_label() -> void:
	if is_instance_valid(kill_count_label):
		kill_count_label.text = "Kills: %d" % total_kills
