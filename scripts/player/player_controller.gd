extends CharacterBody2D

const MOVE_SPEED := 220.0
const MAX_STAMINA := 100
const TOOL_DEFINITIONS: Array[ToolData] = [
	preload("res://resources/data/tools/hoe.tres"),
	preload("res://resources/data/tools/axe.tres"),
	preload("res://resources/data/tools/pickaxe.tres"),
	preload("res://resources/data/tools/fishing_rod.tres"),
	preload("res://resources/data/tools/watering_can.tres"),
]
const CROP_DEFINITIONS: Array[CropData] = [
	preload("res://resources/data/crops/wheat.tres"),
	preload("res://resources/data/crops/carrot.tres"),
	preload("res://resources/data/crops/moonberry.tres"),
]

var stamina := MAX_STAMINA
var selected_tool_index := 0
var selected_crop_index := 0
var facing_direction := Vector2.DOWN
var last_tool_time_msec := -100000
var last_action_message := "1-5：选择工具 | Q：切换种子 | 空格：使用 | E：在家睡觉"
var walk_frame := 0
var walk_frame_elapsed := 0.0
const WALK_FRAME_INTERVAL := 0.12
const CHARACTER_FRAME_WIDTH := 768.0
const CHARACTER_FRAME_HEIGHT := 1024.0
const PLAYER_IDLE_TEXTURE: Texture2D = preload("res://assets/characters/player/player_idle_sheet.png")
const PLAYER_WALK_TEXTURE: Texture2D = preload("res://assets/characters/player/player_walk_sheet.png")
signal stamina_changed(current: int, maximum: int)

func _physics_process(_delta: float) -> void:
	if FishingManager.is_active():
		velocity = Vector2.ZERO
		return
	var input_vector := Vector2(
		(1.0 if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) else 0.0),
		(1.0 if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0)
	).normalized()
	if input_vector.length_squared() > 0.0:
		facing_direction = input_vector
		walk_frame_elapsed += _delta
		if walk_frame_elapsed >= WALK_FRAME_INTERVAL:
			walk_frame_elapsed = fmod(walk_frame_elapsed, WALK_FRAME_INTERVAL)
			walk_frame = (walk_frame + 1) % 2
	else:
		walk_frame = 0
		walk_frame_elapsed = 0.0
	velocity = input_vector * MOVE_SPEED
	move_and_slide()
	_update_character_art(input_vector.length_squared() > 0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			_select_tool(0)
		elif event.keycode == KEY_2:
			_select_tool(1)
		elif event.keycode == KEY_3:
			_select_tool(2)
		elif event.keycode == KEY_4:
			_select_tool(3)
		elif event.keycode == KEY_5:
			_select_tool(4)
		elif event.keycode == KEY_Q:
			selected_crop_index = (selected_crop_index + 1) % CROP_DEFINITIONS.size()
			last_action_message = "已选择种子：%s" % CROP_DEFINITIONS[selected_crop_index].display_name
		elif event.keycode == KEY_SPACE:
			_try_tool_action()
		elif event.keycode == KEY_E:
			if _try_npc_interaction():
				return
			if _try_quest_stone_interaction():
				return
			if get_parent().get("region_name") == "town" and global_position.distance_to(Vector2(275, 355)) < 170.0:
				ShopManager.toggle()
			else:
				_try_sleep()

func _try_npc_interaction() -> bool:
	for npc in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(npc) and npc.visible and global_position.distance_to(npc.global_position) < 65.0:
			last_action_message = "%s：%s" % [npc.get_display_name(), npc.get_dialogue()]
			return true
	return false

func _try_quest_stone_interaction() -> bool:
	for stone in get_tree().get_nodes_in_group("quest_stones"):
		if is_instance_valid(stone) and global_position.distance_to(stone.global_position) < 75.0:
			last_action_message = stone.try_interact()
			return true
	return false

func _try_sleep() -> void:
	if get_parent().get("region_name") == "farm" and global_position.distance_to(Vector2(245, 255)) < 130.0:
		TimeManager.advance_day()
		last_action_message = "已在家中睡觉，新的一天开始了。"

func _select_tool(index: int) -> void:
	selected_tool_index = index
	last_action_message = "已选择工具：%s" % TOOL_DEFINITIONS[selected_tool_index].display_name

func get_selected_tool_name() -> String:
	return TOOL_DEFINITIONS[selected_tool_index].display_name

func get_selected_crop_name() -> String:
	return CROP_DEFINITIONS[selected_crop_index].display_name

func _try_tool_action() -> void:
	var tool: ToolData = TOOL_DEFINITIONS[selected_tool_index]
	var tool_level := int(WorldManager.tool_levels.get(tool.tool_id, 0))
	var stamina_cost := maxi(1, int(round(tool.stamina_cost * (1.0 - 0.15 * tool_level))))
	var cooldown_ms := int(tool.cooldown_seconds * 1000.0 / (1.0 + 0.2 * tool_level))
	var now := Time.get_ticks_msec()
	if now - last_tool_time_msec < cooldown_ms:
		last_action_message = "工具冷却中。"
		return
	if stamina < stamina_cost:
		last_action_message = "体力不足，无法使用%s。" % tool.display_name
		return
	if tool.tool_id == "fishing_rod" and _can_fish_here():
		if FishingManager.start_fishing():
			stamina -= stamina_cost
			last_tool_time_msec = now
			last_action_message = "抛竿成功，体力-%d。" % stamina_cost
			stamina_changed.emit(stamina, MAX_STAMINA)
		return
	var target: Node = null
	if tool.tool_id == "hoe" or tool.tool_id == "watering_can":
		target = _find_target_in_group("farm_plots", tool.interaction_range)
		if target != null:
			var plot_result: String = str(target.call("try_interact", tool.tool_id, CROP_DEFINITIONS[selected_crop_index]))
			if plot_result in ["tilled", "seeded", "watered"] or plot_result.begins_with("harvested_"):
				stamina -= stamina_cost
				last_tool_time_msec = now
				last_action_message = _plot_result_message(plot_result, tool, stamina_cost)
				stamina_changed.emit(stamina, MAX_STAMINA)
				return
			last_action_message = _plot_failure_message(plot_result)
			return
	target = _find_resource_target(tool.interaction_range)
	if target == null:
		last_action_message = "%s前方没有可交互的目标。" % tool.display_name
		return
	var result: String = str(target.call("try_collect", tool.tool_id))
	if result.begins_with("needs_"):
		var tool_names := {"hoe": "锄头", "axe": "斧头", "pickaxe": "镐子", "fishing_rod": "鱼竿", "watering_can": "水壶"}
		last_action_message = "该资源需要使用%s。" % tool_names.get(result.trim_prefix("needs_"), result.trim_prefix("needs_"))
		return
	if result != "collected":
		last_action_message = "该资源当前不可用。"
		return
	stamina -= stamina_cost
	last_tool_time_msec = now
	last_action_message = "使用%s采集成功，体力-%d。" % [tool.display_name, stamina_cost]
	stamina_changed.emit(stamina, MAX_STAMINA)

func _can_fish_here() -> bool:
	if get_parent().get("region_name") != "river":
		return false
	var near_left_bank := global_position.x >= 570.0 and global_position.x <= 680.0 and facing_direction.x > 0.0
	var near_right_bank := global_position.x >= 920.0 and global_position.x <= 1030.0 and facing_direction.x < 0.0
	return near_left_bank or near_right_bank

func _plot_result_message(result: String, tool: ToolData, stamina_cost: int) -> String:
	if result == "tilled":
		return "翻地成功，体力-%d。" % stamina_cost
	if result == "seeded":
		return "播种%s成功，体力-%d。" % [CROP_DEFINITIONS[selected_crop_index].display_name, stamina_cost]
	if result == "watered":
		return "浇水成功，体力-%d。" % stamina_cost
	return "收获%s成功，体力-%d。" % [result.trim_prefix("harvested_"), stamina_cost]

func _plot_failure_message(result: String) -> String:
	return {"no_crop_selected": "请先选择一种种子。", "no_seeds": "这种种子已经用完了。", "invalid": "当前工具无法作用于这块土地。"}.get(result, "这块土地当前无法操作。")

func _find_resource_target(interaction_range: float) -> Node:
	return _find_target_in_group("resource_nodes", interaction_range)

func _find_target_in_group(group_name: String, interaction_range: float) -> Node:
	var best_target: Node = null
	var best_distance := interaction_range
	for node in get_tree().get_nodes_in_group(group_name):
		if not is_instance_valid(node) or (node.has_method("try_collect") and not node.is_available):
			continue
		var offset: Vector2 = node.global_position - global_position
		var distance := offset.length()
		if distance > best_distance or distance <= 0.0:
			continue
		if facing_direction.dot(offset.normalized()) < 0.35:
			continue
		best_target = node
		best_distance = distance
	return best_target

func _try_placeholder_tool_action() -> void:
	if stamina < 10:
		last_action_message = "体力不足，无法使用工具。"
		return

func _ready() -> void:
	TimeManager.day_started.connect(_on_day_started)
	stamina_changed.emit(stamina, MAX_STAMINA)

func _on_day_started(_day: int) -> void:
	stamina = MAX_STAMINA
	last_action_message = "新的一天开始，体力已恢复。"
	stamina_changed.emit(stamina, MAX_STAMINA)

func _update_character_art(is_moving: bool) -> void:
	var character_art := get_node_or_null("CharacterArt") as Sprite2D
	if character_art == null or character_art.texture == null:
		return
	var desired_texture := PLAYER_WALK_TEXTURE if is_moving else PLAYER_IDLE_TEXTURE
	if character_art.texture != desired_texture:
		character_art.texture = desired_texture
	var column := 0
	var face_left := false
	if absf(facing_direction.x) > absf(facing_direction.y):
		if is_moving:
			# Walk sheet columns 2/3 are two right-facing side poses.
			column = 2 + walk_frame
			face_left = facing_direction.x < 0.0
		else:
			column = 3 if facing_direction.x > 0.0 else 1
	else:
		column = 0 if facing_direction.y > 0.0 else 2
	character_art.flip_h = face_left
	character_art.region_rect = Rect2(
		column * CHARACTER_FRAME_WIDTH,
		0,
		CHARACTER_FRAME_WIDTH,
		CHARACTER_FRAME_HEIGHT
	)
	queue_redraw()

func _draw() -> void:
	var character_art := get_node_or_null("CharacterArt") as Sprite2D
	if character_art != null and character_art.texture != null and character_art.visible:
		return
	# Geometric placeholder player.
	draw_circle(Vector2(0, 4), 14.0, Color("#d97962"))
	draw_circle(Vector2(0, -10), 10.0, Color("#f2c29b"))
	draw_rect(Rect2(-11, -20, 22, 6), Color("#384b68"))
	draw_circle(Vector2(4, -11), 1.8, Color("#202b3d"))
	draw_line(Vector2.ZERO, facing_direction * 24.0, Color("#f4d35e"), 3.0)
