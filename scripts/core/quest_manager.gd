extends Node

signal quest_changed

var moonstone_repaired := false
var quest_started := false

func _ready() -> void:
	quest_changed.emit()

func get_objective_text() -> String:
	if moonstone_repaired:
		return "主线完成：女巫圣地已开放"
	if not quest_started:
		return "前往森林调查损坏的月影石碑"
	return "收集月莓 3 个和月辉矿 1 个，带回石碑"

func interact_with_stone() -> String:
	if moonstone_repaired:
		return "石碑散发着稳定的月光，新的通路已经开启。"
	quest_started = true
	if int(WorldManager.inventory.get("moonberry", 0)) < 3:
		return "石碑需要 3 个月莓和 1 个月辉矿。"
	if int(WorldManager.inventory.get("moonlight_ore", 0)) < 1:
		return "石碑需要 1 个月辉矿。"
	WorldManager.inventory["moonberry"] = int(WorldManager.inventory.get("moonberry", 0)) - 3
	WorldManager.inventory["moonlight_ore"] = int(WorldManager.inventory.get("moonlight_ore", 0)) - 1
	moonstone_repaired = true
	WorldManager.unlocked_regions["sanctum"] = true
	quest_changed.emit()
	return "月影石碑已修复，森林的新通路开启了。"
