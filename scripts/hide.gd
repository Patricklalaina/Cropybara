extends Area2D

@export var hide_duration: float = 10.0
@export var cooldown_duration: float = 5.0

var player_nearby: bool = false
var player_hidden: bool = false
var is_on_cooldown: bool = false
var current_player: CharacterBody2D = null

var original_sprite_scale: Vector2 = Vector2.ONE
var original_sprite_modulate: Color = Color.WHITE
var original_sprite_position: Vector2 = Vector2.ZERO

var hide_timer: Timer = Timer.new()
var cooldown_timer: Timer = Timer.new()

var progress_container: Control = Control.new()
var progress_bar: ProgressBar = ProgressBar.new()
var progress_bg: ColorRect = ColorRect.new()

var highlight_sprite: Sprite2D = null
var original_modulate: Color = Color.WHITE
var highlight_color: Color = Color(1.5, 1.5, 0.5, 1.0)

func _ready() -> void:
	add_child(hide_timer)
	hide_timer.wait_time = hide_duration
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	progress_bar.z_index = 6
	add_child(cooldown_timer)
	cooldown_timer.wait_time = cooldown_duration
	cooldown_timer.one_shot = true
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	
	add_child(progress_container)
	progress_container.position = Vector2(-60, -140)
	progress_container.size = Vector2(120, 15)
	progress_container.visible = false
	
	progress_container.add_child(progress_bg)
	progress_bg.color = Color(0.1, 0.1, 0.1, 0.9)
	progress_bg.size = Vector2(120, 15)
	
	progress_container.add_child(progress_bar)
	progress_bar.position = Vector2(2, 2)
	progress_bar.size = Vector2(116, 11)
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 100
	progress_bar.show_percentage = false
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.0)
	progress_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.2, 0.8, 0.3, 1.0)
	style_fill.set_corner_radius_all(3)
	progress_bar.add_theme_stylebox_override("fill", style_fill)
	
	highlight_sprite = get_node_or_null("Sprite2D")
	if highlight_sprite:
		original_modulate = highlight_sprite.modulate
	
	add_to_group("cachettes")

func _process(_delta: float) -> void:
	if player_hidden and hide_timer.time_left > 0:
		var percentage = (hide_timer.time_left / hide_duration) * 100.0
		progress_bar.value = percentage
		
		var style = progress_bar.get_theme_stylebox("fill")
		if style is StyleBoxFlat:
			if percentage < 20:
				style.bg_color = Color(0.9, 0.2, 0.2, 1.0)
			elif percentage < 50:
				style.bg_color = Color(0.9, 0.7, 0.2, 1.0)
			else:
				style.bg_color = Color(0.2, 0.8, 0.3, 1.0)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = true
		current_player = body
		_show_highlight(true)

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_nearby = false
		current_player = null
		_show_highlight(false)

func try_hide() -> void:
	if not player_nearby or not current_player:
		return
	
	if player_hidden:
		return
	
	if is_on_cooldown:
		return
	
	if GameManager.is_game_over:
		return
	
	_hide_player()

func _hide_player() -> void:
	player_hidden = true
	
	if current_player and is_instance_valid(current_player):
		var sprite = current_player.get_node_or_null("capitch")
		if sprite and is_instance_valid(sprite):
			original_sprite_scale = sprite.scale
			original_sprite_modulate = sprite.modulate
			original_sprite_position = sprite.position
			
	if current_player:
		_play_hide_animation()
	
	hide_timer.start()
	progress_container.visible = true
	progress_bar.value = 100
	
	if current_player:
		current_player.set_physics_process(false)
		current_player.set_process_input(false)

func _show_player() -> void:
	player_hidden = false
	progress_container.visible = false
	
	if current_player:
		_play_show_animation()
	
	await get_tree().create_timer(0.6).timeout
	
	if current_player and is_instance_valid(current_player):
		current_player.set_physics_process(true)
		current_player.set_process_input(true)
	
	is_on_cooldown = true
	cooldown_timer.start()
	_show_highlight(false)

func _play_hide_animation() -> void:
	if not is_instance_valid(current_player):
		return
	
	var sprite = current_player.get_node_or_null("capitch")
	if not sprite or not is_instance_valid(sprite):
		return
	
	var target_scale = sprite.scale * 0.1
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", target_scale, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_property(current_player, "position:y", current_player.position.y - 20, 0.5)

func _play_show_animation() -> void:
	if not is_instance_valid(current_player):
		return
	
	var sprite = current_player.get_node_or_null("capitch")
	if not sprite or not is_instance_valid(sprite):
		return
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(sprite, "scale", original_sprite_scale, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(sprite, "modulate", original_sprite_modulate, 0.5)
	
	tween.tween_property(current_player, "position:y", current_player.position.y + 20, 0.5)
	
	await tween.finished
	
	if sprite and is_instance_valid(sprite):
		sprite.scale = original_sprite_scale
		sprite.modulate = original_sprite_modulate

func _show_highlight(enabled: bool) -> void:
	if not highlight_sprite:
		return
	
	if enabled and not is_on_cooldown:
		highlight_sprite.modulate = highlight_color
		
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(highlight_sprite, "modulate:a", 0.7, 0.5)
		tween.tween_property(highlight_sprite, "modulate:a", 1.0, 0.5)
	else:
		highlight_sprite.modulate = original_modulate
		var tweens = get_tree().get_processed_tweens()
		for tween in tweens:
			if tween.is_valid():
				tween.kill()

func _on_hide_timer_timeout() -> void:
	_show_player()

func _on_cooldown_timeout() -> void:
	is_on_cooldown = false
	if player_nearby:
		_show_highlight(true)

func is_player_hidden() -> bool:
	return player_hidden
