extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var map_container: Node2D = $MapContainer

func _ready():
	SceneManager.player_node = player
	SceneManager.map_container_node = map_container
	SceneManager.change_map("res://Map/Village.tscn", "InitialSpawn")
