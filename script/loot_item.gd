extends Area2D

var item_data : ItemData = null
var can_be_collected : bool = true 
var dropped_time : float = 0.0 # Waktu item ini jatuh (Unix Time)

@onready var sprite = $Sprite2D

func _ready():
	# Masukkan ke grup agar Player bisa mendata semua item sebelum pindah map
	add_to_group("loot_items")
	
	body_entered.connect(_on_body_entered)
	
	if item_data != null and item_data.icon != null:
		sprite.texture = item_data.icon
	
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1), 0.3).set_trans(Tween.TRANS_BACK)
	
	# Jika dropped_time belum diisi (baru spawn), set ke waktu sekarang
	if dropped_time == 0.0:
		dropped_time = Time.get_unix_time_from_system()
	
	setup_expiry_timer()

func setup_expiry_timer():
	# Hitung sisa umur
	var age = Time.get_unix_time_from_system() - dropped_time
	var time_left = 60.0 - age
	
	if time_left <= 0:
		queue_free() # Sudah kadaluarsa
		return

	var expiry_timer = get_tree().create_timer(time_left)
	expiry_timer.timeout.connect(func(): 
		if is_instance_valid(self): queue_free()
	)

func set_item(data: ItemData):
	item_data = data

func start_pickup_delay(duration: float):
	can_be_collected = false
	modulate.a = 0.5 
	if duration > 0:
		await get_tree().create_timer(duration).timeout
	can_be_collected = true
	modulate.a = 1.0

func _on_body_entered(body):
	if not can_be_collected: return
	if body.name == "Player" or body.is_in_group("player"):
		collect_item(body) 

func collect_item(collector):
	if item_data == null: return
	
	if "inventory" in collector:
		collector.inventory.add_item(item_data, 1)
		queue_free()
