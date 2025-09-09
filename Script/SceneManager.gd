extends Node

var current_map_scene = null
var player_node = null
var map_container_node = null

func change_map(map_path: String, spawn_point_name: String):
	if is_instance_valid(current_map_scene):
		current_map_scene.queue_free()

	var new_map_resource = load(map_path)
	current_map_scene = new_map_resource.instantiate()
	map_container_node.add_child(current_map_scene)

	var spawn_point = current_map_scene.find_child(spawn_point_name)
	if is_instance_valid(spawn_point) and is_instance_valid(player_node):
		player_node.global_position = spawn_point.global_position
