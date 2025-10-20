@tool
extends EditorScript

func _run() -> void:
	var scene_path = "res://scenes/game_ui.tscn"
	var game_ui_scene = load(scene_path)
	
	if not game_ui_scene:
		#print("❌ Impossible de charger ", scene_path)
		return
	
	var root = game_ui_scene.instantiate()
	
	# Vérifier si le modal existe déjà
	if root.get_node_or_null("congratulations_modal"):
		#print("⚠️ Le modal existe déjà!")
		root.queue_free()
		return
	
	# Créer le modal
	var modal = Control.new()
	modal.name = "congratulations_modal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.visible = false
	
	# ✅ CORRECTION : Ajouter le modal à la racine AVANT d'ajouter ses enfants
	root.add_child(modal)
	modal.owner = root
	
	# Fond
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(bg)
	bg.owner = root
	
	# Panel
	var panel = Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(500, 400)
	panel.position = Vector2(-250, -200)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.16, 0.16, 0.16)
	panel_style.set_border_width_all(5)
	panel_style.border_color = Color(1.0, 0.78, 0.0)
	panel_style.set_corner_radius_all(20)
	panel_style.shadow_size = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	modal.add_child(panel)
	panel.owner = root
	
	# VBoxContainer
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 30
	vbox.offset_top = 30
	vbox.offset_right = -30
	vbox.offset_bottom = -30
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	vbox.owner = root
	
	# Titre
	var title = Label.new()
	title.name = "Title"
	title.text = "🎊 CONGRATULATIONS! 🎊"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	vbox.add_child(title)
	title.owner = root
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.name = "Spacer1"
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	spacer1.owner = root
	
	# Message
	var message = Label.new()
	message.name = "Message"
	message.text = "You completed all levels!\n\nYou are the ultimate capybara!"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color(0.86, 0.86, 0.86))
	vbox.add_child(message)
	message.owner = root
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.name = "Spacer2"
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	spacer2.owner = root
	
	# Score
	var score_label = Label.new()
	score_label.name = "score_label"
	score_label.text = "Final Score: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.5))
	vbox.add_child(score_label)
	score_label.owner = root
	
	# Spacer
	var spacer3 = Control.new()
	spacer3.name = "Spacer3"
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)
	spacer3.owner = root
	
	# HBoxContainer pour les boutons
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox)
	hbox.owner = root
	
	# Bouton Menu
	var btn_menu = Button.new()
	btn_menu.name = "btn_menu"
	btn_menu.text = "MENU"
	btn_menu.custom_minimum_size = Vector2(140, 60)
	btn_menu.add_theme_font_size_override("font_size", 26)
	
	var menu_normal = StyleBoxFlat.new()
	menu_normal.bg_color = Color(0.27, 0.27, 0.35)
	menu_normal.set_border_width_all(3)
	menu_normal.border_color = Color(0.59, 0.59, 0.78)
	menu_normal.set_corner_radius_all(10)
	btn_menu.add_theme_stylebox_override("normal", menu_normal)
	
	var menu_hover = StyleBoxFlat.new()
	menu_hover.bg_color = Color(0.35, 0.35, 0.47)
	menu_hover.set_border_width_all(3)
	menu_hover.border_color = Color(0.59, 0.59, 0.78)
	menu_hover.set_corner_radius_all(10)
	btn_menu.add_theme_stylebox_override("hover", menu_hover)
	
	var menu_pressed = StyleBoxFlat.new()
	menu_pressed.bg_color = Color(0.2, 0.2, 0.27)
	menu_pressed.set_border_width_all(3)
	menu_pressed.border_color = Color(0.59, 0.59, 0.78)
	menu_pressed.set_corner_radius_all(10)
	btn_menu.add_theme_stylebox_override("pressed", menu_pressed)
	
	hbox.add_child(btn_menu)
	btn_menu.owner = root
	
	# Bouton Replay
	var btn_replay = Button.new()
	btn_replay.name = "btn_replay"
	btn_replay.text = "REPLAY"
	btn_replay.custom_minimum_size = Vector2(140, 60)
	btn_replay.add_theme_font_size_override("font_size", 26)
	
	var replay_normal = StyleBoxFlat.new()
	replay_normal.bg_color = Color(0.13, 0.55, 0.13)
	replay_normal.set_border_width_all(3)
	replay_normal.border_color = Color(0.56, 0.93, 0.56)
	replay_normal.set_corner_radius_all(10)
	btn_replay.add_theme_stylebox_override("normal", replay_normal)
	
	var replay_hover = StyleBoxFlat.new()
	replay_hover.bg_color = Color(0.2, 0.7, 0.2)
	replay_hover.set_border_width_all(3)
	replay_hover.border_color = Color(0.56, 0.93, 0.56)
	replay_hover.set_corner_radius_all(10)
	btn_replay.add_theme_stylebox_override("hover", replay_hover)
	
	var replay_pressed = StyleBoxFlat.new()
	replay_pressed.bg_color = Color(0.1, 0.39, 0.1)
	replay_pressed.set_border_width_all(3)
	replay_pressed.border_color = Color(0.56, 0.93, 0.56)
	replay_pressed.set_corner_radius_all(10)
	btn_replay.add_theme_stylebox_override("pressed", replay_pressed)
	
	hbox.add_child(btn_replay)
	btn_replay.owner = root
	
	# Sauvegarder
	var packed = PackedScene.new()
	packed.pack(root)
	var result = ResourceSaver.save(packed, scene_path)
	
	
	root.queue_free()
