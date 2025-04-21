# Represents a single modification to a specific stat.
class_name StatModifier
extends Resource

const StatType = Enums.StatType

@export var stat: StatType              # Use the unified StatType enum
@export var type: Enums.ModifierType    # How to modify (ADD, MULTIPLY, SET)
@export var value: float = 0.0          # The value to use for modification
