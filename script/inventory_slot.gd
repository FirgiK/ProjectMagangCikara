extends PanelContainer

signal slot_clicked(slot_node, item_data, click_type)

@onready var icon = $Icon
@onready var quantity_label = $Quantity

var my_item_data : ItemData

func _ready():
	gui_input.connect(_on_gui_input)

func set_slot_data(item_dict: Dictionary):
	my_item_data = item_dict["data"]
	var qty = item_dict["quantity"]
	
	icon.texture = my_item_data.icon
	

	if my_item_data.description != "":
		tooltip_text = "%s\n%s" % [my_item_data.name, my_item_data.description]
	else:
		tooltip_text = my_item_data.name
	
	if qty > 1:
		quantity_label.text = str(qty)
		quantity_label.visible = true
	else:
		quantity_label.visible = false

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			slot_clicked.emit(self, my_item_data, 0)
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			slot_clicked.emit(self, my_item_data, 1)
