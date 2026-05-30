extends Area2D

func _ready():
	add_to_group("player_hitbox")
	monitoring = true
	monitorable = false
	$CollisionShape2D.disabled = true
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(1)
