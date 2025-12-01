extends CharacterBody2D

# --- DATA STATS ---
@export var stats : PlayerStats 
@export var friction : float = 0.2
@export var acceleration : float = 0.2

var current_health : int
var state = MOVE
var anim_suffix : String = "down"

enum { MOVE, ATTACK, HURT, DEATH }

@onready var anim = $AnimatedSprite2D
@onready var weapon_pivot = $WeaponPivot
@onready var sword_hitbox_shape = $WeaponPivot/SwordHitbox/CollisionShape2D
@onready var sword_hitbox = $WeaponPivot/SwordHitbox

func _ready():
	y_sort_enabled = true
	
	# Inisialisasi Stats
	if stats == null: stats = PlayerStats.new()
	current_health = stats.max_hp
	
	# --- KONEKSI SIGNAL VIA KODE (AUTO) ---
	# Ini menggantikan tugas panah hijau di editor
	
	# 1. Sinkronisasi Hitbox (Frame)
	if !anim.frame_changed.is_connected(_on_frame_changed):
		anim.frame_changed.connect(_on_frame_changed)
	
	# 2. Selesai Animasi (Attack/Death)
	if !anim.animation_finished.is_connected(_on_animation_finished):
		anim.animation_finished.connect(_on_animation_finished)
		
	# 3. Pedang Kena Musuh
	if !sword_hitbox.body_entered.is_connected(_on_sword_hit_enemy):
		sword_hitbox.body_entered.connect(_on_sword_hit_enemy)

func _physics_process(_delta):
	match state:
		# Player bisa gerak saat HURT (No Stun)
		MOVE: move_state()
		HURT: move_state() 
		ATTACK: attack_state()
		DEATH: velocity = Vector2.ZERO

func move_state():
	var input_vector = Input.get_vector("left", "right", "up", "down")
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.lerp(input_vector * stats.get_speed(), acceleration)
		weapon_pivot.rotation = input_vector.angle() - PI/2
		
		# Update Arah
		if abs(input_vector.x) > abs(input_vector.y):
			anim_suffix = "side"
			anim.flip_h = (input_vector.x > 0)
		else:
			if input_vector.y > 0: anim_suffix = "down"
			else: anim_suffix = "up"
			anim.flip_h = false
		
		# --- LOGIKA ANIMASI PINTAR ---
		# Jika tidak sakit, mainkan Run. Jika sakit, paksa Hurt.
		if state != HURT:
			play_anim("run")
		else:
			play_anim("hurt") 
			
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
		
		if state != HURT:
			play_anim("idle")
		else:
			play_anim("hurt")
	
	move_and_slide()
	
	if Input.is_action_just_pressed("attack") and state != HURT:
		state = ATTACK

func attack_state():
	velocity = Vector2.ZERO
	play_anim("attack")
	anim.speed_scale = stats.aspd 

func play_anim(action_name: String):
	var full_name = action_name + "_" + anim_suffix
	if action_name == "death": full_name = "death"
	
	# Safety Check: Hanya mainkan jika animasi ada
	if anim.sprite_frames.has_animation(full_name):
		if anim.animation != full_name:
			anim.play(full_name)
	else:
		# Fallback ke nama dasar jika varian arah tidak ada
		if anim.sprite_frames.has_animation(action_name):
			if anim.animation != action_name:
				anim.play(action_name)

# --- FUNGSI SIGNAL (Dipanggil otomatis oleh _ready) ---

func _on_frame_changed():
	if state == ATTACK:
		# Frame 3-6 Pedang Aktif
		if anim.frame >= 3 and anim.frame <= 6:
			sword_hitbox_shape.set_deferred("disabled", false)
		else:
			sword_hitbox_shape.set_deferred("disabled", true)
	else:
		sword_hitbox_shape.set_deferred("disabled", true)

func _on_animation_finished():
	if state == ATTACK:
		state = MOVE
		sword_hitbox_shape.set_deferred("disabled", true)
		anim.speed_scale = 1.0
		
	elif state == HURT:
		state = MOVE
		modulate = Color.WHITE # Reset warna merah
		
	elif state == DEATH:
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()

func _on_sword_hit_enemy(body):
	if body.has_method("take_damage"):
		body.take_damage(stats.attack, self)

# --- SISTEM DAMAGE ---

func take_damage(amount, _enemy_pos):
	if state == DEATH: return
	
	var actual_damage = max(1, amount - stats.defense)
	current_health -= actual_damage
	print("Player HP: ", current_health)
	
	if current_health <= 0:
		die()
	else:
		state = HURT
		play_anim("hurt")
		
		# Efek Visual Flash Merah
		modulate = Color(1, 0, 0)
		var t = create_tween()
		t.tween_property(self, "modulate", Color.WHITE, 0.4)

func die():
	print("GAME OVER")
	state = DEATH
	$CollisionShape2D.set_deferred("disabled", true)
	$WeaponPivot/SwordHitbox/CollisionShape2D.set_deferred("disabled", true)
	modulate = Color.WHITE
	play_anim("death")

func gain_exp(amount):
	if stats.gain_exp(amount):
		print("LEVEL UP! Lv: ", stats.level)
		current_health = stats.max_hp
