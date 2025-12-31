extends Resource
class_name PlayerStats

# --- KONFIGURASI BASE (Stat Awal) ---
@export var base_max_hp : int = 100
@export var base_def : int = 0
@export var base_atk : int = 5
@export var base_agi : int = 10    
@export var base_aspd : float = 1.0

# --- STATS AKUMULASI (Untuk stats yang pertumbuhannya Random) ---
# Kita butuh variabel ini agar nilai randomnya tersimpan permanen
@export var current_atk : int = 5 

# --- SISTEM ORGANIK (3 PILAR) ---
var proficiency = {
	"survival": { "level": 1, "xp": 0, "max_xp": 100 }, 
	"athletics": { "level": 1, "xp": 0, "max_xp": 30 }, 
	"combat": { "level": 1, "xp": 0, "max_xp": 40 }
}

# --- GETTERS ---

func get_max_hp() -> int:
	# Formula HP masih linear (per level +10)
	return base_max_hp + ((proficiency["survival"]["level"] - 1) * 10)

func get_def() -> int:
	return base_def + floor((proficiency["survival"]["level"] - 1) / 2.0)

func get_speed() -> float:
	var bonus_agi = (proficiency["athletics"]["level"] - 1)
	return 50.0 + ((base_agi + bonus_agi) * 10.0)

func get_atk() -> int:
	# PERUBAHAN: Tidak lagi pakai rumus level.
	# Kita ambil nilai yang sudah diakumulasi lewat RNG.
	# Safety check: jangan sampai current_atk lebih kecil dari base
	return maxi(current_atk, base_atk)

func get_aspd() -> float:
	var bonus_aspd = floor((proficiency["combat"]["level"] - 1) / 5.0) * 0.1
	return base_aspd + bonus_aspd

# --- LOGIKA LATIHAN ---

func train_athletics(distance: float):
	var xp_gain = int(distance / 100.0) 
	if xp_gain > 0:
		_add_xp("athletics", xp_gain)

func train_survival(damage_received: int):
	var xp_gain = int(damage_received * 0.5) 
	xp_gain = maxi(xp_gain, 1) 
	_add_xp("survival", xp_gain)

func train_combat():
	_add_xp("combat", 40)

# --- SISTEM LEVEL UP & RNG GROW ---

func _add_xp(type: String, amount: int):
	var skill = proficiency[type]
	skill["xp"] += amount
	
	while skill["xp"] >= skill["max_xp"]:
		skill["xp"] -= skill["max_xp"]
		skill["level"] += 1
		skill["max_xp"] = int(skill["max_xp"] * 1.2)
		
		# Panggil efek level up spesifik
		_on_skill_level_up(type, skill["level"])

func _on_skill_level_up(type: String, new_level: int):
	print("STAT UP! ", type.to_upper(), " Lv: ", new_level)
	
	# Jika yang naik Combat, acak pertumbuhan Attack
	if type == "combat":
		grow_attack_randomly()

func grow_attack_randomly():
	# RNG Logic:
	# 75% -> Naik 1
	# 15% -> Naik 2
	# 10% -> Naik 3
	
	var roll = randf() # Mengambil angka acak 0.0 sampai 1.0
	var bonus = 0
	
	if roll < 0.75:
		bonus = 1
	elif roll < 0.90:
		bonus = 2
	else:
		bonus = 3
		print("LUCKY!! Attack naik drastis (+3)!")
	
	current_atk += bonus
	print("Combat Up! Attack +", bonus, " (Total: ", current_atk, ")")
