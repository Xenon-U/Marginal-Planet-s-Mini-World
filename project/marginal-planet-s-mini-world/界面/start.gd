extends Control

func _on_start_pressed() -> void:
	#点击开始按钮跳转到游戏页面
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")
