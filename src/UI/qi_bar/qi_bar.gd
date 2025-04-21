extends ProgressBar

@onready var level_label: Label = $LevelLabel

func _ready() -> void:
	# Connect to global signals to receive updates from the player
	GlobalEvents.player_qi_updated.connect(update_qi)

	value = 0
	max_value = 1 # Avoid division by zero initially

func update_qi(current_qi: int, next_level_qi: int, current_level: int) -> void:
	if next_level_qi > 0:
		max_value = next_level_qi
		value = current_qi
	else:
		# Handle edge case where next_level_qi might be 0 (e.g., max level)
		max_value = 1
		value = 1 # Show as full


	level_label.text = "Lvl%d" % current_level
