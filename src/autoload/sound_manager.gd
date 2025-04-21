# filepath: src/autoload/SoundManager.gd
extends Node

const SoundEffect = Enums.SoundEffect

# --- Sound Preloads ---
# Map SoundEffect enum values to their audio file paths
const SOUND_PATHS = {
    SoundEffect.HIT_ENEMY: "res://assets/audio/sfx/hit_sound2.wav",
    # Add paths for other sounds defined in the enum:
    # Enums.SoundEffect.ENEMY_DEATH: "res://assets/audio/sfx/enemy_death.wav",
    # Enums.SoundEffect.PLAYER_HURT: "res://assets/audio/sfx/player_hurt.wav",
    # Enums.SoundEffect.LEVEL_UP: "res://assets/audio/sfx/level_up.wav",
    # Enums.SoundEffect.QI_ORB_PICKUP: "res://assets/audio/sfx/pickup.wav",
    # Enums.SoundEffect.UI_CLICK: "res://assets/audio/sfx/ui_click.wav",
    # ... etc.
}

# Dictionary to hold preloaded AudioStream resources
var preloaded_sounds: Dictionary = {}

# --- Audio Player Pool ---
# Use multiple players to allow sounds to overlap
const PLAYER_POOL_SIZE = 5 # Adjust as needed
var audio_players: Array[AudioStreamPlayer] = []
var current_player_index: int = 0

func _ready():
    for effect_enum in SOUND_PATHS:
        var path = SOUND_PATHS[effect_enum]
        var stream = load(path) # Use load() instead of preload() for dynamic loading
        if stream is AudioStream:
            preloaded_sounds[effect_enum] = stream
        else:
            printerr("SoundManager: Failed to load sound at path: ", path)

    # Create the pool of AudioStreamPlayer nodes
    for i in range(PLAYER_POOL_SIZE):
        var player = AudioStreamPlayer.new()
        player.bus = "SFX" # <-- Assign the player to the "SFX" bus
        add_child(player) # Add player to the scene tree
        audio_players.append(player)

# --- Generic Play Function ---
func play_sound(effect: SoundEffect):
    # Check if the sound effect exists in our preloaded dictionary
    if not preloaded_sounds.has(effect):
        printerr("SoundManager: Sound effect enum not found in preloaded sounds: ", Enums.SoundEffect.keys()[effect])
        return

    # Get the preloaded audio stream
    var stream: AudioStream = preloaded_sounds[effect]

    # Find an available player from the pool
    # Cycle through the pool to play the next sound
    var player = audio_players[current_player_index]
    current_player_index = (current_player_index + 1) % PLAYER_POOL_SIZE

    # Assign the stream and play
    if is_instance_valid(player):
        player.stream = stream
        player.play()
    else:
        # This should ideally not happen if _ready() completed
        printerr("SoundManager: Audio player instance in pool is invalid.")

# --- Optional: Specific Play Functions (Convenience) ---
func play_hit_enemy_sound():
    play_sound(Enums.SoundEffect.HIT_ENEMY)
