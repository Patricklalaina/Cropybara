extends Marker2D

@onready var debug_visual: Node2D = Node2D.new()

func _ready() -> void:
	add_to_group("path_markers")
	
	if OS.is_debug_build():
		add_child(debug_visual)
		debug_visual.z_index = 10
		debug_visual.draw.connect(_draw_debug)
		debug_visual.queue_redraw()

func _draw_debug() -> void:
	"""Dessiner un cercle pour visualiser le marker en debug"""
	debug_visual.draw_circle(Vector2.ZERO, 10.0, Color.GREEN)
	debug_visual.draw_circle(Vector2.ZERO, 8.0, Color.DARK_GREEN)
	debug_visual.draw_line(Vector2(-15, 0), Vector2(15, 0), Color.WHITE, 2.0)
	debug_visual.draw_line(Vector2(0, -15), Vector2(0, 15), Color.WHITE, 2.0)
