extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0
const INVINCIBLE_TIME = 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: Node = $HealthComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_attacking = false
var attack_combo = 0
var combo_window = false
var is_invincible = false
var is_dead = false

func _ready():
	collision_layer = 2
	collision_mask = 1
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	health_component.died.connect(_on_player_died)
	print("【玩家】血量:", health_component.current_health, "/", health_component.max_health)

func _input(_event):
	if is_dead:
		return
	if Input.is_action_just_pressed("attack"):
		if not is_attacking:
			start_attack(1)
		elif combo_window:
			start_attack(2)

func start_attack(combo_level: int):
	is_attacking = true
	combo_window = false
	attack_combo = combo_level
	
	if combo_level == 1:
		animated_sprite.play("攻击1")
		$Hitbox/CollisionShape2D.disabled = false
		await get_tree().create_timer(0.3).timeout
		$Hitbox/CollisionShape2D.disabled = true
		combo_window = true
		await get_tree().create_timer(0.5).timeout
		if combo_window:
			combo_window = false
			
	elif combo_level == 2:
		animated_sprite.play("攻击2")
		$Hitbox/CollisionShape2D.disabled = false
		await get_tree().create_timer(0.3).timeout
		$Hitbox/CollisionShape2D.disabled = true

func take_damage(amount: int):
	if is_invincible or is_dead:
		return
	health_component.take_damage(amount)
	print("【玩家】受伤! 血量:", health_component.current_health, "/", health_component.max_health)
	if health_component.is_alive():
		is_invincible = true
		await get_tree().create_timer(INVINCIBLE_TIME).timeout
		is_invincible = false

func _on_player_died():
	is_dead = true
	print("【玩家】死亡！")
	Engine.time_scale = 0.5
	collision_shape.queue_free()
	await get_tree().create_timer(1.0).timeout
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _on_animation_finished():
	if animated_sprite.animation == "攻击1" or animated_sprite.animation == "攻击2":
		is_attacking = false
		attack_combo = 0
		combo_window = false
		$Hitbox/CollisionShape2D.disabled = true

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction := Input.get_axis("move_left", "move_right")
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("待机")
			else:
				animated_sprite.play("跑")
		else:
			animated_sprite.play("跳")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	move_and_slide()
