extends AnimationPlayer

func _ready():
	animation_finished.connect(_on_animation_finished)
	play("intro")

func _on_animation_finished(anim_name: String) -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
