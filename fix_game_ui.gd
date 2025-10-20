@tool
extends EditorScript

func _run():
	# Charger la scène
	var scene = load("res://scenes/game_ui.tscn")
	if not scene:
		print("❌ Impossible de charger game_ui.tscn")
		return
	
	var root = scene.instantiate()
	var android = root.get_node("android")
	
	# Supprimer l'ancien btn_eat s'il existe
	var old_eat = android.get_node_or_null("btn_eat")
	if old_eat:
		old_eat.queue_free()
	
	# Créer le nouveau btn_eat (Button au lieu de TextureButton)
	var btn_eat = Button.new()
	btn_eat.name = "btn_eat"
	btn_eat.text = "🍽️"
	
	# Style orange moderne
	var eat_normal = StyleBoxFlat.new()
	eat_normal.bg_color = Color(1.0, 0.5, 0.2, 0.9)
	eat_normal.set_border_width_all(4)
	eat_normal.border_color = Color(1, 1, 1, 0.9)
	eat_normal.set_corner_radius_all(45)
	eat_normal.shadow_size = 6
	eat_normal.shadow_color = Color(0, 0, 0, 0.4)
	eat_normal.shadow_offset = Vector2(0, 3)
	
	var eat_pressed = StyleBoxFlat.new()
	eat_pressed.bg_color = Color(0.8, 0.4, 0.15, 1.0)
	eat_pressed.set_border_width_all(4)
	eat_pressed.border_color = Color(0.9, 0.9, 0.9, 1)
	eat_pressed.set_corner_radius_all(45)
	eat_pressed.shadow_size = 3
	eat_pressed.shadow_color = Color(0, 0, 0, 0.6)
	eat_pressed.shadow_offset = Vector2(0, 1)
	
	btn_eat.add_theme_stylebox_override("normal", eat_normal)
	btn_eat.add_theme_stylebox_override("pressed", eat_pressed)
	btn_eat.add_theme_font_size_override("font_size", 42)
	
	# Position
	btn_eat.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_eat.offset_left = -230
	btn_eat.offset_top = -210
	btn_eat.offset_right = -150
	btn_eat.offset_bottom = -130
	
	android.add_child(btn_eat)
	btn_eat.owner = root
	
	# Créer btn_sprint
	var btn_sprint = Button.new()
	btn_sprint.name = "btn_sprint"
	btn_sprint.text = "⚡"
	
	# Style vert moderne
	var sprint_normal = StyleBoxFlat.new()
	sprint_normal.bg_color = Color(0.2, 0.8, 0.5, 0.9)
	sprint_normal.set_border_width_all(4)
	sprint_normal.border_color = Color(1, 1, 1, 0.9)
	sprint_normal.set_corner_radius_all(45)
	sprint_normal.shadow_size = 6
	sprint_normal.shadow_color = Color(0, 0, 0, 0.4)
	sprint_normal.shadow_offset = Vector2(0, 3)
	
	var sprint_pressed = StyleBoxFlat.new()
	sprint_pressed.bg_color = Color(0.15, 0.6, 0.4, 1.0)
	sprint_pressed.set_border_width_all(4)
	sprint_pressed.border_color = Color(0.9, 0.9, 0.9, 1)
	sprint_pressed.set_corner_radius_all(45)
	sprint_pressed.shadow_size = 3
	sprint_pressed.shadow_color = Color(0, 0, 0, 0.6)
	sprint_pressed.shadow_offset = Vector2(0, 1)
	
	btn_sprint.add_theme_stylebox_override("normal", sprint_normal)
	btn_sprint.add_theme_stylebox_override("pressed", sprint_pressed)
	btn_sprint.add_theme_font_size_override("font_size", 38)
	
	# Position
	btn_sprint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_sprint.offset_left = -380
	btn_sprint.offset_top = -100
	btn_sprint.offset_right = -300
	btn_sprint.offset_bottom = -20
	
	android.add_child(btn_sprint)
	btn_sprint.owner = root
	
	# Sauvegarder
	var packed = PackedScene.new()
	packed.pack(root)
	ResourceSaver.save(packed, "res://scenes/game_ui.tscn")
	
	print("✅ game_ui.tscn réparé avec succès!")
	
	root.queue_free()
