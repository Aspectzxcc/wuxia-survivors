extends Button
class_name UpgradeOptionCard

signal upgrade_selected(option_data: Dictionary)

# Adjust node paths if your scene structure is different
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var description_label: Label = $HBoxContainer/VBoxContainer/DescriptionLabel
@onready var technique_icon: TextureRect = $HBoxContainer/TechniqueIcon# Assuming this node exists
@onready var new_label: Label = $HBoxContainer/NewLabel # Assuming this node exists

var option_data: Dictionary = {}

func _ready():
    self.pressed.connect(_on_pressed)

# Call this function to populate the card's UI elements
func set_option_data(data: Dictionary):
    option_data = data

    # Populate UI elements from the data dictionary
    name_label.text = data.get("name", "Error: Name Missing")
    description_label.text = data.get("description", "")

    if is_instance_valid(technique_icon):
        technique_icon.texture = data.get("icon")

    if is_instance_valid(new_label):
        new_label.visible = true

    self.disabled = false
    self.visible = true

func get_option_data() -> Dictionary:
    return option_data

func _on_pressed():
    # Check if the data is valid before emitting
    if not option_data.is_empty():
        # Emit the custom signal, passing the data associated with this card
        upgrade_selected.emit(option_data)
    else:
        print("UpgradeOptionCard: Pressed with empty data.")