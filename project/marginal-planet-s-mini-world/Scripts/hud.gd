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
	fill.size = Vector2(max_width, BAR_HEIGHT)
	background.size = Vector2(max_width + BORDER, BAR_HEIGHT + BORDER)
	fill.position = Vector2(BORDER / 2.0, BORDER / 2.0)
	
	# 关键：设置父容器 HealthBar 的尺寸，否则子节点不可见
	health_bar.size = background.size
	
	# 确保血条有可见颜色
	fill.color = Color.RED
	
	# 存档面板默认隐藏
	save_panel.hide()
	
	# 死亡界面默认隐藏
	death_screen.hide()
	black_overlay.color.a = 0.0
	dead_label.hide()
	retry_button.hide()
	
	# 连接重试按钮
	retry_button.pressed.connect(_on_retry_pressed)
	
	# 连接存档按钮（按钮名为 SaveButton）
	if has_node("SaveButton"):
		# 假设编辑器中的信号连接到了 _on_save_bottom_pressed，但我们直接在此连接
		$SaveButton.pressed.connect(_on_save_button_pressed)
	else:
		print("警告：未找到 SaveButton 节点，存档按钮无效")
	
	# 为 SavePanel 中的按钮连接信号（如果编辑器里已连则跳过，用代码更可靠）
	# 快速读档按钮
	var quick_slot = $SavePanel/VBoxContainer/QuickSaveSlot
	if quick_slot:
		quick_slot.pressed.connect(_on_quick_save_slot_pressed)
	# 关闭按钮
	var close_btn = $SavePanel/VBoxContainer/CloseButton
	if close_btn:
		close_btn.pressed.connect(_on_close_button_pressed)
	# 三个存档槽
	slot1.pressed.connect(_on_save_slot_1_pressed)
	slot2.pressed.connect(_on_save_slot_2_pressed)
	slot3.pressed.connect(_on_save_slot_3_pressed)

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
