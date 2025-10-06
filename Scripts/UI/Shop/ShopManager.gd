extends Control

@onready var Main_Shop_Container: GridContainer  = $Main_Shop/Main_Panel/ScrollContainer/MarginContainer/GridContainer
@onready var Seeds_Shop_Container: GridContainer = $Seeds_Shop/Seeds_Panel/MarginContainer/ScrollContainer/GridContainer
@onready var Event_Shop_Container: GridContainer = $Event_Seed_Shop/Event_Seeds_Panel/MarginContainer/ScrollContainer/GridContainer
@onready var Decoration_Shop_Container: GridContainer = $Decoration_Shop/Decoration_Shop_Panel/MarginContainer/ScrollContainer/GridContainer


var shop_place_holder = preload("res://Scenes/UI/ShopPlaceHolder.tscn")


func _ready() -> void:
	add_items()

func add_items() -> void:
	# Loop through database and sort items
	for item in ItemDatabase.items:
		var shop_entry = shop_place_holder.instantiate()
		shop_entry.item_name     = item.id
		shop_entry.item_icon     = item.icon
		shop_entry.item_resource = item
		shop_entry.item_price    = item.value

		# Add to correct container based on shop_space
		match item.shop_space:
			Item.ShopCategory.MAINSHOP:
				Main_Shop_Container.add_child(shop_entry)
			Item.ShopCategory.SEEDS:
				Seeds_Shop_Container.add_child(shop_entry)
			Item.ShopCategory.EVENT:
				Event_Shop_Container.add_child(shop_entry)
			Item.ShopCategory.DECORATION:
				Decoration_Shop_Container.add_child(shop_entry)
			_:
				push_warning("Item %s has no valid shop space!" % item.id)
