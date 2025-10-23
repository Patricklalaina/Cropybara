extends Node2D

func _draw() -> void:
	var parent = get_parent()
	if parent and parent.has_method("_draw_vision_cone"):
		parent._draw_vision_cone()
