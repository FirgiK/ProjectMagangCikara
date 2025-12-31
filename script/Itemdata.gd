extends Resource
class_name ItemData

enum Type { MATERIAL, CONSUMABLE, COMPONENT, FOOD, WASTE, QUEST }

@export_category("General Info")
@export var type : Type = Type.CONSUMABLE
@export var name : String = "Item Name"
@export_multiline var description : String = "Deskripsi item."
@export var icon : Texture2D
@export var stackable : bool = true

@export_category("Consumable Stats")
@export var heal_amount : int = 0
@export var atk_bonus : int = 0
@export var def_bonus : int = 0
@export var speed_bonus : int = 0
@export var duration : float = 0.0 

func use(target) -> void:
	if not "stats" in target: return
	
	if heal_amount > 0:
		target.heal_player(heal_amount)

	# Delegasikan logika buff ke Player untuk menghindari crash
	if duration > 0:
		if atk_bonus > 0: apply_buff(target, "atk", atk_bonus)
		if def_bonus > 0: apply_buff(target, "def", def_bonus)
		if speed_bonus > 0: apply_buff(target, "spd", speed_bonus)
	else:
		# Jika buff permanen (instant use tanpa durasi)
		apply_instant(target)

func apply_buff(target, stat_type: String, amount: int):
	# Cek apakah target punya sistem buff manager baru
	if target.has_method("apply_temporary_buff"):
		target.apply_temporary_buff(stat_type, amount, duration)
	else:
		print("Warning: Target tidak mendukung Buff System")

func apply_instant(target):
	var s = target.stats
	if atk_bonus > 0: s.current_atk += atk_bonus
	if def_bonus > 0: s.base_def += def_bonus
	if speed_bonus > 0: s.base_agi += speed_bonus
	target.update_stats_ui()
