extends Control

var load_panel: Panel
var quick_slot: Button
var save_slots: Array[Button] = []

func _ready():
	load_panel = $LoadPanel
	load_panel.hide()
	
	# 强制连接主按钮
	$VBoxContainer/start.pressed.connect(_on_start_pressed)
	$VBoxContainer/load.pressed.connect(_on_load_pressed)
	$VBoxContainer/exit.pressed.connect(_on_exit_pressed)
	
	# 强制连接 LoadPanel 按钮
	var vbox = $LoadPanel/VBoxContainer
	quick_slot = vbox.get_node("QuickSaveSlot")
	quick_slot.pressed.connect(_on_quick_save_slot_pressed)
	
	save_slots = [
		vbox.get_node("SaveSlot1"),
		vbox.get_node("SaveSlot2"),
		vbox.get_node("SaveSlot3")
	]
	save_slots[0].pressed.connect(_on_save_slot_1_pressed)
	save_slots[1].pressed.connect(_on_save_slot_2_pressed)
	save_slots[2].pressed.connect(_on_save_slot_3_pressed)
	
	vbox.get_node("BackButton").pressed.connect(_on_back_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")

func _on_load_pressed():
	print("Load按钮被点击")
	update_load_slots()
	load_panel.show()

func _on_exit_pressed():
	get_tree().quit()

func _on_back_pressed():
	print("Back按钮被点击")
	load_panel.hide()

func _on_quick_save_slot_pressed():
	print("QuickSave被点击")
	var info = SaveManager.get_save_info("quicksave")
	if info.is_empty():
		return
	SaveManager.load_game("quicksave")

func _on_save_slot_1_pressed():
	load_slot("save1")

func _on_save_slot_2_pressed():
	load_slot("save2")

func _on_save_slot_3_pressed():
	load_slot("save3")

func load_slot(slot: String):
	var info = SaveManager.get_save_info(slot)
	if info.is_empty():
		return
	SaveManager.load_game(slot)

func update_load_slots():
	var quick = SaveManager.get_save_info("quicksave")
	quick_slot.text = "快速存档: 空" if quick.is_empty() else "快速存档: " + quick["timestamp"]
	
	for i in save_slots.size():
		var slot_name = "save" + str(i + 1)
		var info = SaveManager.get_save_info(slot_name)
		save_slots[i].text = "存档" + str(i + 1) + ": 空" if info.is_empty() else "存档" + str(i + 1) + ": " + info["timestamp"]
