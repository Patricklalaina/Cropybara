extends VBoxContainer

@onready var buttons = [$Play, $Options, $help, $quit]
var selected_index := 0
@onready var sound: AudioStreamPlayer2D = $"../sound"
@onready var music: AudioStreamPlayer2D = $"../music"
@onready var sound_slider: HSlider = $"../option/VBoxContainer/sound_ctrl/sound_slider"
@onready var music_slider: HSlider = $"../option/VBoxContainer/music_ctrl/music_slider"
var is_mute: bool = false
const CHECKED = preload("res://assets/volume/checked.png")
const BOX = preload("res://assets/volume/box.png")
var mute_state: FileAccess
var last_state_sound: float
var last_state_music: float

var list_help: Array = [
	"GAME OBJECTIVE\n\n\
	Eat all the farmer's crops\n\
	without getting caught!\n\n\
	Reach the quota to advance to\n\
	the next level.\n\n\
	WARNING: If the farmer sees you,\n\
	it's GAME OVER!",
	
	"CONTROLS\n\
	PC:\n\
	  - Arrows / WASD: Move\n\
	  - Space: Eat / Hide\n\
	  - Shift: Sprint (uses energy)\n\
	  - ESC: Menu\n\
	MOBILE:\n\
	  - Virtual joystick to move\n\
	  - Eat button: Harvest crops\n\
	  - Sprint button: Run faster\n\
	  - Hide button: Hide in spots",
	
	"ENERGY SYSTEM\n\
	Your energy depletes when:\n\
	  - Sprinting (fast)\n\
	  - Low energy (slow drain)\n\
	Restore energy by:\n\
	  - Eating crops (+5 energy)\n\
	WARNING:\n\
	Speed decreases below 20%\n\
	GAME OVER at 0% energy!\n\
	Manage your energy wisely!",
	
	"PROGRESSION SYSTEM\n\
	Each level has a quota:\n\
	  - Level 1: 45 points\n\
	  - Level 2: 100 points\n\
	  - Level 3: 200 points\n\
	  - Level 4: 400 points\n\
	  - Level 5: 682 points\n\
	Crops give different points:\n\
	  - Carrot: 10 points\n\
	  - Wheat: 8-15 points\n\
	Energy fully restored on level up!",
	
	"BEWARE OF THE FARMER!\n\
	The farmer patrols his field:\n\
	  - Follows marker waypoints\n\
	  - Has a cone of vision (red)\n\
	  - Gets FASTER each level!\n\
	  - Wider vision at high levels\n\
	If he sees you: GAME OVER\n\
	Watch his movements carefully\n\
	and stay out of his sight!",
	
	"HIDING SPOTS\n\
	Hide to avoid the farmer:\n\
	  - Press Space / Hide button\n\
	  - You're invisible for 10s\n\
	  - Progress bar shows time left\n\
	  - 5s cooldown after each use\n\
	TIP: Highlighted when nearby\n\
	The farmer can't see you inside\n\
	Use them strategically!",
	
	"PROGRESSIVE DIFFICULTY\n\
	Each level increases:\n\
	  - Farmer speed: +15/level\n\
	  - Vision range: +20/level\n\
	  - Vision angle: +5 degrees/level\n\
	  - Patrol speed: faster pauses\n\
	Higher levels = Higher challenge!\n\
	Plan your route carefully\n\
	and use hiding spots wisely.",
	
	"TIPS AND STRATEGIES\n\
	> Plan your route beforehand\n\
	> Watch the farmer's patrol\n\
	> Use hiding spots when close\n\
	> Sprint only when necessary\n\
	> Eat crops to restore energy\n\
	> Avoid low energy situations\n\
	> Stay behind the farmer\n\
	> Crops near walls are safer\n\
	Be smart, be fast, survive!",
	
	"GAME OVER CONDITIONS\n\
	You lose if:\n\
	  - Farmer sees you (instant)\n\
	  - Energy reaches 0%\n\
	SCORING SYSTEM\n\
	Points are saved automatically\n\
	Track your progress:\n\
	  - Score counter (top left)\n\
	  - Level progress bar\n\
	  - Energy bar (critical!)\n\
	Try to reach the highest level!",
	
	"SAVE SYSTEM\n\
	Your progress is saved:\n\
	  > Current score\n\
	  > Current level\n\
	  > Energy amount\n\
	  > Audio settings\n\
	Progress resets on:\n\
	  - Returning to menu\n\
	  - Game Over\n\
	Complete all levels in one run\n\
	for the ultimate challenge!"
]



@onready var help_idx: int = 0

var _updating_sliders: bool = false

func _ready() -> void:
	$"../verification".visible = false
	$"../option".visible = false

	mute_state = GameManager._open_file("res://state/mute.txt", FileAccess.READ)
	if mute_state:
		var val = mute_state.get_as_text()
		is_mute = bool(int(val))
		mute_state.close()

	GameManager._handle_checked(sound, music, is_mute, [BOX, CHECKED], $"../option/VBoxContainer/HBoxContainer3/Button")

	_updating_sliders = true
	var fd = GameManager._open_file("res://state/volume_sound.txt", FileAccess.READ)
	if fd:
		GameManager._update_slider(float(fd.get_as_text()), sound_slider)
		fd.close()

	fd = GameManager._open_file("res://state/last_volume.txt", FileAccess.READ)
	if fd:
		GameManager._update_slider(float(fd.get_as_text()), music_slider)
		fd.close()
	last_state_sound = sound_slider.value
	last_state_music = music_slider.value
	_updating_sliders = false
	$"../help".visible = false
	$"../help/VBoxContainer/help_desc".text = list_help[help_idx]
	$"../help/VBoxContainer/HBoxContainer/back".disabled = true

func _on_play_pressed() -> void:
	await GameManager._play_msc(sound)
	get_tree().change_scene_to_file("res://intro.tscn")


func _on_options_pressed() -> void:
	await GameManager._play_msc(sound)
	$"../option".visible = true


func _on_help_pressed() -> void:
	await GameManager._play_msc(sound)
	$"../help".visible = true


func _on_quit_pressed() -> void:
	await GameManager._play_msc(sound)
	$"../verification".visible = true
	if mute_state and mute_state.is_open():
		mute_state.close()


func _on_cancel_pressed() -> void:
	await GameManager._play_msc(sound)
	$"../verification".visible = false


func _on_exit_pressed() -> void:
	await GameManager._play_msc(sound)
	get_tree().quit(0)


func _on_button_pressed() -> void:
	is_mute = !is_mute
	GameManager._handle_checked(sound, music, is_mute, [BOX, CHECKED], $"../option/VBoxContainer/HBoxContainer3/Button")
	mute_state = GameManager._open_file("res://state/mute.txt", FileAccess.WRITE)
	GameManager._write_in_file(str(int(is_mute)), mute_state)

func _on_quit_opt_pressed() -> void:
	await GameManager._play_msc(sound)
	$"../option".visible = false


func _on_music_finished() -> void:
	$"../music".play(0.0)


func _on_sound_slider_value_changed(value: float) -> void:
	if _updating_sliders:
		return
	GameManager._update_volume(sound, value - last_state_sound, "res://state/volume_sound.txt")
	last_state_sound = value


func _on_music_slider_value_changed(value: float) -> void:
	if _updating_sliders:
		return
	GameManager._update_volume(music, value - last_state_music, "res://state/last_volume.txt")
	last_state_music = value


func _on_menu_pressed() -> void:
	await GameManager._play_msc(sound)
	$"../help".visible = false


func _on_next_pressed() -> void:
	help_idx = (help_idx + 1)
	if help_idx >= len(list_help) - 1:
		$"../help/VBoxContainer/HBoxContainer/next".disabled = true
	if help_idx > 0:
		$"../help/VBoxContainer/HBoxContainer/back".disabled = false
	$"../help/VBoxContainer/help_desc".text = list_help[help_idx]


func _on_back_pressed() -> void:
	help_idx = (help_idx - 1)
	if help_idx - 1 < 0:
		$"../help/VBoxContainer/HBoxContainer/back".disabled = true
	if help_idx < len(list_help) - 1:
		$"../help/VBoxContainer/HBoxContainer/next".disabled = false
	$"../help/VBoxContainer/help_desc".text = list_help[help_idx]
