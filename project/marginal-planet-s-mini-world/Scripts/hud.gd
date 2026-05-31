extends CanvasLayer

@onready var health_bar: Control = $HealthBar
@onready var fill: ColorRect = $HealthBar/Fill
@onready var background: Panel = $HealthBar/Background
@onready var save_panel: Panel = $SavePanel
@onready var slot1: Button = $SavePanel/VBoxContainer/SaveSlot1
@onready var slot2: Button = $SavePanel/VBoxContainer/SaveSlot2
@onready var slot3: Button = $SavePanel/VBoxContainer/SaveSlot3

var max_width: float
const MAX_BAR_WIDTH = 200
const SCREEN_MAX_RATIO = 0.5
const BORDER = 4  # 上下左右边框厚度
const BAR_HEIGHT = 20

func _ready():
	max_width = min(MAX_BAR_WIDTH, get_tree().root.size.x * SCREEN_MAX_RATIO)
	fill.size = Vector2(max_width, BAR_HEIGHT)
	background.size = Vector2(max_width + BORDER, BAR_HEIGHT + BORDER)
	fill.position = Vector2(BORDER / 2.0, BORDER / 2.0)
	$SaveButton.mouse_filter = Control.MOUSE_FILTER_STOP
	$SaveButton.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_save_bottom_pressed():
	print("存档按钮被点击")
	update_save_slots()
	save_panel.show()

func _on_close_pressed():
	save_panel.hide()

func _on_save_slot_1_pressed():
	SaveManager.save_game("save1")
	save_panel.hide()

func _on_save_slot_2_pressed():
	SaveManager.save_game("save2")
	save_panel.hide()

func _on_save_slot_3_pressed():
	SaveManager.save_game("save3")
	save_panel.hide()
	
func _on_close_button_pressed():
	save_panel.hide()

func update_save_slots():
	var info1 = SaveManager.get_save_info("save1")
	slot1.text = "存档1: 空" if info1.is_empty() else "存档1: " + info1["timestamp"]
	var info2 = SaveManager.get_save_info("save2")
	slot2.text = "存档2: 空" if info2.is_empty() else "存档2: " + info2["timestamp"]
	var info3 = SaveManager.get_save_info("save3")
	slot3.text = "存档3: 空" if info3.is_empty() else "存档3: " + info3["timestamp"]

func set_health(current: int, max_hp: int):
	var target_width = (float(current) / max_hp) * max_width
	var tween = create_tween()
	tween.tween_property(fill, "size:x", target_width, 0.2)
	# 边框跟随填充宽度
	#tween.tween_property(background, "size:x", target_width + BORDER, 0.2)


func _on_quick_save_slot_pressed() -> void:
	pass # Replace with function body.
