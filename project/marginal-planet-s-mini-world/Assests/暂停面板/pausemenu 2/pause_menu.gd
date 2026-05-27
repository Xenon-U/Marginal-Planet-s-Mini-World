extends CanvasLayer

@export var pause_panel: Panel
@export var bgm_player: AudioStreamPlayer
@export var pause_sound: AudioStreamPlayer
var paused_time: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var volume_linear = db_to_linear(bgm_player.volume_db)
	var target_volume = 0.0 if get_tree().paused else 1.0
	volume_linear = lerp(volume_linear, target_volume, delta * 15.0)
	bgm_player.volume_db = linear_to_db(volume_linear)
	
	bgm_player.stream_paused = get_tree().paused and Time.get_ticks_msec() > paused_time + 300

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			if not get_tree().paused:
				pause()
			else:
				unpause()

func pause():
	get_tree().paused = true
	pause_panel.visible = true
	paused_time = Time.get_ticks_msec()
	pause_sound.play()

func unpause():
	get_tree().paused = false
	pause_panel.visible = false
	pause_sound.play()
	
func quit_game():
	get_tree().quit()
	
