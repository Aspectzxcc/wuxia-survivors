class_name Player
extends CharacterBody2D

@export var speed: float = 200.0 # Base move speed, will be modified by stats
@export var character_data: CharacterData # Assign the CharacterData resource here

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var health: Node = $Health
@onready var health_bar: ProgressBar = $HealthBar
@onready var technique_manager: TechniqueManager = $TechniqueManager
@onready var passive_manager: PassiveManager = $PassiveManager

const StatType = Enums.StatType # Use unified StatType
const UpgradeType = Enums.UpgradeType

# --- Player Stats ---
# Base values will be loaded from character_data
var base_stats: Dictionary = {} # Initialize as empty, will be populated from character_data

# Stores the *final calculated* values of player stats
var final_stats: Dictionary = {}

# Stores all active StatModifier resources affecting the player
var active_modifiers: Array[StatModifier] = []
# --- End Player Stats ---

var current_qi: int = 0
@export var experience_to_next_level: int = 5
var level: int = 1

# Variable to store joystick input
var joystick_vector: Vector2 = Vector2.ZERO

signal player_stats_updated

func _ready() -> void:
	PlayerTracker.register_player(self)
	health.health_updated.connect(_on_health_updated)
	health.died.connect(_on_death)
	GlobalEvents.upgrade_selected.connect(_on_upgrade_selected)

	# --- Connect to Virtual Joystick ---
	var joystick_nodes = get_tree().get_nodes_in_group("Joystick")
	if not joystick_nodes.is_empty():
		var joystick = joystick_nodes[0] # Assuming there's only one
		if joystick.has_signal("analogic_change"):
			joystick.analogic_change.connect(_on_virtual_joystick_analogic_change)
		else:
			printerr("Player: Found node in 'joystick' group, but it doesn't have the 'analogic_change' signal.")
	else:
		printerr("Player: Could not find any node in the 'joystick' group to connect to.")
	# --- End Joystick Connection ---

	# --- Load from CharacterData ---
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

		# Set sprite frames
		if is_instance_valid(character_data.sprite_frames):
			sprite.sprite_frames = character_data.sprite_frames
		else:
			printerr("Player: Missing sprite_frames in CharacterData!")

		# Add starting technique
		if is_instance_valid(technique_manager) and is_instance_valid(character_data.starting_technique):
			technique_manager.add_technique(character_data.starting_technique)
		elif not is_instance_valid(technique_manager):
			printerr("Player: TechniqueManager node is missing or invalid.")
		elif not is_instance_valid(character_data.starting_technique):
			printerr("Player: Missing starting_technique in CharacterData!")

	else:
		printerr("Player: No CharacterData assigned! Using default empty stats.")
		# Initialize with default empty stats or some fallback if needed
		base_stats = {} # Ensure it's at least an empty dictionary
	# --- End Load from CharacterData ---

	# Initialize final_stats and apply initial calculations
	_recalculate_all_stats() # This now uses the loaded base_stats

	health.set_max_health(final_stats.get(StatType.PLAYER_MAX_HEALTH, 100.0))
	health.set_current_health(health.get_max_health())

	# Emit initial state for Qi bar
	GlobalEvents.player_qi_updated.emit(current_qi, experience_to_next_level, level)

# Signal handler function for the joystick
func _on_virtual_joystick_analogic_change(move: Vector2) -> void:
	joystick_vector = move # Store the latest vector from the joystick
	
func _physics_process(_delta: float) -> void:
	# --- MODIFIED: Combine Keyboard/Gamepad and Joystick Input ---
	var keyboard_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var combined_input := keyboard_input + joystick_vector

	# Clamp the combined input vector length to 1 to prevent faster diagonal movement
	# when both inputs are used simultaneously.
	var input_direction := combined_input.limit_length(1.0)
	# --- END MODIFICATION ---

	# --- Use calculated Move Speed ---
	var calculated_speed = speed * final_stats.get(StatType.PLAYER_MOVE_SPEED, 1.0)
	velocity = input_direction * calculated_speed
	# --- END ---

	# --- Sprite flipping based on combined input ---
	if input_direction.x > 0.1: # Use a small threshold
		sprite.scale.x = 1
	elif input_direction.x < -0.1:
		sprite.scale.x = -1
	# --- End sprite flipping modification ---

	move_and_slide()

	PlayerTracker.update_position(global_position)

func collect_qi(value: int) -> void:
	# --- Use calculated Qi Gain ---
	var modified_value = int(ceil(float(value) * final_stats.get(StatType.PLAYER_QI_GAIN, 1.0)))
	current_qi += modified_value
	# --- END ---
	# --- Emit update after collecting ---
	GlobalEvents.player_qi_updated.emit(current_qi, experience_to_next_level, level)

	while current_qi >= experience_to_next_level:
		var previous_exp_needed = experience_to_next_level
		level += 1

		current_qi -= previous_exp_needed

		# Use the new function from StatCalculator
		experience_to_next_level = StatCalculator.get_xp_for_next_level(level)

		# --- Emit update after level up ---
		GlobalEvents.player_qi_updated.emit(current_qi, experience_to_next_level, level)

		_trigger_level_up_event()

func _trigger_level_up_event():
	var options = UpgradeGenerator.generate_upgrade_options(self, 3) # Request 3 options

	# Check if options were successfully generated
	if options.is_empty():
		printerr("Player: Failed to generate level up options!")
		# Handle error case - maybe retry, offer default, or skip UI?
		return 
		
	# Emit the global signal WITH the generated options data
	# This will be caught by the UI to show the level-up options
	GlobalEvents.player_leveled_up.emit(options) 

func _on_upgrade_selected(selected_upgrade_data: Dictionary) -> void: 
	
	# Apply selected upgrade
	var upgrade_type = selected_upgrade_data.get("type", UpgradeType.UNKNOWN) 
	var upgrade_resource = selected_upgrade_data.get("resource") # Contains the actual resource

	if upgrade_resource == null:
		printerr("Player: Upgrade selected data is missing 'resource'.")
		return
		
	# Ensure managers are valid before matching
	if not is_instance_valid(technique_manager):
		printerr("Player: TechniqueManager node is missing or invalid.")
		# Optionally return here if techniques are essential
	if not is_instance_valid(passive_manager):
		printerr("Player: PassiveManager node is missing or invalid.")
		# Optionally return here if passives are essential

	match upgrade_type: 
		UpgradeType.TECHNIQUE_UPGRADE:
			if is_instance_valid(technique_manager):
				# --- MODIFIED: Use the resource directly ---
				if upgrade_resource is TechniqueData:
					technique_manager.level_up_technique(upgrade_resource)
				else:
					printerr("Player: Provided resource for TECHNIQUE_UPGRADE is not TechniqueData: ", upgrade_resource)
				# --- END MODIFICATION ---
			else:
				printerr("Player: TechniqueManager not found for upgrade.")
				
		UpgradeType.NEW_TECHNIQUE:
			if is_instance_valid(technique_manager):
				# --- MODIFIED: Use the resource directly ---
				if upgrade_resource is TechniqueData:
					if technique_manager.has_method("add_technique"):
						technique_manager.add_technique(upgrade_resource)
					else:
						printerr("Player: TechniqueManager is missing the 'add_technique' method.")
				else:
					printerr("Player: Provided resource for NEW_TECHNIQUE is not TechniqueData: ", upgrade_resource)
				# --- END MODIFICATION ---
			else:
				printerr("Player: TechniqueManager not found for new technique.")

		UpgradeType.PASSIVE_UPGRADE:
			if is_instance_valid(passive_manager):
				# --- MODIFIED: Use the resource directly ---
				if upgrade_resource is PassiveData:
					if passive_manager.level_up_passive(upgrade_resource):
						# Successfully leveled up, re-collect all modifiers
						_collect_all_modifiers()
						_recalculate_all_stats()
				else:
					printerr("Player: Provided resource for PASSIVE_UPGRADE is not PassiveData: ", upgrade_resource)
				# --- END MODIFICATION ---
			else:
				printerr("Player: PassiveManager not found for passive upgrade.")

		UpgradeType.NEW_PASSIVE:
			if is_instance_valid(passive_manager):
				# --- MODIFIED: Use the resource directly ---
				if upgrade_resource is PassiveData:
					if passive_manager.add_passive(upgrade_resource):
						# Successfully added, re-collect all modifiers
						_collect_all_modifiers()
						_recalculate_all_stats()
				else:
					printerr("Player: Provided resource for NEW_PASSIVE is not PassiveData: ", upgrade_resource)
				# --- END MODIFICATION ---
			else:
				printerr("Player: PassiveManager not found for new passive.")

		_: # Handles UpgradeType.UNKNOWN or any unexpected value
			# --- MODIFIED: Update error message ---
			printerr("Player: Unknown or invalid upgrade type selected: ", upgrade_type, " with resource: ", upgrade_resource)
			# --- END MODIFICATION ---

# --- Stat Management Functions ---

# Collects all StatModifiers from active passives
func _collect_all_modifiers() -> void:
	active_modifiers.clear()
	if not is_instance_valid(passive_manager):
		printerr("Player: Cannot collect modifiers, PassiveManager is invalid.")
		return

	var current_active_passives: Array[PassiveData] = passive_manager.get_active_passives() # format { PassiveData: {"level": int} }
	for passive_data in current_active_passives:
		if not is_instance_valid(passive_data) or not passive_data is PassiveData:
			printerr("Player: Invalid key found in active passives dictionary.")
			continue

		if passive_data.level <= 0:
			continue

		# Get modifiers for all levels up to the current one
		for level_to_check in range(1, passive_data.level + 1):
			var upgrade_data: UpgradeData = passive_data.get_upgrade_for_level(level_to_check)
			if is_instance_valid(upgrade_data) and upgrade_data.has_method("get_modifications"):
				var mods_this_level: Array = upgrade_data.get_modifications()
				if mods_this_level is Array:
					for mod in mods_this_level:
						if mod is StatModifier:
							# Ensure the modifier is actually for a PLAYER stat before adding
							# Check if the stat name starts with "PLAYER_"
							if StatType.keys()[mod.stat].begins_with("PLAYER_"):
								active_modifiers.append(mod)
							# else: # Optional: Keep this if you want to log non-player mods found here
								# printerr("Player: Passive upgrade provided a non-PLAYER StatModifier: ", mod.stat)
				else:
					printerr("Player: PassiveData.get_modifications() did not return an Array for ", passive_data.passive_name, " L", level_to_check)


# Recalculates all final player stats based on base stats and active modifiers
func _recalculate_all_stats() -> void:
	# Clear previous final stats before recalculating
	final_stats.clear()
	# Iterate only through PLAYER stats defined in the *loaded* base_stats
	for stat_type_int in base_stats:
		var stat_type: StatType = stat_type_int # Cast the int key back to the enum type
		# Ensure we only calculate PLAYER stats here
		if not StatType.keys()[stat_type].begins_with("PLAYER_"):
			printerr("Player: Found non-PLAYER stat key (%s) in base_stats during recalculation. Skipping." % StatType.keys()[stat_type])
			continue
		final_stats[stat_type] = StatCalculator.calculate_player_stat(self, stat_type)
		# print(" - %s: %s" % [StatType.keys()[stat_type], str(final_stats[stat_type])]) # Debug

	# Apply recalculated stats where necessary
	if is_instance_valid(health):
		health.set_max_health(final_stats.get(StatType.PLAYER_MAX_HEALTH, 100.0))

	_update_magnet_area()
	# Speed is applied in _physics_process
	# Qi Gain is applied in collect_qi
	# Might, Area, Duration, etc., are used by StatCalculator when calculating technique stats

	player_stats_updated.emit()

# Gets all active modifiers relevant to a specific player stat type
func get_modifiers_for_stat(target_stat_type: StatType) -> Array[StatModifier]:
	var relevant_mods: Array[StatModifier] = []
	for modifier in active_modifiers:
		# Check if the stat name starts with "PLAYER_" and matches the target type
		if StatType.keys()[modifier.stat].begins_with("PLAYER_") and modifier.stat == target_stat_type:
			relevant_mods.append(modifier)
	return relevant_mods

# Helper to update the magnet area collision shape size
func _update_magnet_area() -> void:
	var magnet_radius = final_stats.get(StatType.PLAYER_MAGNET, 32.0)
	var magnet_shape = $MagnetArea/CollisionShape2D as CollisionShape2D
	if is_instance_valid(magnet_shape) and magnet_shape.shape is CircleShape2D:
		(magnet_shape.shape as CircleShape2D).radius = magnet_radius
	else:
		printerr("Player: Could not find or update MagnetArea shape.")


# --- Signal Handlers ---

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
