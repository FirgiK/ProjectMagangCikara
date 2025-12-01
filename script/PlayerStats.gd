extends Resource
class_name PlayerStats

# --- BASE STATS (Level 1) ---
@export var max_hp : int = 100
@export var attack : int = 5
@export var defense : int = 1
@export var agility : int = 10     # Base Speed
@export var aspd : float = 1.0     # Base Anim Speed

# --- PROGRESSION ---
@export var level : int = 1
@export var current_exp : int = 0
@export var exp_to_next_level : int = 50

# --- FUNGSI HELPER ---
func get_speed() -> float:
	# Rumus: Base 50 + (Agi * 10)
	return 50.0 + (agility * 10.0)

func gain_exp(amount: int) -> bool:
	current_exp += amount
	var leveled_up = false
	
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level += 1
		grow_stats()
		leveled_up = true
		
	return leveled_up

func grow_stats():
	attack += 2
	defense += 1
	agility += 1
	max_hp += 20
	
	#Bungkus rumus matematika dengan int(...)
	exp_to_next_level = int(50 * pow(level, 2))
