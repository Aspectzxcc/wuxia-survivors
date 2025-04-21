class_name EnemyData extends Resource

@export var enemy_name: String = "Unnamed Foe" # For identification/debugging
@export var enemy_scene: PackedScene # The scene representing this enemy (visuals, collision, script)

# --- Stats ---
@export var health: float = 10.0
@export var speed: float = 50.0
@export var damage: float = 5.0

@export var knockback_friction: float = 5.0 # Higher value = faster deceleration

# --- Behavior ---
# You could add more complex behavior flags here if needed later (e.g., ranged, charging)
# For now, assume basic homing movement.

# --- Drops ---
@export var qi_orb_scene: PackedScene # Scene for the standard XP drop
@export var qi_amount: int = 1       # Amount of XP this enemy drops

# Could add more drop types (healing, specific items)
