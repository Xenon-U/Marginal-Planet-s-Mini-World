extends Area2D

@export var damage: int = 1

func _ready():
	add_to_group("enemy_hurtbox")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
