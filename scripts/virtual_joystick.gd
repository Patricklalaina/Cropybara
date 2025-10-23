extends Control

@onready var out: Sprite2D = $out
@onready var inside: Sprite2D = $out/inside

@export var max_distance: float = 100.0  
@export var return_speed: float = 10.0   

var is_pressed: bool = false
var touch_index: int = -1
var center_position: Vector2
var current_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	if out:
		center_position = out.position
	else:
		push_error("Sprite2D 'out' introuvable!")
	
	print("Joystick virtuel initialise")

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

# === GESTION TACTILE (Android) ===

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var touch_pos = event.position
		if _is_in_joystick_area(touch_pos):
			if touch_index == -1:
				is_pressed = true
				touch_index = event.index
				_update_joystick(touch_pos)
				get_viewport().set_input_as_handled()
	else:
		if event.index == touch_index:
			is_pressed = false
			touch_index = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if is_pressed and event.index == touch_index:
		_update_joystick(event.position)
		get_viewport().set_input_as_handled()

# === GESTION SOURIS (PC - pour test) ===

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_pos = event.position
			if _is_in_joystick_area(mouse_pos):
				is_pressed = true
				_update_joystick(mouse_pos)
				get_viewport().set_input_as_handled()
		else:
			is_pressed = false

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if is_pressed:
		_update_joystick(event.position)

# === LOGIQUE COMMUNE ===

func _is_in_joystick_area(pos: Vector2) -> bool:
	"""Vérifie si une position est dans la zone du joystick"""
	if not out or not out.texture:
		return false
	
	var joystick_global_pos = out.global_position
	var joystick_size = out.texture.get_size() * out.scale
	
	var margin = 20.0
	var joystick_rect = Rect2(
		joystick_global_pos - joystick_size / 2 - Vector2(margin, margin),
		joystick_size + Vector2(margin * 2, margin * 2)
	)
	
	return joystick_rect.has_point(pos)

func _update_joystick(input_pos: Vector2) -> void:
	"""Met à jour la position du joystick"""
	var local_pos = input_pos - out.global_position
	
	var distance = local_pos.length()
	if distance > max_distance:
		local_pos = local_pos.normalized() * max_distance
	
	inside.position = local_pos
	
	current_direction = local_pos / max_distance

func _process(delta: float) -> void:
	if not is_pressed:
		inside.position = inside.position.lerp(Vector2.ZERO, return_speed * delta)
		current_direction = current_direction.lerp(Vector2.ZERO, return_speed * delta)
		
		if inside.position.length() < 1.0:
			inside.position = Vector2.ZERO
			current_direction = Vector2.ZERO

func get_direction() -> Vector2:
	"""Retourne la direction actuelle du joystick (normalisée)"""
	return current_direction
