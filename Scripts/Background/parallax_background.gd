extends ParallaxBackground

@export var scroll_speed: Vector2 = Vector2(100, 0) # negative X moves left

func _process(delta: float) -> void:
	scroll_offset += scroll_speed * delta 
