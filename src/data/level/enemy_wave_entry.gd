class_name EnemyWaveEntry
extends Resource

## The EnemyData resource for the enemy type.
@export var enemy_data: EnemyData

## Maximum number of this specific enemy type allowed on screen. 0 = no limit.
# @export var max_concurrent: int = 0

## How many to spawn at once when below min_concurrent.
# @export var spawn_burst_count: int = 1

## Chance (0.0 to 1.0) for this specific enemy type's spawn attempt to succeed (if interval met).
## Luck can modify this. 1.0 = guaranteed attempt if interval met.
@export var spawn_chance: float = 1.0

## If true, this enemy ignores the global enemy limit. (e.g., Bosses)
@export var bypass_global_limit: bool = false

# --- Internal state for the spawner ---
