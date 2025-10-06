extends Panel

signal button_pressed(item: Item)

var item_name: String
var item_icon: Texture2D
var item_resource: Item
var item_amount: int

@onready var button: Button = $Button
@onready var amount: Label = $MarginContainer2/Amount
@onready var icon: Button = $MarginContainer/Icon
@onready var name_2: Label = $Name/Name2

func _ready():
	icon.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_on_Button_pressed)
	update_ui()

func update_ui():
	if icon:
		icon.icon = item_icon
	if amount:
		amount.text = "x" + str(item_amount)
	if name_2:
		name_2.text = item_name

func _on_Button_pressed():
	if item_resource:
		emit_signal("button_pressed", item_resource)
