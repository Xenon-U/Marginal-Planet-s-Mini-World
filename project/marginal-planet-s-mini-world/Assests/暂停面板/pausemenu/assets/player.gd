extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -350.0
@export var animator : AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		animator.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if is_on_floor():
		if direction != 0:
			animator.play("run")
		else:
			animator.play("idle")
	else:
		animator.play("jump")
	
			

	move_and_slide()
