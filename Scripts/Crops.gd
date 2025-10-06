extends Node2D
class_name Crop

# ----------------- Nodes -----------------
@onready var stage1: Sprite2D = $Stage1
@onready var stage2: Sprite2D = $Stage2
@onready var ready_stage: Sprite2D = $Ready
@onready var area2d: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

# ----------------- Exported -----------------
@export var growth_time: float = 5.0
@export var yield_item_id: String = ""
@export var min_yield: int = 1
@export var max_yield: int = 5

# ----------------- State -----------------
var current_stage: int = 0
var elapsed_time: float = 0.0
var is_harvested: bool = false

# ----------------- Save/Load -----------------
var object_id: String = ""
var root_tile: Vector2i = Vector2i.ZERO
var tile_size: Vector2i = Vector2i.ZERO

# ----------------- Ready -----------------
func _ready():
	area2d.monitoring = true
	collision_shape.disabled = false
	area2d.input_pickable = false  # initially not pickable

	if not area2d.is_connected("input_event", Callable(self, "_on_area_input_event")):
		area2d.connect("input_event", Callable(self, "_on_area_input_event"))

	_set_stage(current_stage)
	print_debug("Crop ready. Stage: %s, Harvested: %s" % [current_stage, is_harvested])

# ----------------- Mouse / Click -----------------
func _on_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print_debug("Click detected on crop. Player state:", PlayerGlobal.player_current_state)
		
		if PlayerGlobal.player_current_state != PlayerGlobal.player_state.HARVESTING:
			print_debug("❌ Cannot harvest: Player not in HARVESTING state")
			return

		if current_stage < 2:
			print_debug("❌ Cannot harvest: Crop not fully grown. Current stage:", current_stage)
			return

		if is_harvested:
			print_debug("❌ Cannot harvest: Crop already harvested")
			return

		print_debug("✅ Harvest conditions met. Harvesting now...")
		harvest_crop()

# ----------------- Harvest -----------------
func harvest_crop() -> void:
	is_harvested = true
	area2d.input_pickable = false
	collision_shape.disabled = true
	hide()

	# Give player items
	if yield_item_id != "":
		var item = ItemDatabase.get_item_by_id(yield_item_id)
		if item:
			var amount = randi() % (max_yield - min_yield + 1) + min_yield
			PlayerGlobal.add_to_inventory(item, amount)
			print_debug("Harvested crop! Gave player ", amount, "x ", item.id)
		else:
			print_debug("ERROR: Item with ID ", yield_item_id, " not found")
	else:
		print_debug("ERROR: yield_item_id not set for crop!")

	# Give XP
	var xp_amount = randi() % 11 + 5
	PlayerGlobal.addXP(xp_amount)
	print_debug("Gave player ", xp_amount, " XP for harvesting!")

	if FarmGlobal:
		FarmGlobal.remove_object(self)
	else:
		queue_free()

# ----------------- Growth -----------------
func _process(delta: float) -> void:
	if is_harvested or current_stage >= 2:
		return

	elapsed_time += delta
	while elapsed_time >= growth_time:
		elapsed_time -= growth_time
		current_stage += 1
		if current_stage > 2:
			current_stage = 2
		_set_stage(current_stage)
		print_debug("Crop grew. New stage:", current_stage)

# ----------------- Stage Handling -----------------
func _set_stage(stage: int) -> void:
	current_stage = stage
	match stage:
		0:
			stage1.visible = true
			stage2.visible = false
			ready_stage.visible = false
		1:
			stage1.visible = false
			stage2.visible = true
			ready_stage.visible = false
		2:
			stage1.visible = false
			stage2.visible = false
			ready_stage.visible = true

	area2d.input_pickable = (stage >= 2 and not is_harvested)
	print_debug("Set stage to", stage, "Input pickable:", area2d.input_pickable)

# ----------------- Debug Helper -----------------
func print_debug(varargs):
	var text = ""
	for a in varargs:
		text += str(a) + " "
	print("[Crop DEBUG]", text)
