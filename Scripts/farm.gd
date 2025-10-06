extends Node2D
# Attach this to your Farm node that contains a child TileMapLayer named "Grid"

signal item_placed(item_id: String, pos: Vector2)
signal item_harvested(item_id: String, pos: Vector2)

@onready var grid: TileMapLayer = $Grid

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if UiGlobal.ui_open:
			return
		
		var hovered := get_viewport().gui_get_hovered_control()
		if hovered and hovered.is_in_group("ui_buttons"):
			return

		# ------------------- STATE MACHINE CHECK -------------------
		match PlayerGlobal.player_current_state:
			PlayerGlobal.player_state.MOVING:
				# Do nothing, can't place or harvest
				return
			PlayerGlobal.player_state.PLACING:
				_handle_placing()
			PlayerGlobal.player_state.HARVESTING:
				_handle_harvesting()

# ------------------- PLACING -------------------
func _handle_placing() -> void:
	if PlayerGlobal.in_hand == null:
		return

	var hand_item = PlayerGlobal.in_hand

	# Make sure we actually have one in inventory
	var has_item := false
	for inv_item in PlayerGlobal.inventory:
		if inv_item.id == hand_item.id and inv_item.quantity > 0:
			has_item = true
			break
	if not has_item:
		PlayerGlobal.clear_in_hand()
		return

	var mos_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var cell_clicked = grid.local_to_map(mos_pos)
	var world_pos = grid.map_to_local(cell_clicked)

	# Ensure tile space is free
	if not FarmGlobal.is_tile_free(cell_clicked, hand_item.tile_size):
		print("❌ Not enough free space")
		return

	# Instantiate
	if hand_item.scene == null:
		print("❌ Item has no scene:", hand_item.id)
		return

	var node = hand_item.scene.instantiate()
	if node is Node2D:
		# Configure object if it supports save/load
		if node.has_method("load_from_data") or node.has_method("get_save_data"):
			node.position = world_pos
			node.root_tile = cell_clicked
			node.tile_size = hand_item.tile_size
			node.object_id = hand_item.id
			add_child(node)
			FarmGlobal.register_object(node, cell_clicked, hand_item.tile_size)
		else:
			node.position = world_pos
			add_child(node)

	# Remove item from inventory
	PlayerGlobal.remove_from_inventory(hand_item.id, 1)
	emit_signal("item_placed", hand_item.id, world_pos)
	GlobalSave.save_game()

# ------------------- HARVESTING -------------------
func _handle_harvesting() -> void:
	var mos_pos = get_viewport().get_camera_2d().get_global_mouse_position()
	var clicked_pos = grid.local_to_map(mos_pos)
	
	# Check if any object occupies this tile
	for obj in FarmGlobal.placed_objects:
		if obj.has_method("get_save_data"):
			var save_data = obj.get_save_data()
			var root_tile = Vector2i(save_data["root_tile"][0], save_data["root_tile"][1])
			var size = Vector2i(save_data["tile_size"][0], save_data["tile_size"][1])
			# Check if clicked tile is inside object's tiles
			for x in range(size.x):
				for y in range(size.y):
					if clicked_pos == root_tile + Vector2i(x, y):
						# Remove object
						FarmGlobal.remove_object(obj)
						emit_signal("item_harvested", obj.object_id, obj.position)
						GlobalSave.save_game()
						return

# ------------------- CAMERA LIMITS -------------------
func get_map_limit() -> Dictionary:
	var map_position := grid.global_position
	var map_size := grid.get_used_rect().size
	var map_cell_size := grid.tile_set.tile_size
	
	var limit_right := (map_cell_size.x * map_size.x) - map_position.x
	var limit_bottom := (map_cell_size.y * map_size.y) - map_position.y
	
	var viewport := get_viewport_rect().size
	
	return {
		"limit_left": map_position.x,
		"limit_top": map_position.y,
		"limit_right": limit_right,
		"limit_bottom": limit_bottom,
		"center": Vector2(limit_right / 2, limit_bottom / 2),
		"minimum_zoom": viewport.x / limit_right
	}
