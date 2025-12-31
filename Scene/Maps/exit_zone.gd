extends Area2D

var target_scene = "res://Scene/Maps/surface.tscn" 
var exit_spawn_pos = Vector2(1152, 120) # Sesuaikan koordinat gua kamu

func _ready():
	monitoring = true
	if !body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		call_deferred("teleport_sequence", body)

func teleport_sequence(player):
	print("Keluar dungeon...")
	
	if player.has_method("save_data_for_transition"):
		player.save_data_for_transition()
	
	Global.next_spawn_pos = exit_spawn_pos 
	get_tree().change_scene_to_file(target_scene)
