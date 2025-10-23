extends CharacterBody2D

@export var base_speed: float = 120.0
@export var speed_increase_per_level: float = 15.0  # Vitesse gagnée par niveau
@export var max_speed: float = 250.0  # Vitesse maximale
@export var acceleration: float = 800.0
@export var friction: float = 600.0

@export var base_vision_range: float = 200.0
@export var vision_range_increase_per_level: float = 20.0  # Portée gagnée par niveau
@export var max_vision_range: float = 350.0
@export var base_vision_angle: float = 90.0
@export var vision_angle_increase_per_level: float = 5.0  # Angle gagné par niveau
@export var max_vision_angle: float = 130.0
@export var raycast_count: int = 7

@export var waypoint_reached_distance: float = 30.0
@export var base_pause_at_waypoint: float = 1.0
@export var pause_decrease_per_level: float = 0.1  # Pause réduite par niveau
@export var min_pause: float = 0.2  # Pause minimale

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var vision_cone: Node2D = $VisionCone

var player: CharacterBody2D = null
var path_markers: Array[Marker2D] = []
var current_patrol_path: Array[Marker2D] = []
var current_waypoint_index: int = 0
var is_paused: bool = false
var pause_timer: float = 0.0

var facing_direction: Vector2 = Vector2.RIGHT
var move_direction: Vector2 = Vector2.ZERO

var current_speed: float = 120.0
var current_vision_range: float = 200.0
var current_vision_angle: float = 90.0
var current_pause_duration: float = 1.0

func _ready() -> void:
	collision_layer = 2  # Enemy layer
	collision_mask = 1 + 4  # Collide avec Player (1) + Walls (4)
	
	_calculate_stats_from_level()
	
	_find_path_markers()
	
	_build_patrol_path()
	
	call_deferred("_find_player")
	
	if sprite:
		sprite.play("idle")
	
	add_to_group("enemies")

func _calculate_stats_from_level() -> void:
	"""Calculer les statistiques de l'ennemi en fonction du niveau actuel"""
	var current_level = GameManager.get_current_level()
	
	current_speed = base_speed + (speed_increase_per_level * current_level)
	current_speed = min(current_speed, max_speed)
	
	current_vision_range = base_vision_range + (vision_range_increase_per_level * current_level)
	current_vision_range = min(current_vision_range, max_vision_range)
	
	current_vision_angle = base_vision_angle + (vision_angle_increase_per_level * current_level)
	current_vision_angle = min(current_vision_angle, max_vision_angle)
	
	current_pause_duration = base_pause_at_waypoint - (pause_decrease_per_level * current_level)
	current_pause_duration = max(current_pause_duration, min_pause)

func _find_path_markers() -> void:
	"""Récupérer tous les Marker2D du niveau pour le pathfinding"""
	var markers = get_tree().get_nodes_in_group("path_markers")
	for marker in markers:
		if marker is Marker2D:
			path_markers.append(marker)

func _build_patrol_path() -> void:
	"""Construire le chemin de patrouille en connectant les markers accessibles"""
	if path_markers.is_empty():
		return
	
	var start_marker = _find_nearest_marker(global_position)
	if not start_marker:
		return
	
	var visited: Array[Marker2D] = []
	var current = start_marker
	current_patrol_path.append(current)
	visited.append(current)
	
	# Parcourir tous les markers accessibles
	while visited.size() < path_markers.size():
		var next_marker = _find_nearest_accessible_marker(current, visited)
		
		if next_marker:
			current_patrol_path.append(next_marker)
			visited.append(next_marker)
			current = next_marker
		else:
			break
	
	if current_patrol_path.size() > 1:
		current_patrol_path.append(start_marker)
	

func _find_nearest_marker(pos: Vector2) -> Marker2D:
	"""Trouver le marker le plus proche d'une position"""
	var nearest: Marker2D = null
	var nearest_distance: float = INF
	
	for marker in path_markers:
		if not is_instance_valid(marker):
			continue
		
		var distance = pos.distance_to(marker.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = marker
	
	return nearest

func _find_nearest_accessible_marker(from_marker: Marker2D, visited: Array[Marker2D]) -> Marker2D:
	"""Trouver le marker le plus proche accessible (sans obstacle entre)"""
	var nearest: Marker2D = null
	var nearest_distance: float = INF
	
	for marker in path_markers:
		if marker in visited or not is_instance_valid(marker):
			continue
		
		# Vérifier s'il y a un chemin direct sans obstacle
		if _has_clear_path(from_marker.global_position, marker.global_position):
			var distance = from_marker.global_position.distance_to(marker.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = marker
	
	return nearest

func _has_clear_path(from: Vector2, to: Vector2) -> bool:
	"""Vérifier s'il y a un chemin direct sans obstacle entre deux points"""
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 4  # Uniquement les murs
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func _find_player() -> void:
	"""Trouver le joueur dans la scène"""
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

func _physics_process(delta: float) -> void:
	if _check_player_in_vision():
		_trigger_game_over()
		return
	
	if is_paused:
		pause_timer -= delta
		if pause_timer <= 0.0:
			is_paused = false
			current_waypoint_index += 1
			
			if current_waypoint_index >= current_patrol_path.size():
				current_waypoint_index = 0
		
		_apply_friction(delta)
		update_animation(Vector2.ZERO)
		move_and_slide()
		_update_vision_cone()
		return
	
	if not current_patrol_path.is_empty():
		_follow_patrol_path(delta)
	else:
		_apply_friction(delta)
		move_direction = Vector2.ZERO
	
	update_animation(move_direction)
	
	move_and_slide()
	_update_vision_cone()

func _check_player_in_vision() -> bool:
	"""Vérifier si le joueur est dans le cône de vision"""
	if not player or not is_instance_valid(player):
		return false
	
	var cachettes = get_tree().get_nodes_in_group("cachettes")
	for cachette in cachettes:
		if cachette.has_method("is_player_hidden") and cachette.is_player_hidden():
			return false
	
	var direction_to_player = (player.global_position - global_position).normalized()
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > current_vision_range:
		return false
	
	var angle_to_player = facing_direction.angle_to(direction_to_player)
	var half_vision_angle = deg_to_rad(current_vision_angle / 2.0)
	
	if abs(angle_to_player) > half_vision_angle:
		return false
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	query.exclude = [self]
	query.collision_mask = 4  # Uniquement les murs
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return true
	
	return false

func _follow_patrol_path(delta: float) -> void:
	"""Suivre le chemin de patrouille"""
	if current_waypoint_index >= current_patrol_path.size():
		current_waypoint_index = 0
		return
	
	var target_marker = current_patrol_path[current_waypoint_index]
	
	if not is_instance_valid(target_marker):
		current_waypoint_index += 1
		return
	
	var target_position = target_marker.global_position
	var direction = (target_position - global_position).normalized()
	var distance = global_position.distance_to(target_position)
	
	if distance < waypoint_reached_distance:
		is_paused = true
		pause_timer = current_pause_duration  # ✅ Utiliser la pause calculée selon le niveau
		move_direction = Vector2.ZERO
		return
	
	facing_direction = direction
	move_direction = direction
	velocity = velocity.move_toward(direction * current_speed, acceleration * delta)

func _apply_friction(delta: float) -> void:
	"""Appliquer la friction pour ralentir"""
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func update_animation(direction: Vector2) -> void:
	"""Mettre à jour l'animation en fonction de la direction de mouvement"""
	if not sprite:
		return
	
	if direction.length() == 0:
		sprite.play("idle")
		return
	
	var speed_ratio = current_speed / base_speed
	sprite.speed_scale = clamp(speed_ratio, 1.0, 2.0)
	
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			sprite.flip_h = false
			sprite.play("walk_right")
		else:
			sprite.flip_h = true
			sprite.play("walk_right")
	else:
		sprite.flip_h = false
		if direction.y > 0:
			sprite.play("walk_down")
		else:
			sprite.play("walk_up")

func _update_vision_cone() -> void:
	"""Mettre à jour la visualisation du cône de vision"""
	if not vision_cone:
		return
	
	vision_cone.queue_redraw()

func _draw_vision_cone() -> void:
	"""Dessiner le cône de vision (appelé par VisionCone)"""
	var half_angle = deg_to_rad(current_vision_angle / 2.0)
	
	var level = GameManager.get_current_level()
	var intensity = clamp(1.0 + (level * 0.1), 1.0, 2.0)
	
	var vision_color = Color.RED * intensity
	vision_color.a = 0.3
	
	for i in range(raycast_count):
		var t = float(i) / float(raycast_count - 1) if raycast_count > 1 else 0.5
		var angle = lerp(-half_angle, half_angle, t)
		var rotated_direction = facing_direction.rotated(angle)
		var end_point = rotated_direction * current_vision_range  # ✅ Utilise la portée calculée
		
		vision_cone.draw_line(Vector2.ZERO, end_point, vision_color, 2.0)
	
	var arc_points: PackedVector2Array = []
	var arc_steps = 20
	for i in range(arc_steps + 1):
		var t = float(i) / float(arc_steps)
		var angle = lerp(-half_angle, half_angle, t)
		var point = facing_direction.rotated(angle) * current_vision_range  # ✅ Utilise la portée calculée
		arc_points.append(point)
	
	var arc_color = Color.RED * intensity
	arc_color.a = 0.2
	
	for i in range(arc_points.size() - 1):
		vision_cone.draw_line(arc_points[i], arc_points[i + 1], arc_color, 1.0)

func _trigger_game_over() -> void:
	"""Déclencher le Game Over"""
	
	velocity = Vector2.ZERO
	move_direction = Vector2.ZERO
	
	if sprite:
		sprite.play("idle")
		sprite.speed_scale = 1.0
	
	if not GameManager.is_game_over:
		GameManager._trigger_game_over()

func take_damage(amount: int) -> void:
	"""Recevoir des dégâts"""
	queue_free()
