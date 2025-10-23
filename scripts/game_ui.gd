extends CanvasLayer

@onready var level_progress: TextureProgressBar = $level_progress
@onready var level: Label = $level_progress/level
@onready var energy_bar: TextureProgressBar = $energy_bar
@onready var energy: Label = $energy_bar/energy
@onready var button: Button = $Button
@onready var sound: AudioStreamPlayer2D = $sound
@onready var music: AudioStreamPlayer2D = $music

@onready var android_controls: Control = $android
@onready var btn_eat: TextureButton = $android/btn_eat
@onready var btn_sprint: Button = $android/btn_sprint
@onready var btn_hide: Button = $android/btn_hide

@onready var congratulations_modal: Control = $congratulations_modal
@onready var game_over_modal: Control = $game_over_modal

signal eat_button_pressed
signal sprint_button_pressed(is_pressed: bool)
signal hide_button_pressed

var is_sprint_active: bool = false

func _ready() -> void:
	
	if not GameManager.score_changed.is_connected(_on_score_changed):
		GameManager.score_changed.connect(_on_score_changed)
	
	if not GameManager.energy_changed.is_connected(_on_energy_changed):
		GameManager.energy_changed.connect(_on_energy_changed)
	
	if not GameManager.level_up.is_connected(_on_level_up):
		GameManager.level_up.connect(_on_level_up)
	
	if not GameManager.level_changed.is_connected(_on_level_changed):
		GameManager.level_changed.connect(_on_level_changed)
	
	if not GameManager.game_completed.is_connected(_on_game_completed):
		GameManager.game_completed.connect(_on_game_completed)
	
	if not GameManager.game_over.is_connected(_on_game_over):
		GameManager.game_over.connect(_on_game_over)
		#print("Signal game_over connecte")
	
	if congratulations_modal:
		congratulations_modal.visible = false
	
	if game_over_modal:
		game_over_modal.visible = false
	
	_update_level_display()
	_update_energy_display()
	
	music.play(0.0)
	GameManager._check_ui_android(android_controls)
	
	$music.volume_db = float(GameManager._get_file_content("res://state/last_volume.txt"))
	$sound.volume_db = float(GameManager._get_file_content("res://state/volume_sound.txt"))
	
	if btn_eat:
		if btn_eat.pressed.is_connected(_on_eat_button_pressed):
			btn_eat.pressed.disconnect(_on_eat_button_pressed)
		
		btn_eat.pressed.connect(_on_eat_button_pressed)
		btn_eat.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if btn_sprint:
		if btn_sprint.button_down.is_connected(_on_sprint_button_down):
			btn_sprint.button_down.disconnect(_on_sprint_button_down)
		if btn_sprint.button_up.is_connected(_on_sprint_button_up):
			btn_sprint.button_up.disconnect(_on_sprint_button_up)
		if btn_sprint.pressed.is_connected(_on_sprint_button_pressed_fallback):
			btn_sprint.pressed.disconnect(_on_sprint_button_pressed_fallback)
		
		btn_sprint.button_down.connect(_on_sprint_button_down)
		btn_sprint.button_up.connect(_on_sprint_button_up)
		btn_sprint.pressed.connect(_on_sprint_button_pressed_fallback)
		btn_sprint.mouse_filter = Control.MOUSE_FILTER_STOP
		
		btn_sprint.toggle_mode = false
		btn_sprint.keep_pressed_outside = true
		
	
	if btn_hide:
		if btn_hide.pressed.is_connected(_on_hide_button_pressed):
			btn_hide.pressed.disconnect(_on_hide_button_pressed)
		
		btn_hide.pressed.connect(_on_hide_button_pressed)
		btn_hide.mouse_filter = Control.MOUSE_FILTER_STOP
	
	add_to_group("game_ui")

func _on_score_changed(current_score: int, required_score: int, progress: float) -> void:
	level_progress.value = progress * 100.0
	
	var level_num = GameManager.get_current_level()
	var max_level = GameManager.get_max_level()
	
	if GameManager.is_max_level_reached():
		level.text = "LEVEL MAX (" + str(current_score) + ")"
	else:
		level.text = "LEVEL " + str(level_num) + "/" + str(max_level) + " (" + str(current_score) + "/" + str(required_score) + ")"

func _on_energy_changed(_current: float, _maximum: float, percentage: float) -> void:
	energy_bar.value = percentage
	energy.text = str(int(round(percentage))) + " %"
	
	if percentage <= 0.0:
		energy.modulate = Color(0.5, 0.5, 0.5)
		energy_bar.modulate = Color(0.5, 0.5, 0.5)
	elif percentage < 20.0:
		energy.modulate = Color(1.0, 0.3, 0.3)
		energy_bar.modulate = Color(1.0, 1.0, 1.0)
	elif percentage < 50.0:
		energy.modulate = Color(1.0, 0.8, 0.2)
		energy_bar.modulate = Color(1.0, 1.0, 1.0)
	else:
		energy.modulate = Color(1.0, 1.0, 1.0)
		energy_bar.modulate = Color(1.0, 1.0, 1.0)

func _on_level_up(new_level: int) -> void:
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(level_progress, "modulate", Color(2.0, 2.0, 1.0), 0.2)
	tween.tween_property(level, "scale", Vector2(1.3, 1.3), 0.2)
	
	await tween.finished
	
	var tween2 = create_tween()
	tween2.set_parallel(true)
	tween2.tween_property(level_progress, "modulate", Color(1.0, 1.0, 1.0), 0.3)
	tween2.tween_property(level, "scale", Vector2(1.0, 1.0), 0.3)

func _on_level_changed(_new_level: int) -> void:
	_update_level_display()

func _update_level_display() -> void:
	var current_score = GameManager.get_current_score()
	var required_score = GameManager.get_required_score_for_current_level()
	var progress = GameManager.get_level_progress()
	
	level_progress.value = progress * 100.0
	
	var level_num = GameManager.get_current_level()
	var max_level = GameManager.get_max_level()
	
	if GameManager.is_max_level_reached():
		level.text = "LEVEL MAX (" + str(current_score) + ")"
	else:
		level.text = "LEVEL " + str(level_num) + "/" + str(max_level) + " (" + str(current_score) + "/" + str(required_score) + ")"

func _update_energy_display() -> void:
	var percentage = GameManager.get_energy_percentage()
	energy_bar.value = percentage
	energy.text = str(int(round(percentage))) + " %"

func _on_game_completed() -> void:
	
	if congratulations_modal:
		var score_label = congratulations_modal.get_node_or_null("Panel/VBoxContainer/score_label")
		if score_label:
			score_label.text = "Final Score: " + str(GameManager.get_current_score())
		
		congratulations_modal.visible = true
		
		congratulations_modal.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(congratulations_modal, "modulate:a", 1.0, 0.5)

func _on_game_over() -> void:
	
	if game_over_modal:
		var score_label = game_over_modal.get_node_or_null("Panel/VBoxContainer/score_label")
		if score_label:
			score_label.text = "Score: " + str(GameManager.get_current_score())
		
		var level_label = game_over_modal.get_node_or_null("Panel/VBoxContainer/level_label")
		if level_label:
			level_label.text = "Level Reached: " + str(GameManager.get_current_level())
		
		await get_tree().create_timer(1.5).timeout
		
		game_over_modal.visible = true
		
		game_over_modal.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(game_over_modal, "modulate:a", 1.0, 0.5)

func _on_ui_menu_pressed() -> void:
	await GameManager._play_msc(sound)
	GameManager.reset_on_menu_return()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_music_finished() -> void:
	music.play(0.0)

func _on_eat_button_pressed() -> void:
	emit_signal("eat_button_pressed")

func _on_sprint_button_down():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.is_sprinting = true

func _on_sprint_button_up():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.is_sprinting = false

func _on_sprint_button_pressed_fallback() -> void:
	is_sprint_active = !is_sprint_active
	emit_signal("sprint_button_pressed", is_sprint_active)

func _on_hide_button_pressed() -> void:
	emit_signal("hide_button_pressed")

func is_using_android_controls() -> bool:
	return GameManager.plateform == GameManager.ANDROID

func _on_congrats_menu_pressed() -> void:
	await GameManager._play_msc(sound)
	GameManager.reset_on_menu_return()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_congrats_replay_pressed() -> void:
	await GameManager._play_msc(sound)
	GameManager.reset_progression()
	get_tree().reload_current_scene()

func _on_gameover_menu_pressed() -> void:
	await GameManager._play_msc(sound)
	GameManager.reset_on_menu_return()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_gameover_retry_pressed() -> void:
	await GameManager._play_msc(sound)
	GameManager.reset_progression()
	get_tree().reload_current_scene()
