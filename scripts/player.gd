extends CharacterBody2D

@export var walk_speed: float = 200.0
@export var run_speed: float = 400.0
@export var acceleration: float = 1500.0
@export var friction: float = 1200.0

@onready var capitch: AnimatedSprite2D = $capitch
@onready var sound: AudioStreamPlayer2D = $sound

var last_direction: Vector2 = Vector2.DOWN
var is_walking: bool = false
var is_running: bool = false

@export var walk_animation_speed: float = 1.0
@export var run_animation_speed: float = 1.5
@export var walk_sound_pitch: float = 1.0
@export var run_sound_pitch: float = 1.4

var eat_cooldown: Timer = Timer.new()
@export var eat_cooldown_time: float = 0.3

var virtual_joystick: Control = null
var game_ui: CanvasLayer = null

var android_sprint_pressed: bool = false
var current_speed_multiplier: float = 1.0

var is_sprinting = false  # Ajoutez cette variable
var speed = 200.0
var sprint_speed = 400.0

   
func _ready() -> void:
	capitch.play("idle")
	sound.volume_db = float(GameManager._get_file_content("res://state/volume_sound.txt"))
	
	add_child(eat_cooldown)
	eat_cooldown.wait_time = eat_cooldown_time
	eat_cooldown.one_shot = true
	
	add_to_group("player")
	
	#print("🎮 Joueur initialisé")
	call_deferred("_setup_android_controls")
	
	if GameManager.has_signal("energy_depleted"):
		GameManager.energy_depleted.connect(_on_energy_depleted)
	if GameManager.has_signal("game_over"):
		GameManager.game_over.connect(_on_game_over)

func _setup_android_controls() -> void:
	game_ui = get_tree().get_first_node_in_group("game_ui")
	if not game_ui:
		game_ui = get_node_or_null("/root/Game/game_ui")
	
	if game_ui:
		if game_ui.has_signal("eat_button_pressed"):
			if not game_ui.eat_button_pressed.is_connected(_on_android_eat_pressed):
				game_ui.eat_button_pressed.connect(_on_android_eat_pressed)
		
		if game_ui.has_signal("sprint_button_pressed"):
			if not game_ui.sprint_button_pressed.is_connected(_on_android_sprint_pressed):
				game_ui.sprint_button_pressed.connect(_on_android_sprint_pressed)
		
		if game_ui.has_signal("hide_button_pressed"):
			if not game_ui.hide_button_pressed.is_connected(_on_android_hide_pressed):
				game_ui.hide_button_pressed.connect(_on_android_hide_pressed)
		
		virtual_joystick = game_ui.get_node_or_null("android")
		if virtual_joystick:
			pass

func _physics_process(delta: float) -> void:
	var energy_percent = GameManager.get_energy_percentage()
	var current_speed = sprint_speed if is_sprinting else speed
	if GameManager.is_game_over or energy_percent <= 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		_update_animation(Vector2.ZERO)
		if sound.playing:
			sound.stop()
		return
	
	var input_direction = _get_input_direction()
	
	var wants_to_run = false
	if GameManager.plateform == GameManager.ANDROID:
		wants_to_run = android_sprint_pressed
	else:
		wants_to_run = Input.is_action_pressed("ui_shift")
	
	is_running = wants_to_run and GameManager.can_run() and input_direction.length() > 0.1
	
	if input_direction.length() > 0.1:
		if is_running:
			GameManager.drain_energy(delta)
		elif energy_percent < 20.0:
			GameManager.drain_energy(delta * 0.3)
	
	current_speed_multiplier = GameManager.get_speed_multiplier()
	
	if current_speed_multiplier < 0.5:
		is_running = false
	
	var movement_direction: Vector2
	
	if input_direction.length() > 0.1:
		movement_direction = input_direction
		last_direction = input_direction
	else:
		movement_direction = Vector2.ZERO
	
	var base_speed = run_speed if is_running else walk_speed
	var target_speed = base_speed * current_speed_multiplier
	
	if current_speed_multiplier < 1.0:
		capitch.modulate = lerp(Color(1.0, 1.0, 1.0), Color(0.7, 0.7, 1.0), 1.0 - current_speed_multiplier)
	else:
		capitch.modulate = Color(1.0, 1.0, 1.0)
	
	if movement_direction.length() > 0.1:
		velocity = velocity.move_toward(movement_direction * target_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
	_update_animation(movement_direction)
	_update_footstep_sound(movement_direction)

func _get_input_direction() -> Vector2:
	var direction := Vector2.ZERO
	
	if GameManager.plateform == GameManager.ANDROID and is_instance_valid(virtual_joystick):
		if virtual_joystick.has_method("get_direction"):
			direction = virtual_joystick.get_direction()
			if direction.length() > 0.1:
				return direction.normalized()
	
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction.length() > 1.0:
		direction = direction.normalized()
	
	return direction

func _unhandled_input(event: InputEvent) -> void:
	# DEBUG : ESC+D pour drainer l'énergie
	if event.is_action_pressed("ui_cancel") and Input.is_key_pressed(KEY_D):
		#print("🧪 DEBUG: Drainage forcé de l'énergie à 0")
		GameManager.current_energy = 0.0
		GameManager._update_energy_ui()
		GameManager._trigger_game_over()
		return
	
	if GameManager.plateform == GameManager.PC:
		if event.is_action_pressed("ui_accept"):
			_try_action()
			return
		
		if event.is_action_pressed("ui_cancel"):
			if not Input.is_key_pressed(KEY_D):
				#print("🏠 Touche ESC pressée - Tentative de se cacher")
				_try_hide()
			return

func _try_action() -> void:
	"""Action contextuelle avec ESPACE : manger en priorité, sinon se cacher"""
	if GameManager.is_in and not eat_cooldown.is_stopped() == false:
		var vegetable = GameManager.get_nearest_vegetable(global_position)
		if is_instance_valid(vegetable):
			_try_eat()
			return
	
	_try_hide()

func _on_android_eat_pressed() -> void:
	if GameManager.is_game_over:
		return
	
	call_deferred("_try_action")

func _on_android_sprint_pressed(is_pressed: bool) -> void:
	android_sprint_pressed = is_pressed

func _on_android_hide_pressed() -> void:
	call_deferred("_try_hide")

func _try_hide() -> void:
	"""Tenter de se cacher dans une cachette proche"""
	if GameManager.is_game_over:
		return
	
	var cachettes = get_tree().get_nodes_in_group("cachettes")
	
	if cachettes.is_empty():
		return
	
	var nearest_cachette: Area2D = null
	var nearest_distance: float = INF
	
	for cachette in cachettes:
		if not is_instance_valid(cachette):
			continue
		
		var distance = global_position.distance_to(cachette.global_position)
		
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cachette = cachette
	
	if nearest_cachette:
		
		if nearest_cachette.has_method("try_hide"):
			nearest_cachette.try_hide()
		else:
			pass
	else:
		pass

func _on_energy_depleted() -> void:
	is_running = false
	android_sprint_pressed = false

func _on_game_over() -> void:
	is_running = false
	android_sprint_pressed = false
	_play_death_animation()

func _play_death_animation() -> void:
	if is_instance_valid(capitch):
		capitch.stop()
	
	if is_instance_valid(sound) and sound.playing:
		sound.stop()
	
	if is_instance_valid(capitch):
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(capitch, "modulate", Color(0.5, 0.5, 0.5, 0.5), 1.0)
		tween.tween_property(capitch, "scale", capitch.scale * 0.8, 1.0)
		tween.tween_property(capitch, "rotation", deg_to_rad(90), 1.0)

func _try_eat() -> void:
	if GameManager.is_game_over:
		return
	
	if not GameManager.is_in:
		return
	
	if not eat_cooldown.is_stopped():
		return
	
	var vegetable = GameManager.get_nearest_vegetable(global_position)
	
	if not is_instance_valid(vegetable):
		return
	
	if vegetable.has_method("eat_once"):
		vegetable.eat_once()
	
	eat_cooldown.start()
	_play_eat_animation()

func _play_eat_animation() -> void:
	if not is_instance_valid(capitch):
		return
	
	var original_scale = capitch.scale
	var tween = create_tween()
	tween.tween_property(capitch, "scale", original_scale * 1.2, 0.1)
	tween.tween_property(capitch, "scale", original_scale, 0.1)
	
	capitch.modulate = Color(1.5, 1.5, 1.5, 1.0)
	var flash = create_tween()
	flash.tween_property(capitch, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)

func _update_animation(direction: Vector2) -> void:
	if not is_instance_valid(capitch):
		return
	
	var anim_speed_mult = max(0.1, current_speed_multiplier)
	
	if is_running:
		capitch.speed_scale = run_animation_speed * anim_speed_mult
	else:
		capitch.speed_scale = walk_animation_speed * anim_speed_mult
	
	if direction.length() > 0.1:
		is_walking = true
		
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				capitch.play("walk_right")
				capitch.flip_h = false
			else:
				capitch.play("walk_right")
				capitch.flip_h = true
		else:
			if direction.y > 0:
				capitch.play("walk_down")
			else:
				capitch.play("walk_up")
	else:
		is_walking = false
		capitch.speed_scale = 1.0
		capitch.play("idle")
		
		if abs(last_direction.x) > abs(last_direction.y):
			capitch.flip_h = last_direction.x < 0
		else:
			capitch.flip_h = false

func _update_footstep_sound(direction: Vector2) -> void:
	if not is_instance_valid(sound):
		return
	
	var pitch_mult = max(0.1, current_speed_multiplier)
	
	if is_running:
		sound.pitch_scale = run_sound_pitch * pitch_mult
	else:
		sound.pitch_scale = walk_sound_pitch * pitch_mult
	
	sound.pitch_scale = max(0.1, sound.pitch_scale)
	
	if direction.length() > 0.1:
		if not sound.playing:
			sound.play()
	else:
		if sound.playing:
			sound.stop()
		sound.pitch_scale = walk_sound_pitch
