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
			# 根据玩家朝向决定击退方向
			var player = get_parent()
			var direction_x = 1.0 if not player.animated_sprite.flip_h else -1.0
			enemy.take_damage(1, direction_x)
