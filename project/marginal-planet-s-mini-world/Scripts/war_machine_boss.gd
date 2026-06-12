extends CharacterBody2D

enum State {
	IDLE_RANGED,        # 远程待机（初始）
	IDLE_MELEE,         # 近战待机
	SWITCH_TO_MELEE,    # 远程→近战过渡动画
	MOVE,               # 正常移动（无伤害）
	CHARGE,             # 冲锋攻击
	RANGED_ATTACK,      # 远程攻击（预留，暂未实现）
	MELEE_ATTACK,       # 近战攻击
	STUNNED,            # 受击硬直
	DEFEATED            # 击败
}

@export var move_speed: float = 60.0
@export var charge_speed_multiplier: float = 5.0
@export var charge_distance: float = 200.0
@export var melee_switch_range: float = 150.0   # 小于此距离切近战姿态
@export var melee_attack_range: float = 60.0    # 近战攻击触发距离
@export var ranged_attack_range: float = 300.0  # 远程攻击触发距离（暂用）
@export var base_attack: int = 15

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health: Node = $HealthComponent
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var body_hitbox: Area2D = $BodyHitbox
@onready var melee_hitbox: Area2D = $MeleeHitbox
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var enter_combat_sound: AudioStreamPlayer = $EnterCombatSound

var current_state: State = State.IDLE_RANGED
var player: CharacterBody2D = null
var charge_start_position: Vector2
var charge_direction: int = 1

func _ready():
	health.died.connect(_on_defeated)
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)

	# 初始禁用所有攻击碰撞体
	body_hitbox.monitoring = false
	body_hitbox.get_node("CollisionShape2D").disabled = true
	melee_hitbox.monitoring = false
	melee_hitbox.get_node("CollisionShape2D").disabled = true

	# 连接攻击碰撞体的信号
	body_hitbox.body_entered.connect(_on_attack_hitbox_entered)
	melee_hitbox.body_entered.connect(_on_attack_hitbox_entered)



func _on_attack_hitbox_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		var dir = sign(body.global_position.x - global_position.x)
		body.take_damage(base_attack, dir)

func _physics_process(delta: float) -> void:
	if current_state == State.DEFEATED:
		return
	
	# 如果玩家存在且处于可行动状态，执行姿态/攻击逻辑
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		
		# 根据距离自动切换远近姿态（仅在非攻击非硬直时）
		if current_state in [State.IDLE_RANGED, State.IDLE_MELEE, State.MOVE]:
			if dist <= melee_switch_range and current_state != State.IDLE_MELEE:
				change_state(State.SWITCH_TO_MELEE)
			elif dist > melee_switch_range and current_state != State.IDLE_RANGED:
				change_state(State.IDLE_RANGED)
		
		# 行为处理
		match current_state:
			State.IDLE_RANGED, State.IDLE_MELEE:
				# 待机时面向玩家
				face_player()
				# 如果不在攻击冷却，尝试选择攻击
				if attack_cooldown.is_stopped():
					choose_attack()
				else:
					# 否则向玩家移动（进入MOVE状态）
					change_state(State.MOVE)
			
			State.MOVE:
				move_toward_player(delta)
				# 移动时也可触发攻击
				if attack_cooldown.is_stopped():
					choose_attack()
			
			State.CHARGE:
				perform_charge(delta)
			
			State.MELEE_ATTACK:
				# 攻击中不移动，由动画控制
				pass
			
			State.STUNNED:
				# 硬直中减速
				velocity.x = move_toward(velocity.x, 0, move_speed * 2 * delta)
				move_and_slide()
		
		# 更新朝向
		if current_state not in [State.CHARGE, State.MELEE_ATTACK, State.STUNNED]:
			face_player()
	else:
		# 没有玩家时回归远程待机
		if current_state != State.IDLE_RANGED:
			change_state(State.IDLE_RANGED)
		velocity.x = 0
		move_and_slide()

func face_player():
	if player:
		animated_sprite.flip_h = player.global_position.x < global_position.x

func move_toward_player(delta):
	if not player: return
	var dir = sign(player.global_position.x - global_position.x)
	velocity.x = dir * move_speed
	animated_sprite.play("move")
	move_and_slide()

func perform_charge(delta):
	# 冲锋移动
	velocity.x = charge_direction * move_speed * charge_speed_multiplier
	move_and_slide()
	
	# 检查是否碰到墙壁或超过距离
	var traveled = abs(global_position.x - charge_start_position.x)
	if traveled >= charge_distance or is_on_wall():
		end_charge()

func choose_attack():
	if not player: return
	var dist = global_position.distance_to(player.global_position)
	
	# 近战姿态下的攻击选择
	if current_state in [State.IDLE_MELEE, State.SWITCH_TO_MELEE]:
		if dist <= melee_attack_range:
			start_melee_attack()
			return
		elif dist <= melee_switch_range * 1.2:  # 在稍远距离可用冲锋
			start_charge()
			return
	
	# 远程姿态下（暂时没有远程攻击，先保持移动）
	# 后续添加 RANGED_ATTACK
	pass

func start_melee_attack():
	change_state(State.MELEE_ATTACK)
	attack_cooldown.start(1.5)  # 冷却时间
	animated_sprite.play("melee_attack")
	
	# 动画长度为5帧，假设帧率10fps，总时长0.5秒
	# 前3帧无伤害，后2帧启用 MeleeHitbox
	await get_tree().create_timer(0.3).timeout  # 3帧时间
	if current_state != State.MELEE_ATTACK: return
	
	melee_hitbox.monitoring = true
	melee_hitbox.get_node("CollisionShape2D").disabled = false
	
	await get_tree().create_timer(0.2).timeout  # 后2帧
	melee_hitbox.monitoring = false
	melee_hitbox.get_node("CollisionShape2D").disabled = true
	
	# 攻击结束，回到近战待机
	if current_state == State.MELEE_ATTACK:
		change_state(State.IDLE_MELEE)

func start_charge():
	change_state(State.CHARGE)
	attack_cooldown.start(2.0)
	
	charge_start_position = global_position
	charge_direction = 1 if not animated_sprite.flip_h else -1
	animated_sprite.play("charge")  # 3帧冲锋动画
	
	# 启用全身碰撞伤害
	body_hitbox.monitoring = true
	body_hitbox.get_node("CollisionShape2D").disabled = false
	
	# 冲锋距离或撞墙时结束，在 perform_charge 中处理

func end_charge():
	body_hitbox.monitoring = false
	body_hitbox.get_node("CollisionShape2D").disabled = true
	
	if current_state == State.CHARGE:
		change_state(State.IDLE_MELEE)  # 冲锋后进入近战待机

func change_state(new_state: State):
	current_state = new_state
	match new_state:
		State.IDLE_RANGED:
			animated_sprite.play("idle_ranged")
		State.IDLE_MELEE:
			animated_sprite.play("idle_melee")
		State.SWITCH_TO_MELEE:
			animated_sprite.play("switch_to_melee")
			# 假设动画9帧，0.9秒后自动切换到近战待机
			await get_tree().create_timer(0.9).timeout
			if current_state == State.SWITCH_TO_MELEE:
				change_state(State.IDLE_MELEE)
		State.MOVE:
			animated_sprite.play("move")
		State.STUNNED:
			animated_sprite.play("hurt")

func _on_player_entered(body):
	if body.is_in_group("player") and current_state == State.IDLE_RANGED:
		player = body
		# 进入战斗，可以播放音效，但动画不打断姿态切换
		if enter_combat_sound:
			enter_combat_sound.play()

func _on_player_exited(body):
	if body == player:
		# 玩家离开检测范围，但暂时保持战斗状态，后续可加脱离计时器
		pass

func take_damage(amount: int, direction_x: float = 0.0):
	health.take_damage(amount)
	if health.is_alive():
		# 受伤硬直
		change_state(State.STUNNED)
		await get_tree().create_timer(0.3).timeout
		if current_state == State.STUNNED:
			# 恢复为合适的待机状态
			if player and global_position.distance_to(player.global_position) <= melee_switch_range:
				change_state(State.IDLE_MELEE)
			else:
				change_state(State.IDLE_RANGED)

func _on_defeated():
	current_state = State.DEFEATED
	animated_sprite.play("defeated")
	# 禁用所有攻击碰撞体
	body_hitbox.monitoring = false
	body_hitbox.get_node("CollisionShape2D").disabled = true
	melee_hitbox.monitoring = false
	melee_hitbox.get_node("CollisionShape2D").disabled = true
	# 可选：禁用受击
	hurtbox.monitoring = false
