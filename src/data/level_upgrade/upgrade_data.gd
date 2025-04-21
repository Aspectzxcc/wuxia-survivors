class_name UpgradeData extends Resource

@export var level: int = 2 # The level this upgrade applies AT
@export var description: String = "" # Description shown on level up screen
@export var modifications: Array[StatModifier] # List of stat changes for this level

# Helper to ensure modifications array exists
func get_modifications() -> Array[StatModifier]:
    if modifications == null:
        modifications = []
    return modifications