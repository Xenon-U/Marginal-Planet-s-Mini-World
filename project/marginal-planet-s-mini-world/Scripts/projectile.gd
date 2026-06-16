extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: int = 1

func _ready():
	collision_layer = 0
	collision_mask = 0
	# 0.05 秒后启用碰撞
	await get_tree().create_timer(0.15).timeout
	collision_layer = 5
	collision_mask = 3
	if not body_entered.is_connected(_on_hit):
		body_entered.connect(_on_hit)

func _physics_process(_delta: float) -> void:
	position += direction * speed * _delta
	# 飞出屏幕自动销毁
	#var screen_rect = get_viewport().get_visible_rect()
	#if not screen_rect.has_point(global_position):
		#queue_free()

func _on_hit(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, direction.x)
	queue_free()
