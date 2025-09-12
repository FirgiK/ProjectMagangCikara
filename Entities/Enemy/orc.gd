extends CharacterBody2D
class_name Orc

@export var stats: StatResource

enum State {IDLE, CHASE, ATTACK}
var current_state: State = State.IDLE
var player_target: CharacterBody2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_hitbox: CollisionShape2D = $AttackHitbox/CollisionShape2D

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta: float):
	match current_state:
		State.IDLE:
			idle_state()
		State.CHASE:
			chase_state()
		State.ATTACK:
			attack_state()
			
	move_and_slide()
	update_animation()

# ----------------------------------------------------------------------------
# LOGIKA STATE
# ----------------------------------------------------------------------------

func idle_state():
	velocity = Vector2.ZERO
	if is_instance_valid(player_target):
		current_state = State.CHASE

func chase_state():
	if not is_instance_valid(player_target):
		current_state = State.IDLE
		return

	var direction = (player_target.global_position - global_position).normalized()
	var movement_speed = 25.0 + (stats.agi * 3.0)
	velocity = direction * movement_speed

func attack_state():
	velocity = Vector2.ZERO

# ----------------------------------------------------------------------------
# FUNGSI KOMBAT
# ----------------------------------------------------------------------------

func take_damage(amount: int):
	stats.hp -= amount
	print("Orc menerima ", amount, " damage! Sisa HP: ", stats.hp)
	
	if stats.hp <= 0:
		print("Orc dikalahkan!")
		LevelManager.gain_exp(50)
		queue_free()

# ----------------------------------------------------------------------------
# KONEKSI SINYAL
# ----------------------------------------------------------------------------

func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player"):
		player_target = body
		if current_state == State.IDLE:
			current_state = State.CHASE

func _on_detection_area_body_exited(body: Node2D):
	if body == player_target:
		player_target = null
		current_state = State.IDLE

func _on_attack_range_area_entered(area: Area2D):
	if current_state == State.CHASE and area.get_parent().is_in_group("player"):
		current_state = State.ATTACK

func _on_animation_finished():
	if current_state == State.ATTACK:
		attack_hitbox.disabled = true
		if is_instance_valid(player_target):
			current_state = State.CHASE
		else:
			current_state = State.IDLE

func _on_attack_hitbox_body_entered(body: Node2D):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(stats.atk)

# ----------------------------------------------------------------------------
# FUNGSI PENDUKUNG
# ----------------------------------------------------------------------------

func update_animation():
	var state_prefix = ""
	match current_state:
		State.IDLE:
			state_prefix = "idle"
		State.CHASE:
			state_prefix = "run"
		State.ATTACK:
			state_prefix = "attack"
			attack_hitbox.disabled = false

	var direction_suffix = ""
	var direction = (player_target.global_position - global_position if player_target else Vector2.DOWN).normalized()
	
	if abs(direction.x) > abs(direction.y):
		direction_suffix = "_right" if direction.x > 0 else "_left"
	else:
		direction_suffix = "_down" if direction.y > 0 else "_up"
		
	# MENGGABUNGKAN SEMUA BAGIAN MENJADI NAMA ANIMASI FINAL
	var final_animation_name = state_prefix + direction_suffix + "_orc"
	
	# Memainkan animasi hanya jika belum berjalan untuk mencegah stuttering
	if animated_sprite.animation != final_animation_name:
		animated_sprite.play(final_animation_name)
