# PlayerTracker.gd
extends Node

# Static variable to hold the player's position
# Using static typing helps prevent errors
var player_position: Vector2 = Vector2.ZERO 

# Optional: Store a reference to the player node itself
var player_node: Node2D = null 

# Optional: Flag to know if the player is currently registered and valid
var is_player_valid: bool = false 

# Function for the Player to call to register itself
func register_player(player: Node2D) -> void:
	player_node = player
	is_player_valid = true
	
	# Connect to the player's tree_exiting signal to know when it's gone
	if player and not player.is_connected("tree_exiting", Callable(self, "_on_player_exiting")):
		player.tree_exiting.connect(_on_player_exiting)


# Function for the Player to call to update its position
func update_position(new_position: Vector2) -> void:
	player_position = new_position

# Optional: Called when the player node is about to be removed
func _on_player_exiting():
	player_node = null
	is_player_valid = false
	# Optional: Reset position or leave it where it was last seen?
	# player_position = Vector2.ZERO 

# Optional: A safer way for enemies to get the position
func get_tracked_player_position() -> Vector2:
	if is_player_valid:
		return player_position
	else:
		# What should happen if the player isn't valid? 
		# Return zero? Return the last known position? 
		# For basic homing, returning the last known might be okay.
		return player_position # Or Vector2.ZERO

func get_tracked_player_node() -> Player:
	if is_player_valid:
		return player_node
	else:
		return null # Or handle as needed