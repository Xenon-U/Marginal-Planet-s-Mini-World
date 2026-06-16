extends Area2D

@export var next_scene_path: String = "res://Scenes2/场景2.tscn"
var switching = false

func _ready():
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if switching:
		return
	if body.is_in_group("player"):
		switching = true
		call_deferred("_change_scene")

func _change_scene():
	if ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("错误：找不到场景文件 ", next_scene_path)
