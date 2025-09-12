extends CharacterBody2D

@export var stats: StatResource
@export var base_speed: float = 100.0

enum State {IDLE, RUN, ATTACK}
var current_state: State = State.IDLE
var facing_direction: Vector2 = Vector2.DOWN

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D

func _ready():
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(_delta: float):
	match current_state:
		State.IDLE:
			idle_state()
		State.RUN:
			run_state()
		State.ATTACK:
			attack_state()
			
	move_and_slide()
	update_animation()

# ----------------------------------------------------------------------------
# LOGIKA STATE
# ----------------------------------------------------------------------------

func idle_state():
	velocity = Vector2.ZERO
	
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
	elif get_input_direction() != Vector2.ZERO:
		current_state = State.RUN

func run_state():
	if Input.is_action_just_pressed("attack"):
		current_state = State.ATTACK
		return

	var input_direction = get_input_direction()
	if input_direction == Vector2.ZERO:
		current_state = State.IDLE
		return
		
	var movement_speed = base_speed + (stats.agi * 5.0)
	velocity = input_direction.normalized() * movement_speed
	update_facing_direction(input_direction)

func attack_state():
	velocity = Vector2.ZERO
	# Aktifkan hitbox saat animasi serangan dimulai
	hitbox_collision.disabled = false

# ----------------------------------------------------------------------------
# FUNGSI KOMBAT & SINYAL
# ----------------------------------------------------------------------------

func take_damage(amount: int):
	stats.hp -= amount
	print("Player menerima ", amount, " damage! Sisa HP: ", stats.hp)
	
	if stats.hp <= 0:
		print("Player Kalah!")
		queue_free()
		
func _on_hitbox_area_entered(area: Area2D):
	# 'area' yang masuk adalah Hurtbox milik musuh.
	# Grup "enemy" dan skripnya ada di parent dari Hurtbox tersebut.
	var parent_body = area.get_parent()
	
	if parent_body.is_in_group("enemy") and parent_body.has_method("take_damage"):
		parent_body.take_damage(stats.atk)
		print("Player berhasil menyerang ", parent_body.name)
		

func _on_animation_finished():
	if current_state == State.ATTACK:
		# Nonaktifkan kembali hitbox setelah serangan selesai
		hitbox_collision.disabled = true
		current_state = State.IDLE

# ----------------------------------------------------------------------------
# FUNGSI PENDUKUNG
# ----------------------------------------------------------------------------

func get_input_direction() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

func update_facing_direction(direction: Vector2):
	if direction.x != 0:
		facing_direction = Vector2(direction.x, 0).normalized()
	elif direction.y != 0:
		facing_direction = Vector2(0, direction.y).normalized()

func update_animation():
	var state_prefix = ""
	match current_state:
		State.IDLE:
			state_prefix = "idle"
		State.RUN:
			state_prefix = "run"
		State.ATTACK:
			state_prefix = "attack"

	var direction_suffix = ""
	if facing_direction.y < 0:
		direction_suffix = "_up"
	elif facing_direction.y > 0:
		direction_suffix = "_down"
	elif facing_direction.x < 0:
		direction_suffix = "_left"
	elif facing_direction.x > 0:
		direction_suffix = "_right"
		
	animated_sprite.play(state_prefix + direction_suffix)
