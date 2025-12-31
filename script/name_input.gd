extends Control

@onready var input_nama = $CenterContainer/VBoxContainer/LineEdit 
@onready var tombol_enter = $CenterContainer/VBoxContainer/Button

func _ready():
	# Cek apakah node ditemukan (untuk mencegah error null instance)
	if tombol_enter:
		tombol_enter.pressed.connect(_on_enter_pressed)
	else:
		print("ERROR: Tombol Enter tidak ditemukan! Cek path node.")

func _on_enter_pressed():
	# 1. Validasi: Jangan mau lanjut kalau nama kosong
	if input_nama.text.strip_edges() == "":
		print("Nama tidak boleh kosong!")
		return

	# 2. SIMPAN DATA: Masukkan nama ke variabel global
	Global.player_name = input_nama.text
	
	# 3. PINDAH SCENE: Masuk ke game (Surface)
	# Pastikan path ini benar mengarah ke scene game kamu
	get_tree().change_scene_to_file("res://Scene/Maps/surface.tscn")
