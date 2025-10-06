extends Node2D

@export var grid: TileMapLayer
@export var highlight_color: Color = Color(1, 0, 0, 0.3)

var hovered_cell: Vector2i = Vector2i(-999, -999)
var ghost_sprite: Sprite2D

@export var num1 : int 
@export var num2 : int

func _ready() -> void:
	ghost_sprite = Sprite2D.new()
	ghost_sprite.modulate = Color(1, 1, 1, 0.7)
	ghost_sprite.scale = Vector2(0.5, 0.5)
	add_child(ghost_sprite)

func _process(_delta: float) -> void:
	# Only show hover/ghost if in PLACING state and holding an item
	if PlayerGlobal.player_current_state != PlayerGlobal.player_state.PLACING or PlayerGlobal.in_hand == null:
		ghost_sprite.visible = false
		if hovered_cell != Vector2i(-999, -999):
			hovered_cell = Vector2i(-999, -999)
			queue_redraw()
		return

	var mos_pos = grid.get_local_mouse_position()

	# --- hover highlight ---
	var cell = grid.local_to_map(mos_pos)
	if cell != hovered_cell:
		hovered_cell = cell
		queue_redraw()

	# --- ghost sprite follow mouse ---
	if PlayerGlobal.in_hand.icon is Texture2D:
		ghost_sprite.texture = PlayerGlobal.in_hand.icon
		ghost_sprite.visible = true
		ghost_sprite.global_position = mos_pos + Vector2(num1, 25) # offset from cursor

func _draw() -> void:
	# Only draw highlight if in PLACING state and holding an item
	if PlayerGlobal.player_current_state != PlayerGlobal.player_state.PLACING or PlayerGlobal.in_hand == null:
		return

	if hovered_cell != Vector2i(-999, -999):
		var cell_size: Vector2 = grid.tile_set.tile_size
		var world_pos: Vector2 = grid.map_to_local(hovered_cell)
		world_pos -= cell_size * 0.5  

		draw_rect(Rect2(world_pos, cell_size), highlight_color, true)
