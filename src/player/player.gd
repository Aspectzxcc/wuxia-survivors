class_name Player
extends CharacterBody2D

@export var speed: float = 200.0
@export var character_data: CharacterData

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var health: Node = $Health
@onready var health_bar: ProgressBar = $HealthBar
@onready var technique_manager: TechniqueManager = $TechniqueManager
@onready var passive_manager: PassiveManager = $PassiveManager

const StatType = Enums.StatType
const UpgradeType = Enums.UpgradeType

var base_stats: Dictionary = {}
var final_stats: Dictionary = {}

var active_modifiers: Array[StatModifier] = []

var current_qi: int = 0
@export var experience_to_next_level: int = 5
var level: int = 1

var joystick_vector: Vector2 = Vector2.ZERO

signal player_stats_updated

func _ready() -> void:
	PlayerTracker.register_player(self)
	health.health_updated.connect(_on_health_updated)
	health.died.connect(_on_death)
	passive_manager.passives_updated.connect(_on_passives_updated)

	var joystick_nodes = get_tree().get_nodes_in_group("Joystick")
	if not joystick_nodes.is_empty():
		var joystick = joystick_nodes[0]
		if joystick.has_signal("analogic_change"):
			joystick.analogic_change.connect(_on_virtual_joystick_analogic_change)
		else:
			printerr("Player: Found node in 'joystick' group, but it doesn't have the 'analogic_change' signal.")
	else:
		printerr("Player: Could not find any node in the 'joystick' group to connect to.")

	if is_instance_valid(character_data):
		base_stats = {
			StatType.PLAYER_MAX_HEALTH: character_data.max_health,
			StatType.PLAYER_RECOVERY: character_data.recovery,
			StatType.PLAYER_ARMOR: character_data.armor,
			StatType.PLAYER_MOVE_SPEED: character_data.move_speed,
			StatType.PLAYER_QI_GAIN: character_data.qi_gain,
			StatType.PLAYER_LUCK: character_data.luck,
			StatType.PLAYER_GREED: character_data.greed,
			StatType.PLAYER_MAGNET: character_data.magnet,
			StatType.PLAYER_CURSE: character_data.curse,
			StatType.PLAYER_DAMAGE: character_data.damage,
			StatType.PLAYER_AREA_SIZE: character_data.area_size,
			StatType.PLAYER_SPEED: character_data.speed,
			StatType.PLAYER_DURATION: character_data.duration,
			StatType.PLAYER_AMOUNT: character_data.amount,
			StatType.PLAYER_COOLDOWN: character_data.cooldown,
			StatType.PLAYER_REVIVAL: character_data.revival,
			StatType.PLAYER_REROLL: character_data.reroll,
			StatType.PLAYER_SKIP: character_data.skip,
			StatType.PLAYER_BANISH: character_data.banish,
			StatType.PLAYER_CHARM: character_data.charm,
			StatType.PLAYER_DEFANG: character_data.defang,
			StatType.PLAYER_SEAL: character_data.seal,
			StatType.PLAYER_CRIT_CHANCE: character_data.crit_chance,
		}

		if is_instance_valid(character_data.sprite_frames):
			sprite.sprite_frames = character_data.sprite_frames
		else:
			printerr("Player: Missing sprite_frames in CharacterData!")

		if is_instance_valid(technique_manager):
			for technique in character_data.starting_techniques:
				if is_instance_valid(technique) and technique is TechniqueData:
					technique_manager.add_technique(technique)
				else:
					printerr("Player: Invalid technique found in starting_techniques array.")
		elif not is_instance_valid(technique_manager):
			printerr("Player: TechniqueManager node is missing or invalid.")

	else:
		printerr("Player: No CharacterData assigned! Using default empty stats.")

		base_stats = {}

	_recalculate_all_stats()

	health.set_max_health(final_stats.get(StatType.PLAYER_MAX_HEALTH, 100.0))
	health.set_current_health(health.get_max_health())

	GlobalEvents.player_qi_updated.emit(current_qi, experience_to_next_level, level)

func _on_virtual_joystick_analogic_change(move: Vector2) -> void:
	joystick_vector = move

func _physics_process(_delta: float) -> void:
	var keyboard_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var combined_input := keyboard_input + joystick_vector

	var input_direction := combined_input.limit_length(1.0)

	var calculated_speed = speed * final_stats.get(StatType.PLAYER_MOVE_SPEED, 1.0)
	velocity = input_direction * calculated_speed

	if input_direction.x > 0.1:
		sprite.scale.x = 1
	elif input_direction.x < -0.1:
		sprite.scale.x = -1

	move_and_slide()

	PlayerTracker.update_position(global_position)

func collect_qi(value: int) -> void:
	var modified_value = int(ceil(float(value) * final_stats.get(StatType.PLAYER_QI_GAIN, 1.0)))
	current_qi += modified_value
	GlobalEvents.player_qi_updated.emit(current_qi, experience_to_next_level, level)

	while current_qi >= experience_to_next_level:
		var previous_exp_needed = experience_to_next_level

		level += 1
		current_qi -= previous_exp_needed

		experience_to_next_level = StatCalculator.get_xp_for_next_level(level)

		GlobalEvents.player_qi_updated.emit(current_qi, experience_to_next_level, level)
		GlobalEvents.player_leveled_up.emit(self)

func _collect_all_modifiers() -> void:
	active_modifiers.clear()
	if not is_instance_valid(passive_manager):
		printerr("Player: Cannot collect modifiers, PassiveManager is invalid.")
		return

	var current_active_passives: Array[PassiveData] = passive_manager.get_active_passives()
	for passive_data in current_active_passives:
		if not is_instance_valid(passive_data) or not passive_data is PassiveData:
			printerr("Player: Invalid key found in active passives dictionary.")
			continue

		if passive_data.level <= 0:
			continue

		for level_to_check in range(1, passive_data.level + 1):
			var upgrade_data: UpgradeData = passive_data.get_upgrade_for_level(level_to_check)
			if is_instance_valid(upgrade_data) and upgrade_data.has_method("get_modifications"):
				var mods_this_level: Array = upgrade_data.get_modifications()
				if mods_this_level is Array:
					for mod in mods_this_level:
						if mod is StatModifier:
							if StatType.keys()[mod.stat].begins_with("PLAYER_"):
								active_modifiers.append(mod)
				else:
					printerr("Player: PassiveData.get_modifications() did not return an Array for ", passive_data.passive_name, " L", level_to_check)

func _recalculate_all_stats() -> void:
	final_stats.clear()
	for stat_type_int in base_stats:
		var stat_type: StatType = stat_type_int
		if not StatType.keys()[stat_type].begins_with("PLAYER_"):
			printerr("Player: Found non-PLAYER stat key (%s) in base_stats during recalculation. Skipping." % StatType.keys()[stat_type])
			continue
		final_stats[stat_type] = StatCalculator.calculate_player_stat(self, stat_type)

	if is_instance_valid(health):
		health.set_max_health(final_stats.get(StatType.PLAYER_MAX_HEALTH, 100.0))

	_update_magnet_area()

	player_stats_updated.emit()

func get_modifiers_for_stat(target_stat_type: StatType) -> Array[StatModifier]:
	var relevant_mods: Array[StatModifier] = []
	for modifier in active_modifiers:
		if StatType.keys()[modifier.stat].begins_with("PLAYER_") and modifier.stat == target_stat_type:
			relevant_mods.append(modifier)
	return relevant_mods

func _update_magnet_area() -> void:
	var magnet_radius = final_stats.get(StatType.PLAYER_MAGNET, 32.0)
	var magnet_shape = $MagnetArea/CollisionShape2D as CollisionShape2D
	if is_instance_valid(magnet_shape) and magnet_shape.shape is CircleShape2D:
		(magnet_shape.shape as CircleShape2D).radius = magnet_radius
	else:
		printerr("Player: Could not find or update MagnetArea shape.")

func _on_death() -> void:
	print("Player has died!")
	queue_free()

	GlobalEvents.player_died.emit()

func _on_health_updated(current_health: float, max_health: float) -> void:
	if health_bar:
		health_bar.value = current_health
		health_bar.max_value = max_health
	else:
		printerr("Player: Health bar not found!")

func _on_damage_tick_timer_timeout() -> void:
	if not is_instance_valid(health) or health.get_current_health() <= 0:
		return

	sprite.modulate = Color.WHITE

	var overlapping_bodies = hurtbox.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body is Enemy:
			if body.enemy_data:
				sprite.modulate = Color.RED
				health.take_damage(body.enemy_data.damage)
			else:
				printerr("Overlapping enemy has no EnemyData!")

func _on_passives_updated() -> void:
	_collect_all_modifiers()
	_recalculate_all_stats()
