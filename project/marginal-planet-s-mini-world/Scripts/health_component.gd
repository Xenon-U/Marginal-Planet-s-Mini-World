extends Node

signal health_changed(current_health, max_health)
signal damage_taken(_amount, direction_x)
signal died

@export var max_health: int = 3
var current_health: int

func _ready():
	current_health = max_health

func take_damage(amount: int, direction_x: float = 0.0):
	if current_health <= 0: return
	current_health -= amount
	current_health = max(current_health, 0)
	health_changed.emit(current_health, max_health)
	damage_taken.emit(amount, direction_x)
	
	if current_health <= 0:
		died.emit()

func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0
