extends Control

@onready var inventory_grid: GridContainer = $MarginContainer2/ScrollContainer/GridContainer
var InventoryPlaceholderScene: PackedScene = preload("res://Scenes/UI/InventoryPlaceHolder.tscn")

# Signal emitted when an item is picked from the inventory
signal item_picked(item: Item)

func _ready():
	# Connect to PlayerGlobal inventory updates
	PlayerGlobal.inventory_updated.connect(update_inventory)

func update_inventory(item: Item) -> void:
	# Update an existing placeholder if it matches the item
	for child in inventory_grid.get_children():
		if child.item_resource == item:
			if item.quantity <= 0:
				child.queue_free()
			else:
				child.item_amount = item.quantity
				child.update_ui()
			return

	# Otherwise, add a new placeholder
	if item.quantity > 0:
		var placeholder = InventoryPlaceholderScene.instantiate()
		placeholder.item_name = item.id
		placeholder.item_icon = item.icon
		placeholder.item_resource = item
		placeholder.item_amount = item.quantity
		placeholder.update_ui()
		inventory_grid.add_child(placeholder)
		
		# Connect placeholder button → when clicked, handle pick
		placeholder.button_pressed.connect(_on_placeholder_button_pressed)

func _on_placeholder_button_pressed(item: Item) -> void:
	emit_signal("item_picked", item)
	
	# ✅ Update player hand & state directly
	PlayerGlobal.set_hand(item)
