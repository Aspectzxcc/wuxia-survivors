extends Control

const MAIN_MENU_PATH = "res://src/UI/main_menu/main_menu.tscn"

@onready var main_menu_button: Button = $VBoxContainer/MainMenuButton

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED # Ensure UI works when paused
    hide() # Start hidden
    if is_instance_valid(main_menu_button):
        main_menu_button.pressed.connect(_on_main_menu_button_pressed)
    else:
        printerr("GameOverUI: MainMenuButton not found!")
        
    # Connect to the global player death signal
    if GlobalEvents.player_died.is_connected(_on_player_died):
        printerr("GameOverUI: Already connected to GlobalEvents.player_died?")
    else:
        GlobalEvents.player_died.connect(_on_player_died)

func show_ui() -> void:
    show()
    get_tree().paused = true # Pause the game

func _on_main_menu_button_pressed() -> void:
    # Unpause before changing scene to avoid issues
    get_tree().paused = false 
    
    # Reset game timer if it exists
    if GameTimer:
        GameTimer.reset_timer()
        
    if ResourceLoader.exists(MAIN_MENU_PATH):
        get_tree().change_scene_to_file(MAIN_MENU_PATH)
    else:
        printerr("GameOverUI: Cannot change scene. Main menu not found at: ", MAIN_MENU_PATH)
        # Optionally, unpause here too if scene change fails
        # get_tree().paused = false 

# Function called when the global player_died signal is emitted
func _on_player_died() -> void:
    print("GameOverUI: Received GlobalEvents.player_died signal.")
    show_ui()
