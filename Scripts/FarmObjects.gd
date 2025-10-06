extends Node2D
class_name FarmObject

@export var object_id: String = ""
@export var tile_size: Vector2i = Vector2i(1, 1)
var root_tile: Vector2i = Vector2i.ZERO

func get_save_data() -> Dictionary:
	return {
		"id": object_id,
		"pos": [position.x, position.y],
		"root_tile": [int(root_tile.x), int(root_tile.y)],
		"tile_size": [int(tile_size.x), int(tile_size.y)]
	}

func load_from_data(data: Dictionary) -> void:
	object_id = str(data.get("id", object_id))
	var p = data.get("pos", [position.x, position.y])
	position = Vector2(float(p[0]), float(p[1]))
	var rt = data.get("root_tile", [int(root_tile.x), int(root_tile.y)])
	root_tile = Vector2i(int(rt[0]), int(rt[1]))
	var ts = data.get("tile_size", [int(tile_size.x), int(tile_size.y)])
	tile_size = Vector2i(int(ts[0]), int(ts[1]))
