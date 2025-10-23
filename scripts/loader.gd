extends Control

@onready var chargement: TextureProgressBar = $chargement
@onready var percent: Label = $chargement/value
var path_scene: Array = []
var current_index: int = 0
var loading_started: bool = false
var all_loaded: bool = false
var i: int = 0
var time: float = 0.0
@onready var animation: Sprite2D = $ColorRect/animation
var dist: float = 964.0
@onready var component: Label = $component

func _ready():
	path_scene = get_all_files("res://")
	
	
	$ColorRect/player.play("loader")
	chargement.value = 0
	dist = dist - chargement.position.x
	animation.position.x = chargement.position.x
	$chargement/value.text = "0%"
	await get_tree().create_timer(2.0).timeout
	start_next_load()

func get_all_files(path: String) -> Array:
	var files: Array = []
	var dir = DirAccess.open(path)
	
	if dir == null:
		return files
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name == "." or file_name == ".." or file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		
		var full_path = path.path_join(file_name)
		
		if dir.current_is_dir():
			files.append_array(get_all_files(full_path))
		else:
			if is_loadable_file(file_name):
				files.append(full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files

func is_loadable_file(file_name: String) -> bool:
	var loadable_extensions = [
		".tscn", ".scn",           # Scènes
		".tres", ".res",           # Ressources
		".gd", ".gdshader",        # Scripts
		".png", ".jpg", ".jpeg", ".svg", ".bmp", ".webp",  # Images
		".wav", ".ogg", ".mp3",    # Audio
		".ttf", ".otf", ".woff", ".woff2",  # Fonts
		".glb", ".gltf",           # 3D
		".obj", ".fbx"             # 3D
	]
	
	for ext in loadable_extensions:
		if file_name.ends_with(ext):
			return true
	
	return false

func start_next_load():
	if current_index < path_scene.size():
		ResourceLoader.load_threaded_request(path_scene[current_index])
		loading_started = true
	else:
		all_loaded = true

func _process(_delta: float) -> void:
	if all_loaded:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	
	if loading_started and current_index < path_scene.size():
		var progress: Array = [0.0]
		component.text = "| Load " + path_scene[current_index] + "..."
		var status = ResourceLoader.load_threaded_get_status(path_scene[current_index], progress)
		
		# Calcul de la progression totale
		var total_progress = (float(current_index) + progress[0]) / float(path_scene.size())
		chargement.value = total_progress * 100
		percent.text = str(int(total_progress * 100)) + "%"
		animation.position.x = chargement.position.x + chargement.value * dist / 100
		
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			current_index += 1
			loading_started = false
			start_next_load()
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			#print("❌ Erreur de chargement : ", path_scene[current_index])
			current_index += 1
			loading_started = false
			start_next_load()
