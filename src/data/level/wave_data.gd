class_name WaveData
extends Resource

## Time in seconds when this wave definition becomes active.
@export var time_start: float = 0.0

## Minimum number of *any* enemy type desired on screen during this wave.
@export var min_concurrent: int = 10 # Default value, adjust as needed

## How often (in seconds) the spawner *attempts* to spawn enemies for this wave.
@export var spawn_interval: float = 3.0 # Default value, adjust as needed

## How many enemies to spawn at once when the wave is below min_concurrent.
@export var spawn_burst_count: int = 5 # Default value, adjust as needed

## Array containing all enemy types and their rules for this wave.
@export var enemy_entries: Array[EnemyWaveEntry] = []

## Optional: Specific one-shot or repeating map events tied to this wave's start time.
## (We can add a structure for this later if needed, similar to SpawnEventData but separate)
# @export var map_events: Array[MapEventData] = []

# --- Internal state for the spawner ---
var spawn_timer: float = 0.0 # Tracks time until next spawn attempt for this wave
