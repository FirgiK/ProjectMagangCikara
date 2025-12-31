extends CanvasLayer

@onready var top_curtain = $TopCurtain
@onready var bottom_curtain = $BottomCurtain
@onready var terminal_label = $TerminalText
@onready var player_node = $"../Environment/Props/Player"

var boot_lines: Array[String] = []

func _ready():
	# Cek Global Data: Jika intro sudah pernah main, hapus node ini segera
	if Global.intro_played:
		queue_free()
		return

	# Tandai intro sudah dimainkan
	Global.intro_played = true

	if player_node:
		player_node.set_physics_process(false)
		if player_node.has_method("set_process_input"):
			player_node.set_process_input(false)
	
	setup_text_data()
	start_terminal_sequence()

func setup_text_data():
	terminal_label.text = ""
	var p_name = Global.player_name.to_upper()
	
	boot_lines = [
		"SYSTEM REBOOT...",
		"CHECKING MEMORY INTEGRITY... OK",
		"BIOMETRIC SCAN: " + p_name,
		"ATMOSPHERE: TOXIC d",
		"MISSION OBJECTIVE: FIND THE BEACON",
		"...",
		"ENGAGING OPTICAL SENSORS..."
	]

func start_terminal_sequence():
	for line in boot_lines:
		for letter in line:
			terminal_label.text += letter
			await get_tree().create_timer(0.04).timeout
		
		terminal_label.text += "\n"
		await get_tree().create_timer(0.3).timeout
	
	await get_tree().create_timer(0.8).timeout
	open_curtains()

func open_curtains():
	terminal_label.hide()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	var half_screen = get_viewport().get_visible_rect().size.y / 2
	var full_screen = get_viewport().get_visible_rect().size.y
	
	tween.tween_property(top_curtain, "position:y", -half_screen, 1.5)
	tween.tween_property(bottom_curtain, "position:y", full_screen, 1.5)
	
	tween.chain().finished.connect(finish_intro)

func finish_intro():
	if player_node:
		player_node.set_physics_process(true)
		player_node.set_process_input(true)
	queue_free()
