extends Node2D

func _ready():
	$CameraControl.apply_camera_limit($Farm.get_map_limit())
