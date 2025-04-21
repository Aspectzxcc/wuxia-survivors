extends Node

# Unified Stat Type Enum
enum StatType {
    TECHNIQUE_COOLDOWN,         # Time between activations (Lower is better)
    TECHNIQUE_DAMAGE,           # Base damage per hit
    TECHNIQUE_AREA_SIZE,        # Multiplier for hitbox size/radius (Larger is better)
    TECHNIQUE_DURATION,         # How long an effect/hitbox lasts (Longer is better for some)
    TECHNIQUE_ATTACK_COUNT,     # How many distinct attacks/instances per activation (e.g., Bible count, Axe count)
    TECHNIQUE_KNOCKBACK,        # Force applied to enemies on hit
    TECHNIQUE_SPEED,            # Speed of projectiles (Higher is better)
    TECHNIQUE_PIERCING,         # How many enemies a projectile can pass through (Higher is better)
    TECHNIQUE_AMOUNT,           # How many projectiles/sub-attacks per Attack Count (e.g., Knife projectiles, Whip hits) (Higher is better)
    TECHNIQUE_INTERVAL,         # Time delay *between* sub-attacks when Amount > 1 (Lower is better)
    TECHNIQUE_HITBOX_DELAY,     # Delay before the hitbox becomes active after activation (Lower is better)
    TECHNIQUE_CRIT_CHANCE,      # Chance to critically hit (%)
    TECHNIQUE_CRIT_MULTIPLIER,  # Damage multiplier on critical hit (e.g., 2.0 for 2x damage)
    TECHNIQUE_EFFECT_CHANCE,    # Generic chance for status effects like freeze, burn etc. (%)
    TECHNIQUE_BLOCKABLE,        # Whether the technique can be blocked by obstacles (e.g., walls, shields)
    TECHNIQUE_RARITY,           # Rarity of the technique (e.g., common, rare, legendary)

    PLAYER_MAX_HEALTH,          # Player Max Health
    PLAYER_RECOVERY,            # Player Health Recovery (Flat HP per second or percentage)
    PLAYER_ARMOR,               # Player Armor (Flat reduction or percentage)
    PLAYER_MOVE_SPEED,          # Player Movement Speed
    PLAYER_QI_GAIN,             # Experience gain multiplier
    PLAYER_LUCK,                # Affects chance-based events, drop rates, crit chance?
    PLAYER_GREED,               # Affects gold/coin gain
    PLAYER_MAGNET,              # Pickup radius for Qi Orbs
    PLAYER_CURSE,               # Increases enemy speed, health, quantity, frequency (Higher is worse for player)
    PLAYER_DAMAGE,              # Global Damage multiplier/additive
    PLAYER_AREA_SIZE,           # Global Area multiplier
    PLAYER_SPEED,               # Global Projectile Speed multiplier
    PLAYER_DURATION,            # Global Effect Duration multiplier
    PLAYER_AMOUNT,              # Global +Amount additive
    PLAYER_COOLDOWN,            # Global Cooldown multiplier (Lower is better)
    PLAYER_REVIVAL,             # Amount of times the player can revive
    PLAYER_CRIT_CHANCE,         # Global Critical Hit Chance
    PLAYER_REROLL,              # Amount of times the player can reroll
    PLAYER_SKIP,                # Amount of times the player can skip
    PLAYER_BANISH,              # Amount of times the player can banish
    PLAYER_CHARM,               # Increase enemy wave quantity by flat amount
    PLAYER_DEFANG,              # Chance to turn an enemy unable to attack
    PLAYER_SEAL,                # Chance to disable a technique before the game starts
}

enum ModifierType {
    ADD,            # Additive bonus (e.g., +10 Damage) -> Base + Value
    MULTIPLY,       # Multiplicative bonus (e.g., +20% Damage -> multiply by 1.2) -> Base * Value
    ADD_PERCENTAGE, # Additive percentage bonus (e.g., +10% Luck -> add 0.1 to a percentage sum) -> Base * (1 + Value)
    SET             # Set the value directly (e.g., Set Piercing to 5) -> Value
    # VS uses multiplicative bonuses for most % increases. We'll primarily use MULTIPLY for percentages.
    # ADD_PERCENTAGE might be less common or used for specific stats like Luck.
}

enum UpgradeType {
    TECHNIQUE_UPGRADE,
    NEW_TECHNIQUE,
    NEW_PASSIVE,
    PASSIVE_UPGRADE,
    UNKNOWN # Optional: for error handling
}
enum EnemyState {
    MOVING,
    KNOCKED_BACK
}

enum QiOrbState {
    IDLE,
    ATTRACTED
}

enum PlatformType { 
    UNKNOWN, 
    PC, 
    MOBILE 
}

enum SoundEffect {
    NONE, # Default/Error case
    HIT_ENEMY,
    ENEMY_DEATH,
    PLAYER_HURT,
    PLAYER_DEATH,
    LEVEL_UP,
    QI_ORB_PICKUP,
    UI_CLICK,
    UI_HOVER,
    GAME_START,
    GAME_OVER,
    TECHNIQUE_ACTIVATE_QI_BLAST, # Example specific technique sound
    TECHNIQUE_ACTIVATE_WANDERERS_STRIKE # Example specific technique sound
    # Add more specific sounds as needed
}