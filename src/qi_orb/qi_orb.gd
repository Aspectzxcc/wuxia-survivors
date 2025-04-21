extends Area2D

const State = Enums.QiOrbState
var current_state: State = State.IDLE

@export var max_speed: float = 300.0
@export var initial_kick_speed: float = 200.0
@export var initial_kick_duration: float = 0.2

var current_velocity: Vector2 = Vector2.ZERO
var qi_value: int = 1

var is_doing_initial_kick: bool = false
var initial_kick_timer: float = 0.0

func initialize(value: int):
	qi_value = value
	current_state = State.IDLE
	is_doing_initial_kick = false

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _on_area_entered(area: Area2D):
	if area.is_in_group("player_magnet") and current_state == State.IDLE:
		current_state = State.ATTRACTED
		is_doing_initial_kick = true
		initial_kick_timer = 0.0

func _on_body_entered(body: Node2D):
	if body.has_method("collect_qi"):
		body.collect_qi(qi_value)
		queue_free()

func _process(delta: float) -> void:
	match current_state:
		State.IDLE:
			current_velocity = Vector2.ZERO

		State.ATTRACTED:
			var player_pos: Vector2 = global_position
			if PlayerTracker != null and PlayerTracker.has_method("get_tracked_player_position"):
				player_pos = PlayerTracker.get_tracked_player_position()
			else:
				print("Warning: PlayerTracker not available in QiOrb._process")

			if is_doing_initial_kick:
				initial_kick_timer += delta
				if initial_kick_timer < initial_kick_duration:
					var direction_away_from_player = (global_position - player_pos)
					
					if direction_away_from_player.length_squared() > 0.01:
						direction_away_from_player = direction_away_from_player.normalized()
					else:
						direction_away_from_player = Vector2.RIGHT.rotated(randf() * TAU)

					current_velocity = direction_away_from_player * initial_kick_speed
				else:
					is_doing_initial_kick = false

			if not is_doing_initial_kick:
				var vector_to_player: Vector2 = player_pos - global_position
				if vector_to_player.length_squared() > 0.01:
					var direction_to_player: Vector2 = vector_to_player.normalized()
					current_velocity = direction_to_player * max_speed
				else:
					current_velocity = Vector2.ZERO

	global_position += current_velocity * delta
