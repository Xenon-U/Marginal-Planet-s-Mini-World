extends Node

var SAVE_DIR: String
const QUICK_SAVE = "quicksave"
const SAVE_SLOTS = ["save1", "save2", "save3"]

func _ready():
	if OS.has_feature("editor"):
		SAVE_DIR = "res://Save/"
	else:
		SAVE_DIR = OS.get_executable_path().get_base_dir() + "/Save/"
	
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

func save_game(slot_name: String):
	var save_data = {
		"timestamp": Time.get_datetime_string_from_system(),
		"scene": get_tree().current_scene.scene_file_path,
		"player": get_player_data(),
		"enemies": get_enemies_data()
	}
	
	var file = FileAccess.open(SAVE_DIR + slot_name + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	print("存档成功: ", slot_name)

func load_game(slot_name: String) -> bool:
	if not FileAccess.file_exists(SAVE_DIR + slot_name + ".json"):
		print("存档不存在: ", slot_name)
		return false
	
	var file = FileAccess.open(SAVE_DIR + slot_name + ".json", FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var save_data = JSON.parse_string(json_string)
	if save_data == null:
		return false
	
	get_tree().change_scene_to_file(save_data["scene"])
	# 等场景加载完成
	await get_tree().create_timer(0.1).timeout
	
	load_player_data(save_data["player"])
	load_enemies_data(save_data["enemies"])
	print("读档成功: ", slot_name)
	return true

func get_save_info(slot_name: String) -> Dictionary:
	if not FileAccess.file_exists(SAVE_DIR + slot_name + ".json"):
		return {}
	
	var file = FileAccess.open(SAVE_DIR + slot_name + ".json", FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if data and data.has("timestamp"):
		return {"slot": slot_name, "timestamp": data["timestamp"]}
	return {}

func get_all_saves() -> Array:
	var saves = []
	var quick = get_save_info(QUICK_SAVE)
	if not quick.is_empty():
		saves.append(quick)
	for slot in SAVE_SLOTS:
		var info = get_save_info(slot)
		if not info.is_empty():
			saves.append(info)
	return saves

func delete_save(slot_name: String):
	if FileAccess.file_exists(SAVE_DIR + slot_name + ".json"):
		DirAccess.remove_absolute(SAVE_DIR + slot_name + ".json")
		print("已删除存档: ", slot_name)

func get_player_data() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return {}
	return {
		"position_x": player.global_position.x,
		"position_y": player.global_position.y,
		"current_health": player.health_component.current_health,
		"max_health": player.health_component.max_health,
		"flip_h": player.animated_sprite.flip_h
	}

func load_player_data(data: Dictionary):
	if data.is_empty():
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	player.global_position = Vector2(data["position_x"], data["position_y"])
	player.health_component.current_health = data["current_health"]  # 改这里
	player.health_component.max_health = data["max_health"]
	player.animated_sprite.flip_h = data["flip_h"]
	# 更新血条
	if player.hud:
		player.hud.set_health(data["current_health"], data["max_health"])

func get_enemies_data() -> Array:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var data = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			data.append({
				"path": enemy.get_path(),
				"position_x": enemy.global_position.x,
				"position_y": enemy.global_position.y,
				"current_health": enemy.health_component.current_health,
				"alive": enemy.health_component.is_alive()
			})
	return data

func load_enemies_data(data: Array):
	for enemy_data in data:
		var enemy = get_node_or_null(enemy_data["path"])
		if enemy and is_instance_valid(enemy):
			enemy.global_position = Vector2(enemy_data["position_x"], enemy_data["position_y"])
			enemy.health_component.current_health = enemy_data["current_health"]
			if not enemy_data["alive"]:
				enemy.queue_free()
