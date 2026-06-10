extends CanvasLayer

# ---- 血条相关 ----
@onready var health_bar: Control = $HealthBar
@onready var fill: ColorRect = $HealthBar/Fill
@onready var background: Panel = $HealthBar/Background

# ---- 存档面板相关 ----
@onready var save_panel: Panel = $SavePanel
@onready var slot1: Button = $SavePanel/VBoxContainer/SaveSlot1
@onready var slot2: Button = $SavePanel/VBoxContainer/SaveSlot2
@onready var slot3: Button = $SavePanel/VBoxContainer/SaveSlot3

# ---- 死亡界面相关 ----
@onready var death_screen: Control = $DeathScreen
@onready var black_overlay: ColorRect = $DeathScreen/BlackOverlay
@onready var dead_label: Label = $DeathScreen/YouDiedLabel
@onready var retry_button: Button = $DeathScreen/RetryButton

var max_width: float
const MAX_BAR_WIDTH = 200
const SCREEN_MAX_RATIO = 0.5
const BORDER = 4
const BAR_HEIGHT = 20

func _ready():
	# 血条初始化
	max_width = min(MAX_BAR_WIDTH, get_tree().root.size.x * SCREEN_MAX_RATIO)
	health_bar.size = Vector2(max_width + BORDER, BAR_HEIGHT + BORDER)
	background.size = health_bar.size
	background.position = Vector2.ZERO
	fill.size = Vector2(max_width, BAR_HEIGHT)
	fill.position = Vector2(BORDER / 2.0, BORDER / 2.0)
	fill.color = Color.RED

	# 存档面板默认隐藏
	save_panel.hide()

	# 死亡界面默认隐藏
	death_screen.hide()
	black_overlay.color.a = 0.0
	dead_label.hide()
	retry_button.hide()

	# ========== 强制重新连接所有信号（先断开再连接） ==========
	# 重试按钮
	if retry_button.pressed.is_connected(_on_retry_pressed):
		retry_button.pressed.disconnect(_on_retry_pressed)
	retry_button.pressed.connect(_on_retry_pressed)

	# 主存档按钮
	if has_node("SaveButton"):
		if $SaveButton.pressed.is_connected(_on_save_button_pressed):
			$SaveButton.pressed.disconnect(_on_save_button_pressed)
		$SaveButton.pressed.connect(_on_save_button_pressed)

	# 快速读档按钮
	var quick_slot = $SavePanel/VBoxContainer/QuickSaveSlot
	if quick_slot:
		if quick_slot.pressed.is_connected(_on_quick_save_slot_pressed):
			quick_slot.pressed.disconnect(_on_quick_save_slot_pressed)
		quick_slot.pressed.connect(_on_quick_save_slot_pressed)

	# 关闭面板按钮
	var close_btn = $SavePanel/VBoxContainer/CloseButton
	if close_btn:
		if close_btn.pressed.is_connected(_on_close_button_pressed):
			close_btn.pressed.disconnect(_on_close_button_pressed)
		close_btn.pressed.connect(_on_close_button_pressed)

	# 三个存档槽按钮
	var slot_funcs = [_on_save_slot_1_pressed, _on_save_slot_2_pressed, _on_save_slot_3_pressed]
	for i in range(3):
		var slot = get_node("SavePanel/VBoxContainer/SaveSlot" + str(i+1))
		if slot.pressed.is_connected(slot_funcs[i]):
			slot.pressed.disconnect(slot_funcs[i])
		slot.pressed.connect(slot_funcs[i])

# ========== 血条更新 ==========
func set_health(current: int, max_hp: int):
	var target_width = (float(current) / max_hp) * max_width
	var tween = create_tween()
	tween.tween_property(fill, "size:x", target_width, 0.2)

# ========== 存档按钮 ==========
func _on_save_button_pressed():
	update_save_slots()
	save_panel.show()

func _on_save_bottom_pressed():
	# 如果编辑器信号连了这个，转调到这里
	_on_save_button_pressed()

func _on_close_button_pressed():
	save_panel.hide()

func _on_quick_save_slot_pressed():
	SaveManager.load_game("quicksave")

func _on_save_slot_1_pressed():
	SaveManager.save_game("save1")
	save_panel.hide()

func _on_save_slot_2_pressed():
	SaveManager.save_game("save2")
	save_panel.hide()

func _on_save_slot_3_pressed():
	SaveManager.save_game("save3")
	save_panel.hide()

func update_save_slots():
	var info1 = SaveManager.get_save_info("save1")
	slot1.text = "存档1: 空" if info1.is_empty() else "存档1: " + info1["timestamp"]
	var info2 = SaveManager.get_save_info("save2")
	slot2.text = "存档2: 空" if info2.is_empty() else "存档2: " + info2["timestamp"]
	var info3 = SaveManager.get_save_info("save3")
	slot3.text = "存档3: 空" if info3.is_empty() else "存档3: " + info3["timestamp"]

# ========== 死亡序列 ==========
func start_death_sequence():
	death_screen.show()
	black_overlay.color.a = 0.0
	dead_label.hide()
	retry_button.hide()
	
	var tween = create_tween()
	tween.tween_property(black_overlay, "color:a", 1.0, 2.0)
	tween.tween_callback(func():
		dead_label.show()
		retry_button.show()
	)

func _on_retry_pressed():
	get_tree().reload_current_scene()
