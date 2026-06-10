extends Area2D



func _on_area_2d_body_entered(body: Node2D) -> void:
	print（“+1 coin!”）
	queue_free()
