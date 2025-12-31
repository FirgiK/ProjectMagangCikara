extends Control

# Mendefinisikan tombol yang BENAR-BENAR ADA di scene MainMenu
@onready var btn_start = $CenterContainer/PanelContainer/VBoxContainer/BtnStart
@onready var btn_quit = $CenterContainer/PanelContainer/VBoxContainer/BtnQuit

func _ready():
	# Cek keamanan path node (Debugging)
	if btn_start == null:
		print("ERROR: BtnStart tidak ditemukan! Cek path node.")
		return # Stop jika error
		
	# Hubungkan sinyal klik tombol
	btn_start.pressed.connect(_on_start_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Saat Start ditekan, pindah ke scene INPUT NAMA
	# Pastikan nama file ini sesuai persis dengan file scene input yang Anda buat
	get_tree().change_scene_to_file("res://Scene/name_input_menu.tscn")

func _on_quit_pressed():
	# Keluar game
	get_tree().quit()
