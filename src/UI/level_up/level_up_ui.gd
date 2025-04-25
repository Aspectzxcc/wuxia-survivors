extends Control

# References to the UpgradeOptionCard buttons (ensure they have the UpgradeOptionCard script attached)
@onready var option_card_1: UpgradeOptionCard = $PanelContainer/VBoxContainer/UpgradeOptionCard
@onready var option_card_2: UpgradeOptionCard = $PanelContainer/VBoxContainer/UpgradeOptionCard2
@onready var option_card_3: UpgradeOptionCard = $PanelContainer/VBoxContainer/UpgradeOptionCard3

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    hide_ui()

    # --- Connect to the NEW signal from each card ---
    option_card_1.upgrade_selected.connect(_on_card_upgrade_selected)
    option_card_2.upgrade_selected.connect(_on_card_upgrade_selected)
    option_card_3.upgrade_selected.connect(_on_card_upgrade_selected)

    GlobalEvents.player_leveled_up.connect(show_ui)

func show_ui(player: Player):
    var generated_options = UpgradeGenerator.generate_upgrade_options(player, 3)

    # Option 1
    var data_1 = generated_options[0] if generated_options.size() > 0 else {} # Use empty dict
    option_card_1.set_option_data(data_1)

    # Option 2
    var data_2 = generated_options[1] if generated_options.size() > 1 else {} # Use empty dict
    option_card_2.set_option_data(data_2)

    # Option 3
    var data_3 = generated_options[2] if generated_options.size() > 2 else {} # Use empty dict
    option_card_3.set_option_data(data_3)

    self.visible = true
    get_tree().paused = true

func hide_ui() -> void:
    hide()
    get_tree().paused = false

# --- New handler function for the signal from the cards ---
func _on_card_upgrade_selected(chosen_option_data: Dictionary):
    if not chosen_option_data.is_empty():
        GlobalEvents.upgrade_selected.emit(chosen_option_data)

    hide_ui()
