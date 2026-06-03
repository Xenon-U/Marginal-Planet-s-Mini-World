extends Area2D
@export var next_scene:PackedScene

func _ready():
	body_entered.connect(_player_touch)

func _player_touch(body:Node2D):
	if body.name == "CharacterBody2D":
		get_tree().change_scene_to_packed(next_scene)
