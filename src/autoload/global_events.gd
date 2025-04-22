extends Node

signal player_died
signal enemy_killed
signal player_leveled_up(player: Player)
signal upgrade_selected(selected_upgrade_data)
signal player_qi_updated(qi: int)