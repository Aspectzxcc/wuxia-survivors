extends Node

# --- Configuration ---
@export var level_spawn_sequence: LevelSpawnSequence
@export var spawn_offset_distance: float = 50.0
@export	var min_spawn_radius: float = 700.0
@export var max_spawn_radius: float = 900.0
@export var enemy_container: Node = null
@export var global_enemy_limit: int = 300

# --- Internal Variables ---
var current_wave_index: int = -1
var active_wave: WaveData = null
var current_enemy_counts: Dictionary = {}
var total_enemy_count: int = 0

# --- Godot Functions ---
func _ready():
	if level_spawn_sequence == null:
		printerr("EnemySpawner: No LevelSpawnSequence assigned!")
		set_process(false)
		return
	if level_spawn_sequence.waves.is_empty():
		printerr("EnemySpawner: LevelSpawnSequence has no waves defined!")
		set_process(false)
		return

	if enemy_container == null:
		enemy_container = get_tree().get_node_or_null("Enemies")
		if enemy_container == null:
			printerr("EnemySpawner: No enemy container node assigned or found! Trying parent.")
			enemy_container = get_parent()
		if enemy_container == null:
			printerr("EnemySpawner: Could not find a suitable enemy container!")
			set_process(false)
			return

	level_spawn_sequence.waves.sort_custom(func(a, b): return a.time_start < b.time_start)

	for wave in level_spawn_sequence.waves:
		for entry in wave.enemy_entries:
			if entry.enemy_data:
				if not current_enemy_counts.has(entry.enemy_data.resource_path):
					current_enemy_counts[entry.enemy_data.resource_path] = 0

	_check_for_wave_change()


func _process(delta: float):
	if not PlayerTracker.is_player_valid:
		return

	_check_for_wave_change()

	if active_wave != null:
		_process_active_wave(delta)


# --- Wave and Spawning Logic ---

func _check_for_wave_change():
	var next_wave_index = current_wave_index + 1
	if next_wave_index < level_spawn_sequence.waves.size():
		var next_wave = level_spawn_sequence.waves[next_wave_index]
		if GameTimer.get_elapsed_time() >= next_wave.time_start:
			_activate_wave(next_wave_index)


func _activate_wave(wave_index: int):
	if wave_index < 0 or wave_index >= level_spawn_sequence.waves.size():
		printerr("Tried to activate invalid wave index: ", wave_index)
		return

	current_wave_index = wave_index
	active_wave = level_spawn_sequence.waves[current_wave_index]
	active_wave._spawn_timer = 0.0
	print("Activating Wave ", current_wave_index, " at time ", GameTimer.get_formatted_time())


func _process_active_wave(delta: float):
	if not is_instance_valid(active_wave):
		printerr("Active wave became invalid during processing.")
		return

	active_wave._spawn_timer += delta

	if active_wave._spawn_timer >= active_wave.spawn_interval:
		active_wave._spawn_timer -= active_wave.spawn_interval

		active_wave.enemy_entries.shuffle()

		for entry in active_wave.enemy_entries:
			if not is_instance_valid(entry) or not is_instance_valid(entry.enemy_data):
				printerr("Skipping invalid EnemyWaveEntry in active wave.")
				continue
			_attempt_spawn_for_entry(entry, active_wave)


func _attempt_spawn_for_entry(entry: EnemyWaveEntry, wave: WaveData):
	var base_chance = entry.spawn_chance
	if base_chance < 1.0:
		var player_luck = 1.0
		var chance_with_luck = base_chance / player_luck
		if randf() > chance_with_luck:
			return

	if not entry.bypass_global_limit and total_enemy_count >= global_enemy_limit:
		return

	var num_to_spawn = 0
	# Check against the wave's min_concurrent now
	if _are_wave_quotas_met(wave):
		num_to_spawn = 1 # Spawn one if quotas are met
	else:
		# Otherwise, spawn a burst
		num_to_spawn = wave.spawn_burst_count

	if not entry.bypass_global_limit:
		var global_headroom = max(0, global_enemy_limit - total_enemy_count)
		num_to_spawn = min(num_to_spawn, global_headroom)

	for i in range(num_to_spawn):
		if not entry.bypass_global_limit and total_enemy_count >= global_enemy_limit:
			break
		_spawn_single_enemy(entry.enemy_data)


func _are_wave_quotas_met(wave: WaveData) -> bool:
	if wave == null: return true

	var wave_total_count = 0
	for check_entry in wave.enemy_entries:
		if is_instance_valid(check_entry) and is_instance_valid(check_entry.enemy_data):
			var check_path = check_entry.enemy_data.resource_path
			wave_total_count += current_enemy_counts.get(check_path, 0)

	if wave_total_count < wave.min_concurrent:
		return false

	return true


func _spawn_single_enemy(enemy_data: EnemyData):
	if not is_instance_valid(enemy_data) or enemy_data.enemy_scene == null:
		printerr("EnemySpawner: EnemyData invalid or has no PackedScene assigned!")
		return

	var spawn_position = _calculate_spawn_position()
	if spawn_position == Vector2.INF:
		printerr("EnemySpawner: Could not determine valid spawn position.")
		return

	var enemy_instance = enemy_data.enemy_scene.instantiate()

	if enemy_instance.has_method("initialize"):
		enemy_instance.initialize(enemy_data)
		enemy_instance.tree_exiting.connect(_on_enemy_destroyed.bind(enemy_data.resource_path), CONNECT_ONE_SHOT)
		current_enemy_counts[enemy_data.resource_path] += 1
		total_enemy_count += 1
	else:
		printerr("ERROR: Spawned enemy scene ", enemy_data.enemy_scene.resource_path, " is missing the initialize() function!")
		enemy_instance.queue_free()
		return

	enemy_instance.global_position = spawn_position
	enemy_container.add_child(enemy_instance)


func _calculate_spawn_position() -> Vector2:
	if not PlayerTracker.is_player_valid:
		printerr("EnemySpawner: Player not valid, cannot determine spawn position.")
		return Vector2.INF

	var player_pos = PlayerTracker.get_tracked_player_position()

	var random_angle = randf() * TAU
	var random_distance = randf_range(min_spawn_radius, max_spawn_radius)

	var spawn_position = player_pos + Vector2.RIGHT.rotated(random_angle) * random_distance

	return spawn_position


func _on_enemy_destroyed(enemy_resource_path: String):
	if current_enemy_counts.has(enemy_resource_path):
		current_enemy_counts[enemy_resource_path] = max(0, current_enemy_counts[enemy_resource_path] - 1)
	total_enemy_count = max(0, total_enemy_count - 1)
