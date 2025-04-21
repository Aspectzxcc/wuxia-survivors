class_name CharacterData
extends Resource

## Name of the character (e.g., "Swift Sword Initiate")
@export var character_name: String = "Default Character"

## Brief description for character selection screens
@export var description: String = "A balanced starting character."

## Icon for character selection
@export var icon: Texture2D

## Sprite frames for the character's appearance
@export var sprite_frames: SpriteFrames

# --- Individual Stat Exports ---
@export_group("Base Stats")
@export var max_health: float = 100.0
@export var recovery: float = 0.0
@export var armor: float = 0.0
@export var move_speed: float = 1.0 # Multiplier for base speed
@export var qi_gain: float = 1.0
@export var luck: float = 1.0
@export var greed: float = 1.0
@export var magnet: float = 32.0 # Base radius, actual radius calculated
@export var curse: float = 1.0 # Enemy speed, health, quantity, and frequency multiplier
@export var damage: float = 1.0
@export var area_size: float = 1.0
@export var speed: float = 1.0 # Projectile Speed
@export var duration: float = 1.0 
@export var amount: int = 0 # Additive
@export var cooldown: float = 1.0 # Multiplier
@export var growth: float = 1.0 # Multiplier for growth effects
@export var revival: int = 0 # Amount of times the player can revive
@export var reroll: int = 0 # Amount of times the player can reroll
@export var skip: int = 0 # Amount of times the player can skip
@export var banish: int = 0 # Amount of times the player can banish
@export var charm: int = 0 # Increase enemy wave quantity by flat amount
@export var defang: float = 0.0 # Chance to turn an enemy spawn unable to attack
@export var seal: int = 0 # Amount of times the player can seal a technique before the game starts
@export var crit_chance: float = 1.0 # Global Critical Hit Chance multiplier
@export_group("") # End Stat Group

## The initial technique the character starts with.
@export var starting_technique: TechniqueData