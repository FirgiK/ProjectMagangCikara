extends Node2D

@export var enemy_scene : PackedScene # Drag Slime.tscn kesini
@export var spawn_radius : float = 200.0
@export var max_enemies : int = 5
@export var spawn_interval : float = 2.0 # Detik

var current_enemy_count : int = 0
var timer : Timer

func _ready():
	# Setup timer otomatis
	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Spawn awal langsung
	spawn_enemy()

func _on_timer_timeout():
	if current_enemy_count < max_enemies:
		spawn_enemy()

func spawn_enemy():
	if enemy_scene == null: return
	
	var enemy = enemy_scene.instantiate()
	
	# Tentukan posisi random dalam lingkaran
	var random_angle = randf() * TAU # TAU = 2 * PI
	var random_dist = randf_range(0, spawn_radius)
	var spawn_pos = Vector2(cos(random_angle), sin(random_angle)) * random_dist
	
	# Set posisi relatif terhadap spawner
	enemy.global_position = global_position + spawn_pos
	
	# PENTING: Masukkan enemy ke parent scene (World), bukan ke Spawner
	# Agar Y-Sort bekerja dengan benar
	get_parent().add_child.call_deferred(enemy)
	current_enemy_count += 1
	
