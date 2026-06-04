extends Control

@export var pause_panel: Control
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	
func pause():
	get_tree().paused = true
	pause_panel.visible = true
func unpause():
	get_tree().paused = false
	pause_panel.visible = false
func quit_game():
	get_tree().quit()
