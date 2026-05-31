extends Area2D

@export var damage: int = 1

func _ready():
	add_to_group("enemy_hurtbox")
	# 编辑器里连过信号的话，这里不要写 body_entered.connect

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			var direction_x = 1.0 if body.global_position.x > global_position.x else -1.0
			body.take_damage(damage, direction_x)
