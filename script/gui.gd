extends CanvasLayer

@onready var hp_bar = $HUD/VBoxContainer/HPBar
@onready var hp_text = $HUD/VBoxContainer/HPBar/NumberLabel
@onready var item_grid = $InventoryDock/ScrollContainer/ItemGrid
@onready var popup = $PopupMenu 
@onready var menu_root = $StatsMenu

# Stats Labels
@onready var lbl_hp = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/GridStats/Lbl_HP
@onready var lbl_atk = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/GridStats/Lbl_Atk
@onready var lbl_def = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/GridStats/Lbl_Def
@onready var lbl_spd = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/GridStats/Lbl_Spd

# Proficiency Labels
@onready var lbl_ath = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/ProficiencyBox/BoxAth/LabelAth
@onready var bar_ath = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/ProficiencyBox/BoxAth/BarAth
@onready var txt_ath = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/ProficiencyBox/BoxAth/BarAth/NumberLabel 
@onready var lbl_surv = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/ProficiencyBox/BoxSurv/LabelSurv
@onready var bar_surv = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/ProficiencyBox/BoxSurv/BarSurv
@onready var txt_surv = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/ProficiencyBox/BoxSurv/BarSurv/NumberLabel 
@onready var lbl_comb = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/ProficiencyBox/BoxComb/LabelComb
@onready var bar_comb = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/ProficiencyBox/BoxComb/BarComb
@onready var txt_comb = $StatsMenu/Background/MarginContainer/HBoxContainer/RightCol/ProficiencyBox/BoxComb/BarComb/NumberLabel 

var slot_scene = preload("res://Scene/inventory_slot.tscn")
var player_stats : PlayerStats
var player_ref = null
var selected_item : ItemData = null

func _ready():
	menu_root.visible = false
	if item_grid:
		item_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item_grid.size_flags_vertical = Control.SIZE_EXPAND
	if popup:
		popup.id_pressed.connect(_on_popup_action)
	clear_inventory_ui()

func _input(event):
	if event.is_action_pressed("ui_focus_next"): 
		toggle_menu()

func update_inventory_ui(inventory_instance: Inventory, player_instance):
	player_ref = player_instance
	clear_inventory_ui()
	
	for item_dict in inventory_instance.items:
		var new_slot = slot_scene.instantiate()
		item_grid.add_child(new_slot)
		new_slot.set_slot_data(item_dict)
		new_slot.slot_clicked.connect(_on_slot_clicked)

func clear_inventory_ui():
	for child in item_grid.get_children():
		child.queue_free()

func _on_slot_clicked(slot_node: Control, item_data: ItemData, click_type: int):
	selected_item = item_data
	
	if click_type == 0: # Double Click
		if item_data.type == ItemData.Type.CONSUMABLE or item_data.type == ItemData.Type.FOOD:
			_execute_action(0)
	
	elif click_type == 1: # Right Click
		popup.clear()
		if item_data.type == ItemData.Type.CONSUMABLE or item_data.type == ItemData.Type.FOOD:
			popup.add_item("Use", 0)
		popup.add_item("Drop", 1)
		popup.add_item("Destroy", 2)
		
		var slot_pos = slot_node.get_global_rect().position
		var slot_w = slot_node.get_global_rect().size.x
		popup.position = Vector2(slot_pos.x + slot_w, slot_pos.y)
		popup.reset_size()
		popup.popup()

func _on_popup_action(id):
	_execute_action(id)

func _execute_action(id):
	if !player_ref or !selected_item: return
	match id:
		0: player_ref.use_item(selected_item)
		1: player_ref.drop_item(selected_item)
		2: player_ref.destroy_item(selected_item)

func update_health(current, max_hp):
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current
		if hp_text: hp_text.text = "%d / %d" % [current, max_hp]

func toggle_menu():
	menu_root.visible = !menu_root.visible
	if menu_root.visible:
		refresh_stats_view()
		get_tree().paused = true
	else:
		get_tree().paused = false

func update_stats(_proficiency_data):
	if menu_root.visible: refresh_stats_view()

func refresh_stats_view():
	if player_stats == null: return
	lbl_hp.text = "HP: %d" % player_stats.get_max_hp()
	lbl_atk.text = "ATK: %d" % player_stats.get_atk()
	lbl_def.text = "DEF: %d" % player_stats.get_def()
	lbl_spd.text = "SPD: %d" % player_stats.get_speed()
	update_prof_ui(player_stats.proficiency["athletics"], lbl_ath, bar_ath, txt_ath, "Athletics")
	update_prof_ui(player_stats.proficiency["survival"], lbl_surv, bar_surv, txt_surv, "Survival")
	update_prof_ui(player_stats.proficiency["combat"], lbl_comb, bar_comb, txt_comb, "Combat")

func update_prof_ui(data, label, bar, text_label, title):
	label.text = "%s: Lv %d" % [title, data.level]
	bar.max_value = data.max_xp
	bar.value = data.xp
	if text_label: text_label.text = "%d / %d XP" % [data.xp, data.max_xp]
