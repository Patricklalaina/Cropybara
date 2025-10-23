extends Node

@onready var mute_volume: float = -80.0
@onready var min_volume: float = -20.0
@onready var max_volume: float = 6.0

@onready var quota_point: Array = [45, 100, 200, 400, 682]
@onready var curr_level: int = 0
@onready var curr_score: int = 0

@onready var max_energy: float = 100.0
@onready var current_energy: float = 100.0
@onready var energy_drain_rate: float = 15.0  
@onready var energy_gain_per_vegetable: float = 5.0
@onready var min_energy_to_run: float = 5.0

@onready var energy_slowdown_threshold: float = 20.0
@onready var min_slowdown_multiplier: float = 0.3

@onready var is_in: bool = false
var nearby_vegetables: Array = []
var current_target_vegetable: Node2D = null

var is_game_over: bool = false

enum {ANDROID, PC}
var plateform = ANDROID

signal level_changed(new_level: int)
signal score_changed(current_score: int, required_score: int, progress: float)
signal energy_changed(current_energy: float, max_energy: float, percentage: float)
signal energy_depleted
signal level_up(new_level: int)
signal game_completed
signal game_over

func _ready() -> void:
	_load_game_state()
	_validate_loaded_state()
	_update_score_ui()
	_update_energy_ui()

func _validate_loaded_state() -> void:
	if curr_level < 0 or curr_level > quota_point.size():
		reset_progression()
		return
	
	if curr_score < 0:
		reset_progression()
		return
	
	if curr_level >= quota_point.size() and curr_score < quota_point[quota_point.size() - 1]:
		reset_progression()
		return

func add_score(points: int) -> void:
	if is_game_over:
		return
	
	curr_score += points
	
	_check_level_up()
	_update_score_ui()
	_save_game_state()

func _check_level_up() -> void:
	if curr_level >= quota_point.size():
		return
	
	var required_score = quota_point[curr_level]
	
	if curr_score >= required_score:
		curr_level += 1
		
		current_energy = max_energy
		_update_energy_ui()
		
		emit_signal("level_up", curr_level)
		emit_signal("level_changed", curr_level)
		
		if curr_level >= quota_point.size():
			emit_signal("game_completed")
		else:
			_check_level_up()

func get_current_level() -> int:
	return curr_level

func get_current_score() -> int:
	return curr_score

func get_required_score_for_current_level() -> int:
	if curr_level >= quota_point.size():
		return quota_point[quota_point.size() - 1]
	return quota_point[curr_level]

func get_level_progress() -> float:
	if curr_level >= quota_point.size():
		return 1.0
	
	var required = quota_point[curr_level]
	var previous = 0 if curr_level == 0 else quota_point[curr_level - 1]
	var progress_in_level = curr_score - previous
	var level_range = required - previous
	
	if level_range <= 0:
		return 0.0
	
	var progress = clamp(float(progress_in_level) / float(level_range), 0.0, 1.0)
	return progress

func get_max_level() -> int:
	return quota_point.size()

func is_max_level_reached() -> bool:
	return curr_level >= quota_point.size()

func drain_energy(delta: float) -> void:
	"""Réduire l'énergie (appelé quand le joueur court)"""
	if is_game_over:
		return
	
	var energy_lost = energy_drain_rate * delta
	current_energy -= energy_lost
	
	if current_energy <= 0.0:
		current_energy = 0.0
		_update_energy_ui()
		_trigger_game_over()
		return
	
	_update_energy_ui()

func restore_energy(amount: float) -> void:
	if is_game_over:
		return
	
	current_energy += amount
	current_energy = clamp(current_energy, 0.0, max_energy)
	
	
	_update_energy_ui()

func can_run() -> bool:
	if is_game_over:
		return false
	return current_energy > min_energy_to_run

func get_speed_multiplier() -> float:
	if is_game_over:
		return 0.0
	
	if current_energy <= 0.0:
		return 0.0
	
	var energy_percentage = get_energy_percentage()
	
	if energy_percentage > energy_slowdown_threshold:
		return 1.0
	
	var slowdown_progress = energy_percentage / energy_slowdown_threshold
	return lerp(min_slowdown_multiplier, 1.0, slowdown_progress)

func get_energy_percentage() -> float:
	if max_energy <= 0.0:
		return 0.0
	
	var percentage = (current_energy / max_energy) * 100.0
	return percentage

func _trigger_game_over() -> void:
	
	if is_game_over:
		return
	
	is_game_over = true
	current_energy = 0.0
	
	_update_energy_ui()
	
	emit_signal("energy_depleted")
	emit_signal("game_over")
	

func reset_game_over() -> void:
	is_game_over = false

func _update_score_ui() -> void:
	var required = get_required_score_for_current_level()
	var progress = get_level_progress()
	emit_signal("score_changed", curr_score, required, progress)

func _update_energy_ui() -> void:
	var percentage = get_energy_percentage()
	emit_signal("energy_changed", current_energy, max_energy, percentage)

func _save_game_state() -> void:
	_write_in_file(str(curr_score), _open_file("res://state/score.txt", FileAccess.WRITE))
	_write_in_file(str(curr_level), _open_file("res://state/level.txt", FileAccess.WRITE))
	_write_in_file(str(current_energy), _open_file("res://state/energy.txt", FileAccess.WRITE))

func _load_game_state() -> void:
	curr_score = 0
	curr_level = 0
	current_energy = max_energy
	
	var score_file = _open_file("res://state/score.txt", FileAccess.READ)
	if score_file:
		var score_text = score_file.get_as_text().strip_edges()
		if score_text != "":
			curr_score = int(score_text)
		score_file.close()
	
	var level_file = _open_file("res://state/level.txt", FileAccess.READ)
	if level_file:
		var level_text = level_file.get_as_text().strip_edges()
		if level_text != "":
			curr_level = int(level_text)
		level_file.close()
	
	var energy_file = _open_file("res://state/energy.txt", FileAccess.READ)
	if energy_file:
		var energy_text = energy_file.get_as_text().strip_edges()
		if energy_text != "":
			current_energy = float(energy_text)
		energy_file.close()
	

func reset_progression() -> void:
	curr_score = 0
	curr_level = 0
	current_energy = max_energy
	is_game_over = false
	
	_save_game_state()
	_update_score_ui()
	_update_energy_ui()
	

func reset_on_menu_return() -> void:
	reset_progression()

func register_vegetable(vegetable: Node2D) -> void:
	if not nearby_vegetables.has(vegetable):
		nearby_vegetables.append(vegetable)
		_update_is_in()

func unregister_vegetable(vegetable: Node2D) -> void:
	nearby_vegetables.erase(vegetable)
	if current_target_vegetable == vegetable:
		current_target_vegetable = null
	_update_is_in()

func _update_is_in() -> void:
	is_in = nearby_vegetables.size() > 0

func get_nearest_vegetable(player_position: Vector2) -> Node2D:
	if nearby_vegetables.is_empty():
		return null
	
	var nearest: Node2D = null
	var nearest_distance: float = INF
	
	for veg in nearby_vegetables:
		if not is_instance_valid(veg):
			nearby_vegetables.erase(veg)
			continue
		
		var distance = player_position.distance_to(veg.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = veg
	
	current_target_vegetable = nearest
	return nearest

func _check_ui_android(android: Control):
	if plateform == PC:
		android.visible = false
	else:
		android.visible = true

func _get_file_content(link: String):
	var fd = _open_file(link, FileAccess.READ)
	if not fd:
		return ""
	var content = fd.get_as_text()
	fd.close()
	return content

func _play_msc(stream: AudioStreamPlayer2D) -> void:
	stream.play()
	await get_tree().create_timer(1.2).timeout

func _open_file(link: String, flags: int)-> FileAccess:
	var fd: FileAccess = FileAccess.open(link, flags)
	return fd

func _write_in_file(content: String, fd: FileAccess) -> void:
	if fd and fd.is_open():
		fd.store_string(content)
		fd.close()

func _handle_checked(sound: AudioStreamPlayer2D, music: AudioStreamPlayer2D, state: bool, link: Array, btn: Button) -> void:
	btn.icon = link[int(state)]
	if state:
		sound.volume_db = mute_volume
		music.volume_db = mute_volume
	else:
		var fd = _open_file("res://state/volume_sound.txt", FileAccess.READ)
		if fd:
			sound.volume_db = float(fd.get_as_text())
			fd.close()
		fd = _open_file("res://state/last_volume.txt", FileAccess.READ)
		if fd:
			music.volume_db = float(fd.get_as_text())
			fd.close()

func _update_volume(audio: AudioStreamPlayer2D, value: float, link: String) -> void:
	audio.volume_db = audio.volume_db + (max_volume - min_volume) * value / 100.0
	_write_in_file(str(audio.volume_db), _open_file(link, FileAccess.WRITE))

func _update_slider(volume_value: float, slider: HSlider) -> void:
	if not slider:
		return
	var mapped = 100.0 * (volume_value - min_volume) / (max_volume - min_volume)
	slider.value = clamp(mapped, 0.0, 100.0)

func _update_slider_ui(new_value: float, label_ui: Label):
	label_ui.text = str(int(new_value)) + " %"

func _update_slider_ui_level(new_value: float, label_ui: Label):
	label_ui.text = "LEVEL " + str(int(new_value))
