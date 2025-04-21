extends Control

const GAME_SCENE_PATH = "res://src/levels/test_level/test_level.tscn"

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	if is_instance_valid(start_button):
		start_button.pressed.connect(_on_start_button_pressed)
	else:
		printerr("Main Menu: Start Button not found at path $VBoxContainer/StartButton")

	if is_instance_valid(options_button):
		options_button.pressed.connect(_on_options_button_pressed)
	else:
		printerr("Main Menu: Options Button not found at path $VBoxContainer/OptionsButton")

	if is_instance_valid(quit_button):
		quit_button.pressed.connect(_on_quit_button_pressed)
	else:
		printerr("Main Menu: Quit Button not found at path $VBoxContainer/QuitButton")

func _on_start_button_pressed() -> void:
	if GameTimer:
		GameTimer.reset_timer()
	else:
		printerr("MainMenu: GameTimer not found before scene change!")

	if ResourceLoader.exists(GAME_SCENE_PATH):
		get_tree().change_scene_to_file(GAME_SCENE_PATH)
	else:
		printerr("Main Menu: Cannot change scene. Game scene not found at: ", GAME_SCENE_PATH)

func _on_options_button_pressed() -> void:
	print("Options button pressed - Not implemented yet")

func _on_quit_button_pressed() -> void:
	print("Quit button pressed")
	get_tree().quit()
