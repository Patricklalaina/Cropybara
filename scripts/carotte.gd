extends StaticBody2D

const OUTLINE_SHADER = preload("res://shaders/carotte.gdshader")
@onready var img: Sprite2D = $img

@export var points_required: int = 3
@export var score_value: int = 10

var current_points: int = 0
var shader_material: ShaderMaterial = null
var original_material: Material = null
var is_being_eaten: bool = false
var initial_scale: Vector2
var collision_shapes: Array[CollisionShape2D] = []

func _ready() -> void:
	if not img:
		return
	
	initial_scale = scale
	original_material = img.material
	shader_material = ShaderMaterial.new()
	shader_material.shader = OUTLINE_SHADER
	current_points = points_required
	add_to_group("vegetables")
	_find_all_collision_shapes()

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
		img.material = shader_material

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		GameManager.unregister_vegetable(self)
		img.material = original_material

func eat_once() -> bool:
	if is_being_eaten or current_points <= 0:
		return true
	
	current_points -= 1
	
	GameManager.restore_energy(GameManager.energy_gain_per_vegetable)
	
	var progress = float(current_points) / float(points_required)
	var new_scale = initial_scale * progress
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", new_scale, 0.2)
	
	if img:
		img.modulate = Color(2.0, 2.0, 2.0, 1.0)
		var flash = create_tween()
		flash.tween_property(img, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	
	if current_points <= 0:
		is_being_eaten = true
		GameManager.add_score(score_value)
		GameManager.unregister_vegetable(self)
		
		_disable_collisions()
		
		var fade = create_tween()
		fade.set_parallel(true)
		fade.tween_property(self, "scale", Vector2.ZERO, 0.3)
		fade.tween_property(self, "modulate:a", 0.0, 0.3)
		fade.finished.connect(queue_free)
		
		return true
	
	return false

func _disable_collisions() -> void:
	for shape in collision_shapes:
		if is_instance_valid(shape):
			shape.set_deferred("disabled", true)

func get_points_remaining() -> int:
	return current_points
