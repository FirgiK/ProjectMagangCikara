extends CharacterBody2D

@export var stats : PlayerStats 
@export var friction : float = 0.2
@export var acceleration : float = 0.2

var current_health : int
var state = MOVE
var anim_suffix : String = "down"
var distance_accumulator : float = 0.0
var active_buffs : Array = [] 

enum { MOVE, ATTACK, HURT, DEATH }

@onready var anim = $AnimatedSprite2D
@onready var weapon_pivot = $WeaponPivot
@onready var sword_hitbox_shape = $WeaponPivot/SwordHitbox/CollisionShape2D
@onready var sword_hitbox = $WeaponPivot/SwordHitbox
@onready var gui = $GUI 
@onready var inventory = $Inventory

func _ready():
	y_sort_enabled = true
	
	if stats == null: stats = PlayerStats.new()
	
	# 1. RESTORE STATS LEVELING
	if not Global.saved_stats.is_empty():
		if "current_atk" in stats: stats.current_atk = Global.saved_stats["atk"]
		if "base_def" in stats: stats.base_def = Global.saved_stats["def"]
		if "base_agi" in stats: stats.base_agi = Global.saved_stats["agi"]
	
	# 2. RESTORE HP
	if Global.stored_hp > 0:
		current_health = Global.stored_hp
		Global.stored_hp = -1
	else:
		current_health = stats.get_max_hp()
	
	# 3. SETUP GUI & INVENTORY
	if gui:
		gui.player_stats = stats
		gui.update_health(current_health, stats.get_max_hp())
		if inventory:
			inventory.inventory_updated.connect(func(): gui.update_inventory_ui(inventory, self))
			gui.update_inventory_ui(inventory, self)
			
			if Global.saved_inventory.size() > 0:
				inventory.items = Global.saved_inventory.duplicate(true)
				Global.saved_inventory.clear() 
				gui.update_inventory_ui(inventory, self)
	
	# 4. RESTORE ACTIVE BUFFS (PERSISTENCE LOGIC)
	# Kita pasang ulang buff yang tersimpan dari scene sebelumnya
	if Global.saved_buffs.size() > 0:
		for buff in Global.saved_buffs:
			# Pasang buff dengan SISA WAKTU (time_left), bukan durasi awal
			apply_temporary_buff(buff["type"], buff["amount"], buff["time_left"])
		Global.saved_buffs.clear() # Bersihkan setelah dipakai
	
	# Signal Connections
	if !anim.frame_changed.is_connected(_on_frame_changed): anim.frame_changed.connect(_on_frame_changed)
	if !anim.animation_finished.is_connected(_on_animation_finished): anim.animation_finished.connect(_on_animation_finished)
	if !sword_hitbox.body_entered.is_connected(_on_sword_hit_enemy): sword_hitbox.body_entered.connect(_on_sword_hit_enemy)

	call_deferred("setup_camera_limits")

	await get_tree().process_frame
	if Global.next_spawn_pos != null:
		global_position = Global.next_spawn_pos
		Global.next_spawn_pos = null

	restore_floor_loot()
	check_corpse_loot() 

# --- TRANSITION LOGIC ---
func save_data_for_transition():
	print("Menyimpan data Player (Stats, Inventory, Buffs)...")
	
	# A. SIMPAN BUFFS (Serialize)
	Global.saved_buffs.clear()
	for buff in active_buffs:
		if is_instance_valid(buff["timer"]):
			var time_remain = buff["timer"].time_left
			# Hanya simpan jika waktu masih ada (> 0.1 detik)
			if time_remain > 0.1:
				Global.saved_buffs.append({
					"type": buff["type"],
					"amount": buff["amount"],
					"time_left": time_remain
				})
	
	# B. BERSIHKAN BUFF (Agar stat yang disimpan di bawah adalah stat murni/base)
	clear_all_buffs()
	
	# C. SIMPAN DATA LAIN
	Global.stored_hp = current_health
	Global.saved_stats = { "atk": stats.current_atk, "def": stats.base_def, "agi": stats.base_agi }
	
	if inventory:
		Global.saved_inventory = inventory.items.duplicate(true)
	
	save_floor_loot()

func save_floor_loot():
	var current_scene = get_tree().current_scene.scene_file_path
	var floor_items = get_tree().get_nodes_in_group("loot_items")
	var items_data_list = []
	for item in floor_items:
		if (Time.get_unix_time_from_system() - item.dropped_time) < 60.0:
			items_data_list.append({
				"item_data": item.item_data,
				"position": item.global_position,
				"dropped_time": item.dropped_time
			})
	Global.scene_floor_loot[current_scene] = items_data_list

func restore_floor_loot():
	var current_scene = get_tree().current_scene.scene_file_path
	if Global.scene_floor_loot.has(current_scene):
		var saved_items = Global.scene_floor_loot[current_scene]
		var loot_scene = load("res://Scene/loot_item.tscn")
		for info in saved_items:
			if (Time.get_unix_time_from_system() - info["dropped_time"]) >= 60.0: continue
			if loot_scene:
				var drop = loot_scene.instantiate()
				drop.global_position = info["position"]
				drop.set_item(info["item_data"])
				drop.dropped_time = info["dropped_time"]
				get_parent().call_deferred("add_child", drop)
		Global.scene_floor_loot.erase(current_scene)

func check_corpse_loot():
	if Global.grave_loot.size() > 0 and Global.grave_scene_path == get_tree().current_scene.scene_file_path:
		var loot_scene = load("res://Scene/loot_item.tscn")
		var current_time = Time.get_unix_time_from_system()
		for info in Global.grave_loot:
			var time_elapsed = current_time - info["timestamp"]
			if time_elapsed >= 60.0: continue 
			if loot_scene:
				var drop = loot_scene.instantiate()
				drop.global_position = info["position"]
				drop.set_item(info["item_data"])
				drop.dropped_time = info["timestamp"]
				get_parent().call_deferred("add_child", drop)
				await drop.tree_entered
				var remaining_pickup_delay = max(0.0, 10.0 - time_elapsed)
				drop.start_pickup_delay(remaining_pickup_delay)
		Global.grave_loot.clear()
		Global.grave_scene_path = ""

func setup_camera_limits():
	var limit_box = get_tree().get_first_node_in_group("bounds")
	var camera = get_node_or_null("Camera2D")
	if limit_box and camera:
		var limit_rect = limit_box.get_global_rect()
		camera.limit_left = int(limit_rect.position.x)
		camera.limit_top = int(limit_rect.position.y)
		camera.limit_right = int(limit_rect.position.x + limit_rect.size.x)
		camera.limit_bottom = int(limit_rect.position.y + limit_rect.size.y)

func _physics_process(delta):
	match state:
		MOVE: move_state(delta)
		HURT: move_state(delta) 
		ATTACK: attack_state()
		DEATH: velocity = Vector2.ZERO

func move_state(delta):
	var input_vector = Input.get_vector("left", "right", "up", "down")
	if input_vector != Vector2.ZERO:
		velocity = velocity.lerp(input_vector * stats.get_speed(), acceleration)
		weapon_pivot.rotation = input_vector.angle() - PI/2
		distance_accumulator += velocity.length() * delta
		if distance_accumulator >= 100.0:
			stats.train_athletics(distance_accumulator)
			distance_accumulator = 0.0
		if abs(input_vector.x) > abs(input_vector.y):
			anim_suffix = "side"
			anim.flip_h = (input_vector.x > 0)
		else:
			anim_suffix = "down" if input_vector.y > 0 else "up"
			anim.flip_h = false
		play_anim("run" if state != HURT else "hurt")
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
		play_anim("idle" if state != HURT else "hurt")
	move_and_slide()
	if Input.is_action_just_pressed("attack") and state != HURT: state = ATTACK

func attack_state():
	velocity = Vector2.ZERO
	play_anim("attack")
	anim.speed_scale = stats.get_aspd()

func play_anim(action_name: String):
	var full_name = action_name + "_" + anim_suffix
	if action_name == "death": full_name = "death"
	if anim.sprite_frames.has_animation(full_name):
		if anim.animation != full_name: anim.play(full_name)
	elif anim.sprite_frames.has_animation(action_name):
		if anim.animation != action_name: anim.play(action_name)

func _on_frame_changed():
	if state == ATTACK:
		var active = (anim.frame >= 3 and anim.frame <= 6)
		sword_hitbox_shape.set_deferred("disabled", !active)
	else:
		sword_hitbox_shape.set_deferred("disabled", true)

func _on_animation_finished():
	if state == ATTACK:
		state = MOVE
		sword_hitbox_shape.set_deferred("disabled", true)
		anim.speed_scale = 1.0
	elif state == HURT:
		state = MOVE
		modulate = Color.WHITE
	elif state == DEATH:
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://Scene/Maps/surface.tscn")

func _on_sword_hit_enemy(body):
	if body.has_method("take_damage"):
		body.take_damage(stats.get_atk(), self)
		stats.train_combat()

func take_damage(amount, _enemy_pos):
	if state == DEATH: return
	var actual_damage = max(1, amount - stats.get_def())
	current_health -= actual_damage
	stats.train_survival(actual_damage)
	if gui: gui.update_health(current_health, stats.get_max_hp())
	if current_health <= 0: die()
	else:
		state = HURT
		play_anim("hurt")
		modulate = Color(1, 0, 0)
		var t = create_tween()
		t.tween_property(self, "modulate", Color.WHITE, 0.4)

func die():
	print("PLAYER MATI - Drop item & Clear buffs")
	
	# MATI = Buff Hilang (Tidak disimpan ke Global)
	clear_all_buffs()
	
	Global.saved_stats = { "atk": stats.current_atk, "def": stats.base_def, "agi": stats.base_agi }
	Global.grave_scene_path = get_tree().current_scene.scene_file_path
	
	# Kosongkan saved_buffs dan saved_inventory agar start fresh saat respawn
	Global.saved_buffs.clear()
	Global.saved_inventory.clear()
	
	var death_time = Time.get_unix_time_from_system()
	var loot_scene = load("res://Scene/loot_item.tscn")
	for slot in inventory.items:
		var data = slot["data"]
		var qty = slot["quantity"]
		for i in range(qty):
			var spread = Vector2(randf_range(-50, 50), randf_range(-50, 50))
			var final_pos = global_position + spread
			if loot_scene:
				var drop = loot_scene.instantiate()
				drop.global_position = final_pos
				drop.set_item(data)
				drop.dropped_time = death_time
				get_parent().call_deferred("add_child", drop)
			Global.grave_loot.append({ "item_data": data, "position": final_pos, "timestamp": death_time })
	
	inventory.items.clear()
	if gui: gui.update_inventory_ui(inventory, self)
	
	state = DEATH
	$CollisionShape2D.set_deferred("disabled", true)
	$WeaponPivot/SwordHitbox/CollisionShape2D.set_deferred("disabled", true)
	modulate = Color.WHITE
	anim.play("death")

# --- BUFF SYSTEM ---
func apply_temporary_buff(stat_type: String, amount: int, duration: float):
	match stat_type:
		"atk": stats.current_atk += amount
		"def": stats.base_def += amount
		"spd": stats.base_agi += amount
	update_stats_ui()
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.autostart = true
	add_child(timer)
	var buff_info = {"timer": timer, "type": stat_type, "amount": amount}
	active_buffs.append(buff_info)
	timer.timeout.connect(func(): _remove_buff(buff_info))

func _remove_buff(buff_info):
	if not buff_info in active_buffs: return
	match buff_info["type"]:
		"atk": stats.current_atk -= buff_info["amount"]
		"def": stats.base_def -= buff_info["amount"]
		"spd": stats.base_agi -= buff_info["amount"]
	update_stats_ui()
	if is_instance_valid(buff_info["timer"]): buff_info["timer"].queue_free()
	active_buffs.erase(buff_info)

func clear_all_buffs():
	for i in range(active_buffs.size() - 1, -1, -1):
		_remove_buff(active_buffs[i])

func heal_player(amount: int):
	current_health = min(current_health + amount, stats.get_max_hp())
	if gui: gui.update_health(current_health, stats.get_max_hp())

func update_stats_ui():
	if gui: gui.refresh_stats_view()

func use_item(item):
	item.use(self)
	inventory.remove_item(item, 1)

func drop_item(item):
	var loot_scene = load("res://Scene/loot_item.tscn")
	if loot_scene:
		var drop = loot_scene.instantiate()
		drop.global_position = global_position + Vector2(randf_range(-20,20), randf_range(-20,20))
		drop.set_item(item)
		drop.dropped_time = Time.get_unix_time_from_system()
		get_parent().add_child(drop)
		drop.start_pickup_delay(10.0)
	inventory.remove_item(item, 1)

func destroy_item(item):
	inventory.remove_item(item, 1)
