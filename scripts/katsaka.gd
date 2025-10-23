extends StaticBody2D

@onready var img: Sprite2D = $img

@export var points_required: int = 5
@export var score_value: int = 15

var current_points: int = 0
var original_wind_shader: ShaderMaterial = null
var initial_scale: Vector2
var collision_shapes: Array[CollisionShape2D] = []

func _ready() -> void:
	if not img:
		return
	
	initial_scale = scale
	
	if img.material and img.material is ShaderMaterial:
		original_wind_shader = img.material
	
	_find_all_collision_shapes()
	current_points = points_required
	add_to_group("vegetables")

func _find_all_collision_shapes() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			collision_shapes.append(child)
	var area = get_node_or_null("Area2D")
	if area:
		for child in area.get_children():
			if child is CollisionShape2D:
				collision_shapes.append(child)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		GameManager.register_vegetable(self)
		_enable_highlight(true)
		#print("🌾 Blé détecté")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		GameManager.unregister_vegetable(self)
		_enable_highlight(false)
		#print("👋 Blé hors de portée")

func _enable_highlight(enabled: bool) -> void:
	if original_wind_shader:
		if original_wind_shader.shader and original_wind_shader.shader.get_code().contains("highlight_enabled"):
			original_wind_shader.set_shader_parameter("highlight_enabled", enabled)
		else:
			if enabled:
				img.modulate = Color(1.4, 1.4, 0.8, 1.0)
			else:
				img.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif img:
		if enabled:
			img.modulate = Color(1.4, 1.4, 0.8, 1.0)
		else:
			img.modulate = Color(1.0, 1.0, 1.0, 1.0)

func eat_once() -> bool:
	if current_points <= 0:
		return true
	
	current_points -= 1
	
	GameManager.restore_energy(GameManager.energy_gain_per_vegetable)
	
	var progress = float(current_points) / float(points_required)
	var new_scale = initial_scale * progress
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", new_scale, 0.25)
	
	if img:
		var original_modulate = img.modulate
		img.modulate = Color(2.5, 2.5, 2.5, 1.0)
		var flash_tween = create_tween()
		flash_tween.tween_property(img, "modulate", original_modulate, 0.15)
	
	if current_points <= 0:
		GameManager.add_score(score_value)
		GameManager.unregister_vegetable(self)
		
		_disable_collisions()
		
		var fade = create_tween()
		fade.set_parallel(true)
		fade.tween_property(self, "scale", Vector2.ZERO, 0.4)
		fade.tween_property(self, "modulate:a", 0.0, 0.4)
		fade.finished.connect(queue_free)
		
		return true
	
	return false

func _disable_collisions() -> void:
	for shape in collision_shapes:
		if is_instance_valid(shape):
			shape.set_deferred("disabled", true)

func get_points_remaining() -> int:
	return current_points

func _update_point(val: int) -> void:
	current_points = val
	if current_points <= 0:
		GameManager.unregister_vegetable(self)
		_disable_collisions()
		var fade = create_tween()
		fade.tween_property(self, "modulate:a", 0.0, 0.3)
		fade.finished.connect(queue_free)

func get_point() -> int:
	return current_points
