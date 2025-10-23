@tool
extends EditorScript

func _run() -> void:
	var scene_path = "res://scenes/game_ui.tscn"
	var game_ui_scene = load(scene_path)
	
	if not game_ui_scene:
		return
	
	var root = game_ui_scene.instantiate()
	
	if root.get_node_or_null("game_over_modal"):
		root.queue_free()
		return
	
	var modal = Control.new()
	modal.name = "game_over_modal"
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.visible = false
	
	root.add_child(modal)
	modal.owner = root
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.add_child(bg)
	bg.owner = root
	
	var panel = Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(500, 400)
	panel.position = Vector2(-250, -200)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.16, 0.05, 0.05)  
	panel_style.set_border_width_all(5)
	panel_style.border_color = Color(0.8, 0.0, 0.0) 
	panel_style.set_corner_radius_all(20)
	panel_style.shadow_size = 10
	panel_style.shadow_color = Color(0, 0, 0, 0.8)
	panel.add_theme_stylebox_override("panel", panel_style)
	
	modal.add_child(panel)
	panel.owner = root
	
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
	
	var title = Label.new()
	title.name = "Title"
	title.text = "💀 GAME OVER 💀"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	vbox.add_child(title)
	title.owner = root
	
	var spacer1 = Control.new()
	spacer1.name = "Spacer1"
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	spacer1.owner = root
	
	var message = Label.new()
	message.name = "Message"
	message.text = "You ran out of energy!"
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(message)
	message.owner = root
	
	var spacer2 = Control.new()
	spacer2.name = "Spacer2"
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	spacer2.owner = root
	
	var score_label = Label.new()
	score_label.name = "score_label"
	score_label.text = "Score: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	vbox.add_child(score_label)
	score_label.owner = root
	
	var level_label = Label.new()
	level_label.name = "level_label"
	level_label.text = "Level Reached: 0"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 24)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(level_label)
	level_label.owner = root
	
	var spacer3 = Control.new()
	spacer3.name = "Spacer3"
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)
	spacer3.owner = root
	
	var hbox = HBoxContainer.new()
	hbox.name = "HBoxContainer"
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox)
	hbox.owner = root
	
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
	
	hbox.add_child(btn_menu)
	btn_menu.owner = root
	
	var btn_retry = Button.new()
	btn_retry.name = "btn_retry"
	btn_retry.text = "RETRY"
	btn_retry.custom_minimum_size = Vector2(140, 60)
	btn_retry.add_theme_font_size_override("font_size", 26)
	
	var retry_normal = StyleBoxFlat.new()
	retry_normal.bg_color = Color(0.8, 0.2, 0.2)
	retry_normal.set_border_width_all(3)
	retry_normal.border_color = Color(1.0, 0.4, 0.4)
	retry_normal.set_corner_radius_all(10)
	btn_retry.add_theme_stylebox_override("normal", retry_normal)
	
	hbox.add_child(btn_retry)
	btn_retry.owner = root
	
	# Sauvegarder
	var packed = PackedScene.new()
	packed.pack(root)
	var result = ResourceSaver.save(packed, scene_path)
	

	root.queue_free()
