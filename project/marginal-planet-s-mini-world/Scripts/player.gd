extends CharacterBody2D

const SPEED = 100.0
const JUMP_VELOCITY = -300.0
const INVINCIBLE_TIME = 1.0
const COYOTE_TIME = 0.12
const KNOCKBACK_X = 100.0
const KNOCKBACK_Y = -150.0
const HITSTUN_TIME = 0.2

const ROLL_DISTANCE = 64.0
const ROLL_DURATION = 0.5
const ROLL_SPEED = SPEED * 1.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: Node = $HealthComponent
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_attacking = false
var attack_combo = 0
var combo_window = false
var is_invincible = false
var is_dead = false
var is_in_hitstun = false
var is_rolling = false
var coyote_timer = 0.0
var hud: Node
var roll_direction = 1
var pending_direction = 0
var white_shader: ShaderMaterial

# 翻滚相关计时
var roll_timer: float = 0.0
var roll_initial_speed: float = 0.0
var roll_target_speed: float = 0.0
var post_roll_invincible_timer: float = 0.0   # 翻滚结束后的额外无敌时间

func _ready():
	collision_layer = 2
	collision_mask = 1
	add_to_group("player")
	animated_sprite.animation_finished.connect(_on_animation_finished)
	health_component.died.connect(_on_player_died)
	health_component.damage_taken.connect(_on_damage_taken)

	# 创建白色闪烁着色器
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
    vec4 col = texture(TEXTURE, UV);
    col.rgb = vec3(1.0);
    COLOR = col;
}
"""
	white_shader = ShaderMaterial.new()
	white_shader.shader = shader

	# 安全连接血量变化信号（避免重复连接）
	if not health_component.health_changed.is_connected(_on_health_changed):
		health_component.health_changed.connect(_on_health_changed)

	# 获取 HUD 并初始化血条显示
	hud = get_tree().current_scene.get_node("HUD")
	if hud:
		_on_health_changed(health_component.current_health, health_component.max_health)
	else:
		print("警告：未找到 HUD 节点，血条不会更新")

	print("【玩家】血量:", health_component.current_health, "/", health_component.max_health)

func _input(_event):
	if is_dead or is_rolling:
		return

	# 硬直中允许用翻滚打断
	if is_in_hitstun:
		if Input.is_action_just_pressed("roll"):
			start_roll()
		return

	if Input.is_action_just_pressed("attack"):
		if not is_attacking:
			start_attack(1)
		elif combo_window:
			start_attack(2)
	if Input.is_action_just_pressed("roll"):
		start_roll()

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

func start_roll():
	# 如果正在硬直，先打断硬直
	if is_in_hitstun:
		is_in_hitstun = false
		velocity = Vector2.ZERO

	is_rolling = true
	is_attacking = false
	$Hitbox/CollisionShape2D.disabled = true
	is_invincible = true          # 全程无敌

	roll_direction = -1 if animated_sprite.flip_h else 1
	roll_initial_speed = velocity.x
	roll_target_speed = ROLL_SPEED * roll_direction
	roll_timer = 0.0
	post_roll_invincible_timer = 0.0

	animated_sprite.play("翻滚")

func take_damage(amount: int, direction_x: float = 0.0):
	if is_dead:
		return

	# 翻滚中或翻滚结束后的短暂无敌
	if is_rolling or post_roll_invincible_timer > 0.0:
		flash_white()
		if not is_invincible:
			health_component.take_damage(amount, direction_x)
		return

	if is_invincible:
		return
	health_component.take_damage(amount, direction_x)
	if health_component.is_alive():
		is_invincible = true
		await get_tree().create_timer(INVINCIBLE_TIME).timeout
		is_invincible = false

func flash_white():
	animated_sprite.material = white_shader
	await get_tree().create_timer(0.1).timeout
	if animated_sprite.material == white_shader:
		animated_sprite.material = null

func _on_damage_taken(_amount: int, direction_x: float):
	print("【玩家】受伤! 血量:", health_component.current_health, "/", health_component.max_health)

	if is_rolling or post_roll_invincible_timer > 0.0:
		return

	is_in_hitstun = true
	is_attacking = false
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)

	animated_sprite.play("受击")

	var knockback_dir = direction_x if direction_x != 0 else 1.0
	velocity = Vector2(KNOCKBACK_X * knockback_dir, KNOCKBACK_Y)

	await get_tree().create_timer(HITSTUN_TIME).timeout
	is_in_hitstun = false

func _on_player_died():
	if is_dead:
		return
	is_dead = true
	print("【玩家】死亡！")

	# 播放死亡动画
	animated_sprite.play("死亡")
	# 禁用碰撞体，防止后续物理交互
	collision_shape.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)

	# 短暂等待，让死亡动画播放一段时间（可根据动画时长调整）
	await get_tree().create_timer(0.5).timeout

	# 调用 HUD 的黑屏+文字序列
	if not hud:
		hud = get_tree().current_scene.get_node("HUD")
	if hud:
		hud.start_death_sequence()

func _on_animation_finished():
	var anim = animated_sprite.animation

	if anim == "攻击1" or anim == "攻击2":
		is_attacking = false
		attack_combo = 0
		combo_window = false
		$Hitbox/CollisionShape2D.disabled = true

	elif anim == "翻滚":
		if is_rolling:
			is_rolling = false
			is_invincible = false
			post_roll_invincible_timer = 0.1
			if pending_direction != 0:
				animated_sprite.flip_h = (pending_direction == -1)
			pending_direction = 0

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# 更新翻滚结束后的额外无敌计时器
	if post_roll_invincible_timer > 0.0:
		post_roll_invincible_timer -= delta
		if post_roll_invincible_timer <= 0.0:
			post_roll_invincible_timer = 0.0

	# ========== 翻滚处理 ==========
	if is_rolling:
		roll_timer += delta

		var t = roll_timer / ROLL_DURATION
		var desired_speed: float
		if t <= 0.2:
			desired_speed = lerp(roll_initial_speed, roll_target_speed, t / 0.2)
		elif t <= 0.8:
			desired_speed = roll_target_speed
		else:
			desired_speed = lerp(roll_target_speed, 0.0, (t - 0.8) / 0.2)

		velocity.x = desired_speed
		if not is_on_floor():
			velocity += get_gravity() * delta
		else:
			velocity.y = 0

		var dir = Input.get_axis("move_left", "move_right")
		if dir != 0:
			pending_direction = dir

		if roll_timer >= ROLL_DURATION:
			is_rolling = false
			is_invincible = false       # 结束无敌
			velocity.x = 0
			post_roll_invincible_timer = 0.1   # 可保留额外保护
			if pending_direction != 0:
				animated_sprite.flip_h = (pending_direction == -1)
			pending_direction = 0

		move_and_slide()
		return

	# ========== 硬直处理 ==========
	if is_in_hitstun:
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	# ========== 正常移动 ==========
	if not is_on_floor():
		velocity += get_gravity() * delta

	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		if is_on_floor() or coyote_timer > 0:
			velocity.y = JUMP_VELOCITY
			coyote_timer = 0

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

func _on_health_changed(current: int, max_hp: int):
	if hud:
		hud.set_health(current, max_hp)
