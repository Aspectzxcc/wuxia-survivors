# game_data.gd
extends Node

var all_techniques: ResourceGroup = preload("res://src/resource/resource_groups/all_techniques.tres")
var all_passives: ResourceGroup = preload("res://src/resource/resource_groups/all_passives.tres")

var _all_techniques: Array[TechniqueData] = []
var _all_passives: Array[PassiveData] = []

func _ready():
    # load all techniques
    all_techniques.load_all_into(_all_techniques)
    print("GameData: Loaded all techniques: ", _all_techniques.size())

    # load all passives
    all_passives.load_all_into(_all_passives)
    print("GameData: Loaded all passives: ", _all_passives.size())

func get_all_techniques() -> Array[TechniqueData]:
    return _all_techniques

func get_all_passives() -> Array[PassiveData]:
    return _all_passives