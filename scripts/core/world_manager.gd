extends Node

var current_region := "farm"
var player_state := {"velocity": Vector2.ZERO, "last_position": Vector2.ZERO}
var temporary_drops: Array[Dictionary] = []
var inventory: Dictionary = {"wheat_seed": 5, "carrot_seed": 5, "moonberry_seed": 5}
var gold := 100
var daily_income := 0
var tool_levels: Dictionary = {"hoe": 0, "axe": 0, "pickaxe": 0, "fishing_rod": 0, "watering_can": 0}
var well_repaired := false
var shop_level := 1
var npc_relationships: Dictionary = {"edrik": 0, "mira": 0, "rowan": 0, "ivy": 0}
var unlocked_regions: Dictionary = {"farm": true, "town": true, "forest": true, "river": true, "mine_1": true, "mine_2": true, "sanctum": false}
var farm_plots: Dictionary = {}
var is_transitioning := false

func _ready() -> void:
	TimeManager.day_started.connect(_on_day_started)

func _on_day_started(_day: int) -> void:
	daily_income = 0

func add_item(item_id: String, amount: int = 1) -> void:
	inventory[item_id] = int(inventory.get(item_id, 0)) + amount

func upgrade_tool(tool_id: String) -> String:
	var level := int(tool_levels.get(tool_id, 0))
	if level >= 1:
		return "max_level"
	if gold < 120:
		return "not_enough_gold"
	gold -= 120
	tool_levels[tool_id] = level + 1
	return "upgraded"

func upgrade_well() -> String:
	if well_repaired:
		return "already"
	if gold < 80:
		return "not_enough_gold"
	gold -= 80
	well_repaired = true
	return "upgraded"

func upgrade_shop() -> String:
	if shop_level >= 2:
		return "max_level"
	if gold < 150:
		return "not_enough_gold"
	gold -= 150
	shop_level = 2
	return "upgraded"

func change_region(scene_path: String, target_region: String, spawn_position: Vector2) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player:
		player_state.velocity = player.velocity
		player_state.last_position = player.global_position
	current_region = target_region
	player_state.last_position = spawn_position
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Unable to change region: %s" % scene_path)
		is_transitioning = false
		return
	await get_tree().scene_changed
	var new_scene := get_tree().current_scene
	if not is_instance_valid(new_scene):
		push_error("Region changed, but no current scene is available: %s" % scene_path)
		is_transitioning = false
		return
	var new_player := new_scene.get_node_or_null("Player")
	if new_player:
		new_player.global_position = spawn_position
		new_player.velocity = player_state.velocity
	else:
		push_error("Region has no Player node: %s" % scene_path)
	is_transitioning = false
