extends Node2D

func _ready():
	SceneManager.player_node = $Player
	SceneManager.map_container_node = $MapContainer
	SceneManager.change_map("res://Maps/Village.tscn", "InitialSpawn")
