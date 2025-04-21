extends Node2D

@onready var player: Player = $Player
@onready var enemy_spawner: Node = $EnemySpawner

@export var game_timer_debug_start: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    if GameTimer:
         GameTimer.elapsed_time = game_timer_debug_start # DEBUG
    else:
         printerr("TestLevel: GameTimer Autoload not found!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    pass # Add any level-specific process logic here
