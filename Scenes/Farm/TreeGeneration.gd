extends Node2D

# ---------------- Config ---------------- #
@export var tile_size: int = 512
@export var grid_width: int = 64
@export var grid_height: int = 36
@export var scene_to_spawn: PackedScene
@export var empty_center_width: int = 10
@export var empty_center_height: int = 5

func _ready():
	spawn_outer_tiles_with_center()


func spawn_outer_tiles_with_center():
	if not scene_to_spawn:
		push_error("No scene assigned to spawn!")
		return

	var center_start_x = (grid_width - empty_center_width) / 2
	var center_end_x = center_start_x + empty_center_width
	var center_start_y = (grid_height - empty_center_height) / 2
	var center_end_y = center_start_y + empty_center_height

	for x in range(grid_width):
		for y in range(grid_height):
			# Skip the central empty area
			if x >= center_start_x and x < center_end_x and y >= center_start_y and y < center_end_y:
				continue

			# Spawn outside the center
			var instance = scene_to_spawn.instantiate()
			instance.position = Vector2(x * tile_size + tile_size/2, y * tile_size + tile_size/2)
			add_child(instance)
