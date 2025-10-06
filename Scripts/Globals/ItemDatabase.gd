extends Node
# Holds references to all available items in the game.
# This is the "single source of truth" for items.

var items: Array = []

func _ready() -> void:
	# Preload some example items
	items.append(preload("res://Scripts/Resources/HaloweenPlants/Skull.tres"))
	items.append(preload("res://Scripts/Resources/Animals/Pig.tres"))
	for item in items:
		print("📦 Loaded item:", item.id)

func get_item_by_id(id: String):
	# Finds an item resource by its ID string
	for item in items:
		if item.id == id:
			return item
	return null
