extends Node2D

const SPEED = 60
var direction = 1

@onready var ray_cast_right: RayCast2D = $RayCastRight
@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: Node = $HealthComponent

func _ready():
	health_component.died.connect(_on_enemy_died)
	print("【史莱姆】血量:", health_component.current_health, "/", health_component.max_health)

func _process(delta: float) -> void:
	if not health_component.is_alive():
		return
	
	if ray_cast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	if ray_cast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	
	position.x += direction * SPEED * delta

func take_damage(amount: int):
	health_component.take_damage(amount)
	print("【史莱姆】受伤! 血量:", health_component.current_health, "/", health_component.max_health)

func _on_enemy_died():
	print("【史莱姆】死亡")
	queue_free()
