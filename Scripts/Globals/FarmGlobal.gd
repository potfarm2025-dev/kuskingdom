extends Node
# Handles everything related to the farm world:
# - Tracking placed objects
# - Managing which tiles are occupied/free
# - Registering and removing farm objects

var farm_scene: Node = null
var placed_objects: Array = [] # All placed objects in the farm
var occupied_tiles: Dictionary = {} # Maps Vector2i -> true if occupied

func _ready() -> void:
	# Wait until the scene tree is ready, then look for the farm node
	call_deferred("_find_farm_scene")

func _find_farm_scene() -> void:
	# Finds and stores reference to the Farm node in the current scene
	if get_tree().current_scene and get_tree().current_scene.has_node("Farm"):
		farm_scene = get_tree().current_scene.get_node("Farm")
		print("FarmGlobal: farm_scene set")
	else:
		print("FarmGlobal: Farm node not found in current scene")

# --- TILE MANAGEMENT ---
func is_tile_free(root_tile: Vector2i, size: Vector2i) -> bool:
	# Returns true if every tile in the rectangle starting at root_tile of given size is free
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var check = root_tile + Vector2i(x, y)
			if occupied_tiles.has(check):
				return false
	return true

func occupy_tiles(root_tile: Vector2i, size: Vector2i) -> void:
	# Marks a set of tiles as occupied
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var t = root_tile + Vector2i(x, y)
			occupied_tiles[t] = true

func free_tiles(root_tile: Vector2i, size: Vector2i) -> void:
	# Frees up a set of tiles so something else can be placed there
	for x in range(int(size.x)):
		for y in range(int(size.y)):
			var t = root_tile + Vector2i(x, y)
			occupied_tiles.erase(t)

func clear_occupied(root_tile: Vector2i, tile_size: Vector2i) -> void:
	# Same as free_tiles, but uses a different iteration style
	for x in range(root_tile.x, root_tile.x + tile_size.x):
		for y in range(root_tile.y, root_tile.y + tile_size.y):
			var key = Vector2i(x, y)
			if key in occupied_tiles:
				occupied_tiles.erase(key)

# --- OBJECT REGISTRATION ---
func register_object(obj: Node, root_tile: Vector2i, size: Vector2i) -> void:
	# Adds an object to the farm tracking list and marks its tiles as occupied
	if obj not in placed_objects:
		placed_objects.append(obj)
	occupy_tiles(root_tile, size)

func unregister_object(obj: Node) -> void:
	# Removes an object from placed_objects and frees up its tiles
	if obj in placed_objects:
		# Ask the object for its save data to figure out what tiles it occupies
		if obj.has_method("get_save_data"):
			var d = obj.get_save_data()
			if d.has("root_tile") and d.has("tile_size"):
				var rt = d["root_tile"]
				var ts = d["tile_size"]

				var rtv = Vector2i(0, 0)
				if rt is Array and rt.size() >= 2:
					rtv = Vector2i(int(rt[0]), int(rt[1]))

				var tsv = Vector2i(1, 1)
				if ts is Array and ts.size() >= 2:
					tsv = Vector2i(int(ts[0]), int(ts[1]))

				free_tiles(rtv, tsv)

		placed_objects.erase(obj)

# --- REMOVE OBJECT (e.g. harvest) ---
func remove_object(node: Node2D) -> void:
	# Safely remove an object from the farm and scene
	if not node:
		return

	# Free tiles used by the object
	if "root_tile" in node and "tile_size" in node:
		free_tiles(node.root_tile, node.tile_size)
	elif node.has_method("get_save_data"):
		var data = node.get_save_data()
		if data.has("root_tile") and data.has("tile_size"):
			var rt = Vector2i(data["root_tile"][0], data["root_tile"][1])
			var ts = Vector2i(data["tile_size"][0], data["tile_size"][1])
			free_tiles(rt, ts)

	# Remove object from tracking
	if node in placed_objects:
		placed_objects.erase(node)

	# Finally remove the node from the scene
	node.queue_free()

# --- CLEAR ALL OBJECTS (reset or load new save) ---
func clear_all() -> void:
	for obj in placed_objects.duplicate():
		remove_object(obj)
