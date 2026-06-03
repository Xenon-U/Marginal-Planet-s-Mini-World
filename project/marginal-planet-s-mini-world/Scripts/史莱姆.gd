extends Node2D

const SPEED = 60
const KNOCKBACK_X = 120.0
const KNOCKBACK_Y = -60.0
const HITSTUN_TIME = 0.2
const GRAVITY = 400.0

var direction = 1
var ground_y: float

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_down: RayCast2D = $RayCastDown
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: Node = $HealthComponent

var is_in_hitstun = false
var knockback_vel: Vector2 = Vector2.ZERO

func _ready():
	ground_y = position.y
	health_component.died.connect(_on_enemy_died)
	health_component.damage_taken.connect(_on_damage_taken)
	print("【史莱姆】血量:", health_component.current_health, "/", health_component.max_health)

func _process(delta: float) -> void:
	if not health_component.is_alive():
		return
	
	# 击退飞行阶段
	if is_in_hitstun:
		knockback_vel.y += GRAVITY * delta
		position += knockback_vel * delta
		knockback_vel.x = move_toward(knockback_vel.x, 0, SPEED * delta)
		return
	
	# 击退结束后还在空中：继续下落直到落地
	if not is_in_hitstun and ray_cast_down.enabled:
		if not ray_cast_down.is_colliding():
			position.y += GRAVITY * delta
		else:
			# 落地
			position.y = ray_cast_down.get_collision_point().y - 12
			knockback_vel = Vector2.ZERO
	
	# 巡逻
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	
	position.x += direction * SPEED * delta

func take_damage(amount: int, direction_x: float = 0.0):
	health_component.take_damage(amount, direction_x)

func _on_damage_taken(_amount: int, direction_x: float):
	print("【史莱姆】受伤! 血量:", health_component.current_health, "/", health_component.max_health)
	
	is_in_hitstun = true
	ray_cast_down.enabled = false
	animated_sprite.play("受击")  # 播放受击动画
	
	var knockback_dir = direction_x if direction_x != 0 else -1.0
	knockback_vel = Vector2(KNOCKBACK_X * knockback_dir, KNOCKBACK_Y)
	
	await get_tree().create_timer(HITSTUN_TIME).timeout
	is_in_hitstun = false
	knockback_vel = Vector2.ZERO
	ray_cast_down.enabled = true
	animated_sprite.play("待机")   

func _on_enemy_died():
	print("【史莱姆】死亡")
	queue_free()
