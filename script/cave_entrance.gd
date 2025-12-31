extends StaticBody2D

@export var dungeon_scene: String = "res://Scene/Maps/dungeon.tscn"

func _ready():
	var trigger = $EntranceTrigger
	
	# Reset koneksi sinyal untuk mencegah duplikasi
	if trigger.body_entered.is_connected(_on_body_entered):
		trigger.body_entered.disconnect(_on_body_entered)
	
	trigger.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		if body.has_method("save_data_for_transition"):
			body.save_data_for_transition()
		
		call_deferred("change_map")

func change_map():
	get_tree().change_scene_to_file(dungeon_scene)
