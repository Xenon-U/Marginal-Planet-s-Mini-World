extends Node

@export var knockback_strength_x: float = 150.0  # 横向击退力度
@export var knockback_strength_y: float = -80.0  # 纵向击退力度（负值向上）
@export var hitstun_duration: float = 0.2        # 硬直时间

var is_in_hitstun = false
var knockback_velocity: Vector2 = Vector2.ZERO

signal knockback_applied

func apply_knockback(target: Node2D, direction_x: float = 1.0):
	"""
	target: 被击退的角色节点
	direction_x: 击退方向，1=向右，-1=向左
	"""
	if is_in_hitstun:
		return
	
	is_in_hitstun = true
	
	# 设置击退速度
	knockback_velocity = Vector2(
		knockback_strength_x * direction_x,
		knockback_strength_y
	)
	
	# 应用击退
	if target is CharacterBody2D:
		target.velocity = knockback_velocity
	else:
		# Node2D 类型（比如史莱姆），用位置移动
		pass
	
	knockback_applied.emit()
	
	# 硬直计时
	await target.get_tree().create_timer(hitstun_duration).timeout
	is_in_hitstun = false
	knockback_velocity = Vector2.ZERO
