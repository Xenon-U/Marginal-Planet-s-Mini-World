extends Area2D

@export var next_scene_path: String = "res://Scenes/Level2.tscn"

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_tree().change_scene_to_file(next_scene_path)
