extends Node

signal save_message(text: String)
const SAVE_PATH := "user://moonshadow_frontier_save.json"

func _ready() -> void:
	TimeManager.day_started.connect(_on_day_started)

func _on_day_started(_day: int) -> void:
	save_game()

func save_game() -> bool:
	var plot_data := {}
	for key in WorldManager.farm_plots:
		var value: Dictionary = WorldManager.farm_plots[key]
		plot_data["%d,%d" % [key.x, key.y]] = value
	var player := get_tree().current_scene.get_node_or_null("Player")
	var payload := {"version": 1, "day": TimeManager.day, "minutes": TimeManager.minutes, "gold": WorldManager.gold, "daily_income": WorldManager.daily_income, "inventory": WorldManager.inventory, "farm_plots": plot_data, "current_region": WorldManager.current_region, "player_position": [player.global_position.x, player.global_position.y] if player else [0, 0], "tool_levels": WorldManager.tool_levels, "well_repaired": WorldManager.well_repaired, "shop_level": WorldManager.shop_level, "npc_relationships": WorldManager.npc_relationships, "unlocked_regions": WorldManager.unlocked_regions, "moonstone_repaired": QuestManager.moonstone_repaired, "quest_started": QuestManager.quest_started}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_message.emit("保存失败：无法打开存档文件。")
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	save_message.emit("游戏已保存。")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		save_message.emit("没有找到存档。")
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or int(parsed.get("version", 0)) != 1:
		save_message.emit("存档格式无法识别。")
		return false
	TimeManager.day = int(parsed.get("day", 1))
	TimeManager.minutes = int(parsed.get("minutes", TimeManager.MORNING_START))
	WorldManager.gold = int(parsed.get("gold", 100))
	WorldManager.daily_income = int(parsed.get("daily_income", 0))
	WorldManager.inventory = parsed.get("inventory", {})
	WorldManager.tool_levels = parsed.get("tool_levels", {})
	WorldManager.well_repaired = bool(parsed.get("well_repaired", false))
	WorldManager.shop_level = int(parsed.get("shop_level", 1))
	WorldManager.npc_relationships = parsed.get("npc_relationships", WorldManager.npc_relationships)
	WorldManager.unlocked_regions = parsed.get("unlocked_regions", WorldManager.unlocked_regions)
	QuestManager.moonstone_repaired = bool(parsed.get("moonstone_repaired", false))
	QuestManager.quest_started = bool(parsed.get("quest_started", false))
	WorldManager.farm_plots.clear()
	for key in parsed.get("farm_plots", {}):
		var parts := str(key).split(",")
		if parts.size() == 2:
			WorldManager.farm_plots[Vector2i(int(parts[0]), int(parts[1]))] = parsed["farm_plots"][key]
	var scene_path := _scene_path_for_region(str(parsed.get("current_region", "farm")))
	if scene_path != get_tree().current_scene.scene_file_path:
		await get_tree().change_scene_to_file(scene_path)
		await get_tree().scene_changed
	var player := get_tree().current_scene.get_node_or_null("Player")
	var position_data = parsed.get("player_position", [360, 450])
	if player and position_data is Array and position_data.size() >= 2:
		player.global_position = Vector2(float(position_data[0]), float(position_data[1]))
	TimeManager.time_changed.emit(TimeManager.day, TimeManager.minutes, TimeManager.get_period())
	save_message.emit("存档已读取。")
	return true

func new_game() -> void:
	TimeManager.day = 1
	TimeManager.minutes = TimeManager.MORNING_START
	WorldManager.gold = 100
	WorldManager.daily_income = 0
	WorldManager.inventory = {"wheat_seed": 5, "carrot_seed": 5, "moonberry_seed": 5}
	WorldManager.farm_plots.clear()
	WorldManager.tool_levels = {"hoe": 0, "axe": 0, "pickaxe": 0, "fishing_rod": 0, "watering_can": 0}
	WorldManager.well_repaired = false
	WorldManager.shop_level = 1
	WorldManager.npc_relationships = {"edrik": 0, "mira": 0, "rowan": 0, "ivy": 0}
	WorldManager.unlocked_regions = {"farm": true, "town": true, "forest": true, "river": true, "mine_1": true, "mine_2": true, "sanctum": false}
	QuestManager.moonstone_repaired = false
	QuestManager.quest_started = false
	save_message.emit("已开始新游戏。")

func _scene_path_for_region(region: String) -> String:
	if region == "town": return "res://scenes/regions/Town.tscn"
	if region == "forest": return "res://scenes/regions/Forest.tscn"
	if region == "river": return "res://scenes/regions/River.tscn"
	if region == "mine_2": return "res://scenes/regions/MineFloor2.tscn"
	if region == "mine_1": return "res://scenes/regions/Mine.tscn"
	if region == "sanctum": return "res://scenes/regions/Sanctum.tscn"
	return "res://scenes/regions/Farm.tscn"
