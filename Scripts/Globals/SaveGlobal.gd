extends Node
# Handles saving and loading of game state
# - Saves player data, inventory, farm objects
# - Restores state on load

const SAVE_DIR := "user://saves/"
var loading_game: bool = false

func _ready() -> void:
	# Wait until items and farm are ready before loading
	call_deferred("_deferred_load_startup")
	print("SaveGlobal: ready and waiting for items/farm")

func _deferred_load_startup() -> void:
	# Keep retrying until database and farm are ready
	if ItemDatabase.items.size() == 0 or FarmGlobal.farm_scene == null:
		call_deferred("_deferred_load_startup")
		return
	load_game()

func _path_for(player_id: String) -> String:
	# Builds the save file path for a given player
	return SAVE_DIR + str(player_id) + ".json"

func _ensure_save_dir() -> void:
	# Make sure save directory exists
	var dir = DirAccess.open("user://")
	if not dir:
		print("SaveGlobal: failed to open user://")
		return
	if not dir.dir_exists("saves"):
		var err = dir.make_dir("saves")
		print("SaveGlobal: created saves dir, error code:", err)

func save_game() -> void:
	# Save player, inventory, and farm data to JSON
	print("SaveGlobal: saving game...")
	_ensure_save_dir()

	var save_data := {
		"player": {
			"money": PlayerGlobal.money,
			"bucks": PlayerGlobal.bucks,
			"level": PlayerGlobal.level,
			"xp": PlayerGlobal.xp,
			"xp_needed": PlayerGlobal.xp_needed
		},
		"inventory": [],
		"farm": [],
		"in_hand": null  # still saved but ignored on load
	}

	# Save inventory
	for inv in PlayerGlobal.inventory:
		save_data["inventory"].append({"id": inv.id, "quantity": int(inv.quantity)})

	# Save in-hand item (optional, can keep for analytics or future use)
	if PlayerGlobal.in_hand:
		save_data["in_hand"] = {"id": PlayerGlobal.in_hand.id, "quantity": PlayerGlobal.get_in_hand_quantity()}

	# Save farm
	for obj in FarmGlobal.placed_objects:
		if obj.has_method("get_save_data"):
			save_data["farm"].append(obj.get_save_data())

	var path = _path_for(PlayerGlobal.player_id)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		print("SaveGlobal: failed to open", path)
		return

	file.store_string(JSON.stringify(save_data))
	file.close()
	print("SaveGlobal: save complete")

func _exit_tree() -> void:
	# Autosave when closing game
	print("SaveGlobal: _exit_tree called, saving game automatically")
	save_game()

func load_game() -> void:
	if loading_game:
		return
	loading_game = true

	var player_id = PlayerGlobal.player_id
	var path = _path_for(player_id)
	if not FileAccess.file_exists(path):
		print("SaveGlobal: no save for", player_id)
		loading_game = false
		return

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("SaveGlobal: failed to open", path)
		loading_game = false
		return

	var text = file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		print("SaveGlobal: invalid save format")
		loading_game = false
		return

	# Reset old state
	FarmGlobal.clear_all()
	PlayerGlobal.clear_inventory()
	PlayerGlobal.clear_in_hand()  # start with empty hand

	# Restore player stats
	var p = parsed.get("player", {})
	PlayerGlobal.set_money(int(p.get("money", PlayerGlobal.money)))
	PlayerGlobal.set_bucks(int(p.get("bucks", PlayerGlobal.bucks)))
	PlayerGlobal.level = int(p.get("level", PlayerGlobal.level))
	PlayerGlobal.xp = int(p.get("xp", PlayerGlobal.xp))
	PlayerGlobal.xp_needed = int(p.get("xp_needed", PlayerGlobal.xp_needed))

	# Restore inventory
	for entry in parsed.get("inventory", []):
		var item_res = ItemDatabase.get_item_by_id(entry["id"])
		if item_res:
			var copy = item_res.duplicate()
			copy.quantity = int(entry.get("quantity", 1))
			PlayerGlobal.inventory.append(copy)
			PlayerGlobal.emit_signal("inventory_updated", copy)

	# --- DO NOT RESTORE IN-HAND ITEM ---
	# Player will start with empty hand

	# Restore farm objects
	for entry in parsed.get("farm", []):
		var item_res = ItemDatabase.get_item_by_id(entry["id"])
		if item_res and item_res.scene:
			var node = item_res.scene.instantiate()
			if FarmGlobal.farm_scene == null:
				FarmGlobal._find_farm_scene()

			if FarmGlobal.farm_scene:
				FarmGlobal.farm_scene.add_child(node)
			else:
				get_tree().get_root().add_child(node)

			if node.has_method("load_from_data"):
				node.load_from_data(entry)

			if node.has_method("get_save_data"):
				FarmGlobal.register_object(node, node.root_tile, node.tile_size)

	# --- NEW: Refresh UI by emitting signals ---
	PlayerGlobal.emit_signal("money_changed", PlayerGlobal.money)
	PlayerGlobal.emit_signal("bucks_changed", PlayerGlobal.bucks)
	PlayerGlobal.emit_signal("leveled_up", PlayerGlobal.level)
	PlayerGlobal.emit_signal("in_hand_changed", PlayerGlobal.in_hand)  # will be null, UI sees empty hand

	loading_game = false
