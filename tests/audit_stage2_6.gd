extends SceneTree

func _init() -> void:
	call_deferred("_run_audit")

func _run_audit() -> void:
	var error := change_scene_to_file("res://scenes/regions/Farm.tscn")
	if error != OK:
		_fail("farm load failed")
		return
	await scene_changed
	var player := current_scene.get_node_or_null("Player")
	if player == null or player.get_node_or_null("HeldTool") == null:
		_fail("HeldTool missing")
		return
	if current_scene.get_node_or_null("TownExit") == null:
		_fail("farm exit missing")
		return
	var farmhouse_door := current_scene.get_node_or_null("PlayerFarmhouseDoor")
	if farmhouse_door == null:
		_fail("farmhouse door missing")
		return
	farmhouse_door._on_body_entered(player)
	await scene_changed
	while get_root().get_node("WorldManager").is_transitioning:
		await process_frame
	if current_scene.scene_file_path != "res://scenes/regions/Interior.tscn" or current_scene.get_node_or_null("InteriorExit") == null:
		_fail("interior entry failed")
		return
	var interior_exit := current_scene.get_node("InteriorExit")
	interior_exit._on_body_entered(current_scene.get_node("Player"))
	await scene_changed
	while get_root().get_node("WorldManager").is_transitioning:
		await process_frame
	if current_scene.name != "Farm":
		_fail("interior exit failed")
		return
	if get_root().get_node_or_null("WorldManager") == null:
		_fail("WorldManager missing")
		return
	if not get_root().get_node("WorldManager").has_signal("item_collected"):
		_fail("item collection signal missing")
		return
	var fishing := get_root().get_node_or_null("FishingManager")
	if fishing == null or not fishing.has_method("start_fishing") or not fishing.has_method("is_active"):
		_fail("fishing manager wiring missing")
		return
	var region_exit := current_scene.get_node_or_null("TownExit")
	if region_exit == null or not region_exit.has_method("_on_body_entered"):
		_fail("region exit wiring missing")
		return
	for npc_data in get_root().get_node("NPCatalog").NPCS:
		for entry in npc_data.schedule:
			if str(entry.region) != "none":
				var target: Vector2 = entry.target
				if target.x < 0.0 or target.x > 1600.0 or target.y < 0.0 or target.y > 900.0:
					_fail("NPC target outside map: " + npc_data.npc_id)
					return
	var forest_error := change_scene_to_file("res://scenes/regions/Forest.tscn")
	if forest_error != OK:
		_fail("forest load failed")
		return
	await scene_changed
	var bridge: Node = current_scene.get_node_or_null("WoodBridgeArt")
	var has_bridge_collision := false
	if bridge != null:
		for child in bridge.get_children():
			if child is CollisionShape2D:
				has_bridge_collision = true
	if bridge == null or not has_bridge_collision:
		_fail("forest bridge collision missing")
		return
	print("AUDIT PASS: stage 2-6 wiring")
	quit(0)

func _fail(message: String) -> void:
	push_error("AUDIT FAILED: " + message)
	quit(1)
