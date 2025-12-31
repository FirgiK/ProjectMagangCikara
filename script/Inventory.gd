extends Node
class_name Inventory

signal inventory_updated

@export var max_slots : int = 20

#  Struktur data kita adalah Array of Dictionary
var items : Array[Dictionary] = [] 

func add_item(item_data: ItemData, amount: int = 1):
	# LOGIKA STACK: Cek berdasarkan NAMA agar deteksi duplikat akurat
	if item_data.stackable:
		for slot in items:
			if slot["data"].name == item_data.name:
				slot["quantity"] += amount
				inventory_updated.emit()
				print("STACK: %s +%d" % [item_data.name, amount])
				return

	# LOGIKA NEW SLOT
	if items.size() < max_slots:
		items.append({ "data": item_data, "quantity": amount })
		inventory_updated.emit()
	else:
		print("TAS PENUH")

# FUNGSI BARU: Menghapus Item dari Dictionary
func remove_item(item_data: ItemData, amount: int = 1):
	for i in range(items.size()):
		# Kita bandingkan Resource atau Nama
		if items[i]["data"] == item_data:
			items[i]["quantity"] -= amount
			
			if items[i]["quantity"] <= 0:
				items.remove_at(i)
			
			inventory_updated.emit()
			return
