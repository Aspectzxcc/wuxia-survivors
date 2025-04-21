class_name Health extends Node

signal died()
signal health_updated(current_health: float, max_health: float)

@export var max_health: float = 100.0 : set = set_max_health

var current_health: float

func _ready() -> void:
	current_health = max_health
	health_updated.emit(current_health, max_health) 

func take_damage(amount: float) -> void:
	if amount <= 0:
		return
	if current_health <= 0:
		return
		
	current_health -= amount
	current_health = max(current_health, 0.0)

	health_updated.emit(current_health, max_health)

	if current_health == 0.0:
		died.emit()

func heal(amount: float) -> void:
	if amount <= 0:
		return
	if current_health <= 0:
		return
		
	current_health += amount
	current_health = min(current_health, max_health)
	
	health_updated.emit(current_health, max_health)

func get_current_health() -> float:
	return current_health

func get_max_health() -> float:
	return max_health

func set_current_health(value: float) -> void:
	if value < 0:
		printerr("Current health must be non-negative!")
		return
		
	current_health = value
	current_health = min(current_health, max_health)
	if is_node_ready():
		health_updated.emit(current_health, max_health)
	
func set_max_health(value: float) -> void:
	if value <= 0:
		printerr("Max health must be positive!")
		return
		
	max_health = value
	current_health = min(current_health, max_health)
	if is_node_ready():
		health_updated.emit(current_health, max_health)
