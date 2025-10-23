@tool
extends EditorScript

func _run() -> void:
	var files = [
		"res://state/score.txt",
		"res://state/level.txt",
		"res://state/energy.txt",
		"res://state/volume_sound.txt",
		"res://state/last_volume.txt",
		"res://state/mute.txt"
	]
	
	for file_path in files:
		var import_path = file_path + ".import"
		var import_file = FileAccess.open(import_path, FileAccess.WRITE)
		if import_file:
			import_file.store_string("""[remap]

importer="keep"
type="Resource"

[params]
""")
			import_file.close()
			print("✅ Créé: ", import_path)
	
	print("✅ Tous les fichiers .import créés!")
	print("🔄 Redémarrez Godot pour appliquer les changements")
