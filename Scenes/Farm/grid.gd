extends TileMapLayer

@export var tiles_x := 60 
@export var tiles_y := 40
@export var ground_id := 13  # your grass tile ID

func _ready() -> void:
	for x in tiles_x:
		for y in tiles_y:
			set_cell(Vector2i(x, y), ground_id, Vector2i.ZERO)
