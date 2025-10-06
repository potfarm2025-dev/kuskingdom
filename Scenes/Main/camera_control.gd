extends Camera2D

@export var min_zoom := 0.1
@export var max_zoom := 5.0
@export var zoom_factor := 0.1
@export var zoom_duration := 0.2

# State
var zoom_level: float = 1.0
var position_before_drag: Vector2
var position_before_drag2: Vector2
var dragging := false

# Touch points for mobile
var touch_points: Dictionary = {}

# ---------------- Input ----------------
func _unhandled_input(event: InputEvent) -> void:
	# --------- Touch / Mobile ---------
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

	# --------- Mouse / Keyboard ---------
	elif event.is_action_pressed("zoom_in"):
		_set_zoom_level(zoom_level + zoom_factor, get_global_mouse_position())
	elif event.is_action_pressed("zoom_out"):
		_set_zoom_level(zoom_level - zoom_factor, get_global_mouse_position())
	elif event.is_action_pressed("MOUSE_BUTTON_MIDLE"):
		# Only allow drag if player is MOVING
		if PlayerGlobal.player_current_state == PlayerGlobal.player_state.MOVING:
			dragging = true
			position_before_drag = event.global_position
			position_before_drag2 = global_position
	elif event.is_action_released("MOUSE_BUTTON_MIDLE"):
		dragging = false
	elif event is InputEventMouseMotion and dragging:
		if PlayerGlobal.player_current_state == PlayerGlobal.player_state.MOVING:
			global_position = position_before_drag2 + (position_before_drag - event.global_position) * (1 / zoom_level)

# ---------------- Touch Handlers ----------------
func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		touch_points[event.index] = event.position
	else:
		touch_points.erase(event.index)

func _handle_drag(event: InputEventScreenDrag) -> void:
	# Only allow camera movement if player is MOVING
	if PlayerGlobal.player_current_state != PlayerGlobal.player_state.MOVING:
		return

	if touch_points.size() == 1:
		# Single-finger drag
		global_position -= event.relative / zoom_level
		touch_points[event.index] = event.position
	elif touch_points.size() == 2:
		# Two-finger pinch & pan
		var pivot_index = 1 if event.index == 0 else 0
		var pivot_point: Vector2 = touch_points[pivot_index]
		var old_point: Vector2 = touch_points[event.index]
		var new_point: Vector2 = event.position

		# Pinch scale
		var old_vector: Vector2 = old_point - pivot_point
		var new_vector: Vector2 = new_point - pivot_point
		var delta_scale: float = new_vector.length() / old_vector.length()
		zoom_level *= delta_scale
		zoom_level = clamp(zoom_level, min_zoom, max_zoom)
		zoom = Vector2(zoom_level, zoom_level)

		# Update touch point
		touch_points[event.index] = new_point

		# Two-finger pan
		global_position -= event.relative / 2 * zoom_level

		print("Pinch detected! Zoom level:", zoom_level)

# ---------------- Zoom Helpers ----------------
func _set_zoom_level(level: float, focal_point: Vector2) -> void:
	var old_zoom = zoom_level
	zoom_level = clamp(level, min_zoom, max_zoom)

	# Zoom around focal point
	var offset = (focal_point - global_position) * (1 - old_zoom / zoom_level)
	global_position += offset
	zoom = Vector2(zoom_level, zoom_level)

# ---------------- Camera Limits ----------------
func apply_camera_limit(map_limits: Dictionary) -> void:
	limit_left = map_limits["limit_left"]
	limit_top = map_limits["limit_top"]
	limit_right = map_limits["limit_right"]
	limit_bottom = map_limits["limit_bottom"]
	global_position = map_limits["center"]
	min_zoom = map_limits["minimum_zoom"]
	print("Camera limits applied:", map_limits)
