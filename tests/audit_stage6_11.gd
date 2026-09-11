extends SceneTree

func _init() -> void:
	call_deferred("_run_audit")

func _run_audit() -> void:
	var world_manager = get_root().get_node("WorldManager")
	var save_manager = get_root().get_node("SaveManager")
	var error := change_scene_to_file("res://scenes/regions/Farm.tscn")
	if error != OK:
		_quit_with_error("farm load failed")
		return
	await scene_changed
	if current_scene.get_node_or_null("Player") == null:
		_quit_with_error("farm has no player")
		return
	await world_manager.change_region("res://scenes/regions/Town.tscn", "town", Vector2(140, 450))
	if current_scene.name != "Town":
		_quit_with_error("town transition failed")
		return
	await world_manager.change_region("res://scenes/regions/Forest.tscn", "forest", Vector2(140, 450))
	if current_scene.name != "Forest":
		_quit_with_error("forest transition failed")
		return
	await world_manager.change_region("res://scenes/regions/Mine.tscn", "mine_1", Vector2(140, 700))
	if current_scene.name != "Mine":
		_quit_with_error("mine floor one transition failed")
		return
	await world_manager.change_region("res://scenes/regions/MineFloor2.tscn", "mine_2", Vector2(140, 180))
	if current_scene.name != "MineFloor2":
		_quit_with_error("mine floor two transition failed")
		return
	if not save_manager.save_game() or not FileAccess.file_exists(save_manager.SAVE_PATH):
		_quit_with_error("save failed")
		return
	if not await save_manager.load_game():
		_quit_with_error("load failed")
		return
	print("AUDIT PASS: stage 6-11 scenes and save/load")
	quit(0)

func _quit_with_error(message: String) -> void:
	push_error("AUDIT FAILED: " + message)
	quit(1)
