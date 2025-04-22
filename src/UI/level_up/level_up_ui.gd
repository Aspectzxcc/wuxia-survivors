extends Control

# References to the UpgradeOptionCard buttons
@onready var option_card_1: Button = $PanelContainer/VBoxContainer/UpgradeOptionCard
@onready var option_card_2: Button = $PanelContainer/VBoxContainer/UpgradeOptionCard2
@onready var option_card_3: Button = $PanelContainer/VBoxContainer/UpgradeOptionCard3

# References to labels within UpgradeOptionCard 1
@onready var name_label_1: Label = $PanelContainer/VBoxContainer/UpgradeOptionCard/HBoxContainer/VBoxContainer/NameLabel
@onready var description_label_1: Label = $PanelContainer/VBoxContainer/UpgradeOptionCard/HBoxContainer/VBoxContainer/DescriptionLabel
# Add @onready var icon_1: TextureRect = $PanelContainer/VBoxContainer/UpgradeOptionCard/HBoxContainer/TechniqueIcon if needed
# Add @onready var new_label_1: Label = $PanelContainer/VBoxContainer/UpgradeOptionCard/HBoxContainer/NewLabel if needed

# References to labels within UpgradeOptionCard 2
@onready var name_label_2: Label = $PanelContainer/VBoxContainer/UpgradeOptionCard2/HBoxContainer/VBoxContainer/NameLabel
@onready var description_label_2: Label = $PanelContainer/VBoxContainer/UpgradeOptionCard2/HBoxContainer/VBoxContainer/DescriptionLabel
# Add @onready var icon_2: TextureRect = $PanelContainer/VBoxContainer/UpgradeOptionCard2/HBoxContainer/TechniqueIcon if needed
# Add @onready var new_label_2: Label = $PanelContainer/VBoxContainer/UpgradeOptionCard2/HBoxContainer/NewLabel if needed

# References to labels within UpgradeOptionCard 3
@onready var name_label_3: Label = $PanelContainer/VBoxContainer/UpgradeOptionCard3/HBoxContainer/VBoxContainer/NameLabel
@onready var description_label_3: Label = $PanelContainer/VBoxContainer/UpgradeOptionCard3/HBoxContainer/VBoxContainer/DescriptionLabel
# Add @onready var icon_3: TextureRect = $PanelContainer/VBoxContainer/UpgradeOptionCard3/HBoxContainer/TechniqueIcon if needed
# Add @onready var new_label_3: Label = $PanelContainer/VBoxContainer/UpgradeOptionCard3/HBoxContainer/NewLabel if needed

var options_data: Array[Dictionary] = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    hide_ui()

    # Connect signals from the UpgradeOptionCard buttons
    option_card_1.pressed.connect(_on_option_button_pressed.bind(0))
    option_card_2.pressed.connect(_on_option_button_pressed.bind(1))
    option_card_3.pressed.connect(_on_option_button_pressed.bind(2))

    GlobalEvents.player_leveled_up.connect(show_ui)

func show_ui(player: Player):
    options_data = UpgradeGenerator.generate_upgrade_options(player, 3)

    # Option 1
    if options_data.size() > 0 and options_data[0] != null:
        name_label_1.text = options_data[0].get("name", "Option 1 Error")
        description_label_1.text = options_data[0].get("description", "")
        # Set icon texture if available: icon_1.texture = options_data[0].get("icon")
        # Set new label visibility/text if needed: new_label_1.visible = options_data[0].get("is_new", false)
        option_card_1.disabled = false
        option_card_1.visible = true
    else:
        option_card_1.disabled = true
        option_card_1.visible = false # Hide card if no data

    # Option 2
    if options_data.size() > 1 and options_data[1] != null:
        name_label_2.text = options_data[1].get("name", "Option 2 Error")
        description_label_2.text = options_data[1].get("description", "")
        # Set icon texture if available: icon_2.texture = options_data[1].get("icon")
        # Set new label visibility/text if needed: new_label_2.visible = options_data[1].get("is_new", false)
        option_card_2.disabled = false
        option_card_2.visible = true
    else:
        option_card_2.disabled = true
        option_card_2.visible = false # Hide card if no data

    # Option 3
    if options_data.size() > 2 and options_data[2] != null:
        name_label_3.text = options_data[2].get("name", "Option 3 Error")
        description_label_3.text = options_data[2].get("description", "")
        # Set icon texture if available: icon_3.texture = options_data[2].get("icon")
        # Set new label visibility/text if needed: new_label_3.visible = options_data[2].get("is_new", false)
        option_card_3.disabled = false
        option_card_3.visible = true
    else:
        option_card_3.disabled = true
        option_card_3.visible = false # Hide card if no data

    self.visible = true
    get_tree().paused = true

func hide_ui() -> void:
    hide()
    get_tree().paused = false

func _on_option_button_pressed(option_index: int):
    if option_index >= 0 and option_index < options_data.size() and options_data[option_index] != null:
        var chosen_option_data = options_data[option_index]

        GlobalEvents.upgrade_selected.emit(chosen_option_data)

        hide_ui()
    else:
        print("Error: Invalid option index selected or data missing.")
        hide_ui()
