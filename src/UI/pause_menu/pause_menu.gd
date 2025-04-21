# filepath: c:\Users\pc\Desktop\godot\wuxia-survivors\src\UI\pause_menu\pause_menu.gd
extends Control

const MAIN_MENU_PATH = "res://src/UI/main_menu/main_menu.tscn"

@onready var resume_button: Button = $CenterContainer/VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $CenterContainer/VBoxContainer/MainMenuButton

func _ready() -> void:
    hide() # Start hidden
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED # Ensure it runs while paused

    if is_instance_valid(resume_button):
        resume_button.pressed.connect(hide_menu) # Resume just hides the menu and unpauses
    else:
        printerr("PauseMenu: ResumeButton not found!")

    if is_instance_valid(main_menu_button):
        main_menu_button.pressed.connect(_on_main_menu_button_pressed)
    else:
        printerr("PauseMenu: MainMenuButton not found!")

func _unhandled_input(event: InputEvent) -> void:
    # Also allow resuming with the pause key (Escape)
    if visible and event.is_action_pressed("ui_cancel"):
        hide_menu()
        get_viewport().set_input_as_handled() # Prevent game from processing Escape too

func show_menu() -> void:
    show()
    get_tree().paused = true

func hide_menu() -> void:
    hide()
    get_tree().paused = false

func _on_main_menu_button_pressed() -> void:
    # Ensure game is unpaused before changing scene
    get_tree().paused = false

    # Reset game timer if it exists
    if GameTimer:
        GameTimer.reset_timer()

    if ResourceLoader.exists(MAIN_MENU_PATH):
        get_tree().change_scene_to_file(MAIN_MENU_PATH)
    else:
        printerr("PauseMenu: Cannot change scene. Main menu not found at: ", MAIN_MENU_PATH)