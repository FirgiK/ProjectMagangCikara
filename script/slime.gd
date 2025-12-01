extends CharacterBody2D

# --- LEVEL & VARIANT SETTINGS ---
@export_group("Level Generator")
@export var min_level : int = 1
@export var max_level : int = 4

@export_group("Base Stats (Lv 1)")
@export var base_max_hp : int = 10
@export var base_atk : int = 3
@export var base_def : int = 0
@export var base_exp_reward : int = 15

# --- MOVEMENT SETTINGS ---
@export var speed_wander : float = 20.0
@export var speed_chase : float = 65.0
@export var wander_radius : float = 50.0

# --- REAL TIME STATS ---
var level : int = 1
var max_hp : int
var current_hp : int
var atk : int
var def : int
var exp_reward : int

# --- STATE MACHINE ---
enum { IDLE, WANDER, CHASE, ATTACK, HURT, DEATH }
var state = IDLE
var home_position : Vector2
var target_player = null 
var wander_direction : Vector2
var anim_suffix : String = "down"

# --- NODES ---
@onready var anim = $AnimatedSprite2D
@onready var state_timer = $StateTimer
@onready var attack_pivot = $AttackPivot 
@onready var hitbox_shape = $AttackPivot/Hitbox/CollisionShape2D

func _ready():
	y_sort_enabled = true
	randomize()
	initialize_level() # Hitung stats
	
	home_position = global_position
	change_state(IDLE)
	
	# --- KONEKSI SINYAL UTAMA ---
	anim.animation_finished.connect(_on_animation_finished)
	anim.frame_changed.connect(_on_frame_changed)
	
	# --- KONEKSI HITBOX (Targeting Hurtbox Area) ---
	# Kita pastikan script mendengar sinyal "area_entered"
	# Area ini adalah Hitbox Slime, mencari Hurtbox Player
	var hitbox = $AttackPivot/Hitbox
	if !hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.connect(_on_hitbox_area_entered)

func initialize_level():
	level = randi_range(min_level, max_level)
	
	# Rumus Stats Scaling
	max_hp = base_max_hp + ((level - 1) * 5)
	current_hp = max_hp
	atk = base_atk + ((level - 1) * 1)
	def = base_def + floor((level - 1) / 2.0)
	exp_reward = int(base_exp_reward * pow(1.2, level - 1))
	
	# Visual Level Indicator (Makin merah = level tinggi)
	var tint = 1.0 - (level * 0.05)
	anim.modulate = Color(1, tint, tint)

func _physics_process(_delta):
	match state:
		IDLE:
			velocity = Vector2.ZERO
			
		WANDER:
			velocity = wander_direction * speed_wander
			if global_position.distance_to(home_position) > wander_radius:
				wander_direction = (home_position - global_position).normalized()
			
			update_animation_direction(velocity)
			play_smart_anim("run")
			
		CHASE:
			if target_player:
				var direction = (target_player.global_position - global_position).normalized()
				var dist = global_position.distance_to(target_player.global_position)
				
				# SOLUSI ANTI-LENGKET: Stop mendorong jika sudah nempel
				if dist > 20.0: 
					velocity = direction * speed_chase
				else:
					velocity = Vector2.ZERO 
				
				attack_pivot.rotation = direction.angle() - PI/2
				update_animation_direction(direction)
				play_smart_anim("run")
				
			else:
				change_state(IDLE)
		
		ATTACK, HURT, DEATH:
			velocity = Vector2.ZERO

	move_and_slide()

# --- STATE MANAGER ---
func change_state(new_state):
	state = new_state
	match state:
		IDLE:
			play_smart_anim("idle")
			state_timer.start(10.0)
		WANDER:
			play_smart_anim("run")
			wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			state_timer.start(randf_range(2.0, 4.0))
		CHASE:
			play_smart_anim("run")
			state_timer.stop()
		ATTACK:
			perform_attack()
		HURT:
			play_smart_anim("hurt")
			state_timer.stop()
		DEATH:
			play_smart_anim("death")
			# Matikan fisik dan hitbox saat mati
			$CollisionShape2D.set_deferred("disabled", true)
			hitbox_shape.set_deferred("disabled", true)

func perform_attack():
	play_smart_anim("attack")

func update_animation_direction(dir: Vector2):
	if dir == Vector2.ZERO: return

	# Prioritas Horizontal
	if abs(dir.x) > abs(dir.y):
		anim_suffix = "side"
		if dir.x > 0:
			anim.flip_h = true  # Kanan (Mirror aset kiri)
		else:
			anim.flip_h = false # Kiri (Normal)
	else:
		if dir.y > 0: anim_suffix = "down"
		else: anim_suffix = "up"
		anim.flip_h = false

func play_smart_anim(base_name: String):
	var full_name = base_name + "_" + anim_suffix
	if anim.animation != full_name:
		anim.play(full_name)

# --- SINKRONISASI HITBOX ---
func _on_frame_changed():
	if state == ATTACK:
		# Hitbox NYALA hanya di frame 4, 5, 6, 7
		if anim.frame >= 4 and anim.frame <= 7:
			hitbox_shape.set_deferred("disabled", false)
		else:
			hitbox_shape.set_deferred("disabled", true)
	else:
		hitbox_shape.set_deferred("disabled", true)

# --- SENSORS & SIGNALS ---
func _on_deetection_area_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target_player = body
		if state != DEATH and state != HURT:
			change_state(CHASE)

func _on_deetection_area_body_exited(body: Node2D) -> void:
	if body == target_player:
		target_player = null
		if state != DEATH:
			change_state(IDLE)

func _on_attack_range_body_entered(body: Node2D) -> void:
	if body == target_player and state == CHASE:
		change_state(ATTACK)

func _on_attack_range_body_exited(_body: Node2D) -> void:
	pass

func _on_state_timer_timeout():
	match state:
		IDLE: change_state(WANDER)
		WANDER: change_state(IDLE)

func _on_animation_finished():
	if state == ATTACK:
		if target_player:
			var dist = global_position.distance_to(target_player.global_position)
			if dist <= 35.0:
				change_state(ATTACK)
			else:
				change_state(CHASE)
		else:
			change_state(IDLE)
	elif state == HURT:
		change_state(CHASE)
	elif state == DEATH:
		queue_free()

# --- LOGIKA SERANGAN BARU (TARGET HURTBOX) ---
func _on_hitbox_area_entered(area: Area2D) -> void:
	# Cek apakah area yang kena adalah Hurtbox milik Player?
	if area.name == "Hurtbox":
		var target = area.get_parent() # Naik ke node Player (CharacterBody2D)
		
		# Validasi target dan state
		if target and state == ATTACK:
			if target.has_method("take_damage"):
				# Berikan damage ke Player
				target.take_damage(atk, global_position)
				
				# Matikan hitbox agar 1 ayunan = 1 damage (tidak spam)
				hitbox_shape.set_deferred("disabled", true)

# --- MENERIMA DAMAGE ---
func take_damage(incoming_damage, attacker = null):
	if state == DEATH: return
	
	var actual_damage = max(1, incoming_damage - def)
	current_hp -= actual_damage
	
	if current_hp <= 0:
		change_state(DEATH)
		if attacker and attacker.has_method("gain_exp"):
			attacker.gain_exp(exp_reward)
	else:
		change_state(HURT)
