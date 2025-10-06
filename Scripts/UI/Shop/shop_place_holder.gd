extends Panel

var item_name: String
var item_icon: Texture2D
var item_resource: Resource
var item_price: int = 0

@onready var icon_button: Button = $MarginContainer/Icon
@onready var button: Button = $Button
@onready var item_name_label: Label = $Name/Name2
@onready var price: Label = $PriceContainer/Price

func _ready():
	if icon_button:
		icon_button.icon = item_icon
		item_name_label.text = item_name
		price.text = PlayerGlobal.format_money(item_price)
	else:
		print("Error: icon_button node not found!")

	button.text = "BUY"
	button.pressed.connect(func(): buy_item(1))

func buy_item(amount: int = 1) -> void:
	var total_cost = item_resource.value * amount
	if PlayerGlobal.money >= total_cost:
		PlayerGlobal.money -= total_cost
		PlayerGlobal.add_to_inventory(item_resource, amount)
		print("Purchased %d x %s for %d coins." % [amount, item_resource.id, total_cost])
		PlayerGlobal.emit_signal("money_changed", PlayerGlobal.money)
	else:
		print("Not enough money to buy %s!" % item_resource.id)

func update_labels() -> void:
	price.text = PlayerGlobal.format_money(item_resource.value)
