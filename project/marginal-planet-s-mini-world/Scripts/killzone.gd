extends Area2D

func _ready():
	pass

func _on_body_entered(body: Node2D) -> void:
	# 只对玩家造成即死伤害
	if body.is_in_group("player") and body.has_method("take_damage"):
		# 方向参数传 0，表示无击退方向（坠落伤害不击退）
		body.take_damage(99999, 0)
