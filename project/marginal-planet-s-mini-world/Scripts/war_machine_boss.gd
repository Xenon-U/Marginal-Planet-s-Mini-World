extends CharacterBody2D

enum State {
	IDLE_RANGED,
	IDLE_MELEE,
	SWITCH_TO_MELEE,
	MOVE,
	CHARGE,
	RANGED_ATTACK,
	MELEE_ATTACK,
	STUNNED,
	DEFEATED
}

@export var move_speed: float = 60.0
@export var charge_speed_multiplier: float = 5.0
@export var charge_distance: float = 200.0
@export var melee_switch_range: float = 150.0
@export var melee_attack_range: float = 60.0
@export var charge_max_range: float = 200.0
@export var ranged_attack_range: float = 400.0
@export var base_attack: int = 15
@export var retreat_distance: float = 2.0
@export var projectile_scene: PackedScene

# 击退相关
const KNOCKBACK_X: float = 120.0
const KNOCKBACK_Y: float = -80.0
const HITSTUN_TIME: float = 0.3

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var body_hitbox: Area2D = $BodyHitbox
@onready var melee_hitbox: Area2D = $MeleeHitbox
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var enter_combat_sound: AudioStreamPlayer = $EnterCombatSound
@onready var projectile_spawn: Marker2D = $ProjectileSpawnPoint

var current_state: State = State.IDLE_RANGED
var player: CharacterBody2D = null
var charge_start_position: Vector2
var charge_direction: int = 1

# 切换动画冷却（仅限制 SWITCH_TO_MELEE 动画的播放频率）
var last_switch_anim_time: float = -15.0
const SWITCH_ANIM_COOLDOWN: float = 15.0

func _ready():
	print("projectile_scene 是否为空：", projectile_scene == null)
	health.died.connect(_on_defeated)
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)

	body_hitbox.monitoring = false
	body_hitbox.get_node("CollisionShape2D").disabled = true
	melee_hitbox.monitoring = false
	melee_hitbox.get_node("CollisionShape2D").disabled = true

	body_hitbox.body_entered.connect(_on_attack_hitbox_entered)
	melee_hitbox.body_entered.connect(_on_attack_hitbox_entered)

	animated_sprite.play("idle_ranged")

func _physics_process(delta: float) -> void:
	if current_state == State.DEFEATED:
		return

	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)

		# 自动切换远近姿态（立即响应，不限制切换行为）
		if current_state in [State.IDLE_RANGED, State.IDLE_MELEE, State.MOVE]:
			if dist <= melee_switch_range and current_state != State.IDLE_MELEE:
				# 需要进入近战姿态
				if current_state == State.IDLE_RANGED:
					change_state(State.SWITCH_TO_MELEE)
				else:
					change_state(State.IDLE_MELEE)
			elif dist > melee_switch_range and current_state != State.IDLE_RANGED:
				change_state(State.IDLE_RANGED)

		match current_state:
			State.IDLE_RANGED, State.IDLE_MELEE:
				face_player()
				if attack_cooldown.is_stopped():
					choose_attack()
				else:
					change_state(State.MOVE)

			State.MOVE:
				move_toward_player(delta)
				if attack_cooldown.is_stopped():
					choose_attack()

			State.CHARGE:
				perform_charge(delta)

			State.MELEE_ATTACK, State.RANGED_ATTACK:
				pass

			State.STUNNED:
				if not is_on_floor():
					velocity += get_gravity() * delta
				velocity.x = move_toward(velocity.x, 0, move_speed * 2 * delta)
				move_and_slide()

		if current_state not in [State.CHARGE, State.MELEE_ATTACK, State.RANGED_ATTACK, State.STUNNED]:
			face_player()
	else:
		if current_state != State.IDLE_RANGED:
			change_state(State.IDLE_RANGED)
		velocity.x = 0
		move_and_slide()

func face_player():
	if player:
		var diff = player.global_position.x - global_position.x
		if abs(diff) > 2.0:
			animated_sprite.flip_h = diff > 0 

func move_toward_player(_delta):
	if not player: return
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = dir * move_speed
	animated_sprite.play("move")
	move_and_slide()

func perform_charge(_delta):
	velocity.x = charge_direction * move_speed * charge_speed_multiplier
	move_and_slide()
	var traveled = abs(global_position.x - charge_start_position.x)
	if traveled >= charge_distance or is_on_wall():
		end_charge()

func choose_attack():
	if not player: return
	var dist = global_position.distance_to(player.global_position)
	var rng = randf()

	# 近战姿态可用攻击
	if current_state in [State.IDLE_MELEE, State.SWITCH_TO_MELEE]:
		if dist <= melee_attack_range:
			if rng < 0.7:
				start_melee_attack()
			else:
				start_charge()
			return
		elif dist <= charge_max_range:
			if rng < 0.5:
				start_charge()
			else:
				change_state(State.IDLE_RANGED)
				start_ranged_attack()
			return
		else:
			change_state(State.IDLE_RANGED)
			start_ranged_attack()
			return

	# 远程姿态
	if current_state == State.IDLE_RANGED:
		if dist >= ranged_attack_range * 0.3:   # 降低门槛，让远程攻击更易触发
			if rng < 0.9:
				start_ranged_attack()
			else:
				start_charge()
			return
		else:
			# 距离较近，切换至近战姿态（交给物理帧自动处理）
			change_state(State.IDLE_MELEE)

func start_melee_attack():
	change_state(State.MELEE_ATTACK)
	attack_cooldown.start(1.5)
	animated_sprite.play("melee_attack")

	await get_tree().create_timer(0.3).timeout
	if current_state != State.MELEE_ATTACK: return
	melee_hitbox.monitoring = true
	melee_hitbox.get_node("CollisionShape2D").disabled = false

	await get_tree().create_timer(0.2).timeout
	melee_hitbox.monitoring = false
	melee_hitbox.get_node("CollisionShape2D").disabled = true

	if current_state == State.MELEE_ATTACK:
		change_state(State.IDLE_MELEE)

func start_charge():
	var back_dir = -1 if not animated_sprite.flip_h else 1
	global_position.x += back_dir * retreat_distance

	change_state(State.CHARGE)
	attack_cooldown.start(2.0)
	charge_start_position = global_position
	charge_direction = 1 if not animated_sprite.flip_h else -1
	animated_sprite.play("charge")

	body_hitbox.monitoring = true
	body_hitbox.get_node("CollisionShape2D").disabled = false

func end_charge():
	body_hitbox.monitoring = false
	body_hitbox.get_node("CollisionShape2D").disabled = true
	if current_state == State.CHARGE:
		change_state(State.IDLE_MELEE)

func start_ranged_attack():
	change_state(State.RANGED_ATTACK)
	attack_cooldown.start(2.0)
	animated_sprite.play("ranged_attack")

	await get_tree().create_timer(0.4).timeout
	if current_state != State.RANGED_ATTACK: return
	spawn_projectile()

	await get_tree().create_timer(0.3).timeout
	if current_state != State.RANGED_ATTACK: return
	spawn_projectile()

	await get_tree().create_timer(0.3).timeout
	if current_state == State.RANGED_ATTACK:
		change_state(State.IDLE_RANGED)

func spawn_projectile():
	if not projectile_scene:
		print("错误：projectile_scene 为空！")
		return
	var proj = projectile_scene.instantiate()
	proj.global_position = projectile_spawn.global_position
	proj.direction = (projectile_spawn.global_position.direction_to(player.global_position))
	proj.damage = 1
	get_parent().add_child(proj)
	print("投射物已生成，方向：", proj.direction, "位置：", proj.global_position)

func change_state(new_state: State):
	current_state = new_state
	match new_state:
		State.IDLE_RANGED:
			animated_sprite.play("idle_ranged")
		State.IDLE_MELEE:
			animated_sprite.play("idle_melee")
		State.SWITCH_TO_MELEE:
			# 切换动画冷却控制：15秒内只播一次，否则直接进入近战待机
			var time_since_last = Time.get_ticks_msec() / 1000.0 - last_switch_anim_time
			if time_since_last >= SWITCH_ANIM_COOLDOWN:
				animated_sprite.play("switch_to_melee")
				last_switch_anim_time = Time.get_ticks_msec() / 1000.0
				await get_tree().create_timer(0.9).timeout
				if current_state == State.SWITCH_TO_MELEE:
					change_state(State.IDLE_MELEE)
			else:
				change_state(State.IDLE_MELEE)
		State.MOVE:
			animated_sprite.play("move")
		State.STUNNED:
			if animated_sprite.sprite_frames.has_animation("hurt"):
				animated_sprite.play("hurt")

func _on_attack_hitbox_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		var dir = sign(body.global_position.x - global_position.x)
		var dmg = base_attack
		if current_state == State.MELEE_ATTACK:
			dmg = 2
		elif current_state == State.CHARGE:
			dmg = 3
		body.take_damage(dmg, dir)

func _on_player_entered(body):
	if body.is_in_group("player") and current_state == State.IDLE_RANGED:
		player = body
		if enter_combat_sound:
			enter_combat_sound.play()

func _on_player_exited(body):
	if body == player:
		pass

func take_damage(amount: int, direction_x: float = 0.0):
	if current_state == State.DEFEATED or not health.is_alive():
		return
	print("Boss 受到伤害：", amount, " 剩余血量：", health.current_health)
	health.take_damage(amount)
	# 后面代码不变...
	if not health.is_alive():
		return

	# 进入硬直状态并添加击退
	change_state(State.STUNNED)

	var knockback_dir = direction_x if direction_x != 0 else 1.0
	velocity = Vector2(KNOCKBACK_X * knockback_dir, KNOCKBACK_Y)

	await get_tree().create_timer(HITSTUN_TIME).timeout
	if current_state == State.STUNNED:
		if player and global_position.distance_to(player.global_position) <= melee_switch_range:
			change_state(State.IDLE_MELEE)
		else:
			change_state(State.IDLE_RANGED)

func _on_defeated():
	if current_state == State.DEFEATED:
		return   # 防止重复执行
	print("Boss 进入 DEFEATED 状态")
	current_state = State.DEFEATED
	if animated_sprite.sprite_frames.has_animation("defeated"):
		animated_sprite.play("defeated")
	else:
		animated_sprite.play("idle_melee")

	# 使用 set_deferred 避免 flushing queries 错误
	body_hitbox.set_deferred("monitoring", false)
	body_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	melee_hitbox.set_deferred("monitoring", false)
	melee_hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
