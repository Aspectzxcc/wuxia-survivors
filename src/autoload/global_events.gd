extends Node

signal player_died
signal enemy_killed
signal player_leveled_up(options_data: Array[Dictionary])
signal upgrade_selected(selected_upgrade_data)
signal player_qi_updated(qi: int)