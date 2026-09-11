extends CharacterBody2D

const MOVE_SPEED := 220.0
const MOVE_ACCELERATION := 1500.0
const MOVE_DECELERATION := 1900.0
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
var selected_tool_index := 0 # -1 means a seed/item is selected
var selected_crop_index := 0
var facing_direction := Vector2.DOWN
var last_tool_time_msec := -100000
var last_action_message := "1-5：选择工具 | Q：切换种子 | 空格：使用 | E：在家睡觉"
var walk_frame := 0
var action_tween: Tween
var walk_distance := 0.0
const WALK_FRAME_DISTANCE := 24.0
const WALK_FRAME_SEQUENCE := [0, 1, 2, 3]
const WALK_FRAME_WIDTH := 256.0
const WALK_FRAME_HEIGHT := 256.0
const IDLE_FRAME_WIDTH := 768.0
const IDLE_FRAME_HEIGHT := 1024.0
const PLAYER_IDLE_TEXTURE: Texture2D = preload("res://assets/characters/player/player_idle_sheet.png")
const PLAYER_WALK_TEXTURE: Texture2D = preload("res://assets/characters/player/player_walk_4x4.png")
const TOOL_ART_PATHS := {"hoe": "res://assets/tools/tool_hoe.png", "axe": "res://assets/tools/tool_axe.png", "pickaxe": "res://assets/tools/tool_pickaxe.png", "fishing_rod": "res://assets/tools/tool_fishing_rod.png", "watering_can": "res://assets/tools/tool_watering_can.png"}
const TOOL_VISUALS := {
	"hoe": {"offset": Vector2(470, -470), "scale": 0.050},
	"axe": {"offset": Vector2(-455, -455), "scale": 0.044},
	"pickaxe": {"offset": Vector2(455, -455), "scale": 0.048},
	"fishing_rod": {"offset": Vector2(470, -470), "scale": 0.055},
	"watering_can": {"offset": Vector2(0, 430), "scale": 0.036},
}
const TOOL_DIRECTION_POSES := {
	"down": {"position": Vector2(11, -23), "rotation": 2.35, "z_index": 2},
	"right": {"position": Vector2(15, -27), "rotation": 1.57, "z_index": 2},
	"up": {"position": Vector2(-10, -31), "rotation": 0.0, "z_index": 0},
	"left": {"position": Vector2(-15, -27), "rotation": 3.14, "z_index": 2},
}
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
		_update_held_tool()
	var target_velocity := input_vector * MOVE_SPEED
	var change_rate := MOVE_ACCELERATION if input_vector.length_squared() > 0.0 else MOVE_DECELERATION
	velocity = velocity.move_toward(target_velocity, change_rate * _delta)
	move_and_slide()
	var is_moving := velocity.length_squared() > 400.0
	if is_moving:
		# Advance the walk cycle by distance so the feet keep pace with movement.
		walk_distance += velocity.length() * _delta
		walk_frame = int(floor(walk_distance / WALK_FRAME_DISTANCE)) % WALK_FRAME_SEQUENCE.size()
	else:
		walk_frame = 0
		walk_distance = 0.0
	_update_character_art(is_moving)

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
			selected_tool_index = -1
			_update_held_tool()
			last_action_message = "已选择种子：%s" % CROP_DEFINITIONS[selected_crop_index].display_name
		elif event.keycode == KEY_SPACE:
			_try_tool_action()
		elif event.keycode == KEY_E:
			if _try_npc_interaction():
				return
			if _try_quest_stone_interaction():
				return
			if get_parent().get("interior_id") == "general_store" and global_position.distance_to(Vector2(1190, 430)) < 100.0:
				ShopManager.toggle()
				last_action_message = "已打开杂货店商品目录。"
				return
			var nearby_plot := _find_target_in_group("farm_plots", 90.0)
			if nearby_plot != null and (selected_tool_index >= 0 or int(nearby_plot.get("state")) == 1):
				_try_tool_action()
				return
			if _near_fishing_spot():
				_try_tool_action()
				return
			if get_parent().get("region_name") == "town" and global_position.distance_to(Vector2(275, 355)) < 170.0:
				ShopManager.toggle()
			else:
				_try_sleep()

func _try_npc_interaction() -> bool:
	for npc in get_tree().get_nodes_in_group("npcs"):
		if is_instance_valid(npc) and npc.visible and global_position.distance_to(npc.global_position) < 65.0:
			if npc.has_method("begin_dialogue"):
				npc.begin_dialogue()
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
	_update_held_tool()

func get_selected_tool_name() -> String:
	return TOOL_DEFINITIONS[selected_tool_index].display_name

func get_selected_crop_name() -> String:
	return CROP_DEFINITIONS[selected_crop_index].display_name

func _try_tool_action() -> void:
	if selected_tool_index < 0:
		_update_held_tool()
		var seed_plot := _find_target_in_group("farm_plots", 90.0)
		if seed_plot != null and int(seed_plot.get("state")) == 1:
			var seed_result: String = str(seed_plot.call("try_interact", "hoe", CROP_DEFINITIONS[selected_crop_index]))
			if seed_result == "seeded":
				_play_seed_animation(seed_plot)
			last_action_message = "播种%s成功。" % CROP_DEFINITIONS[selected_crop_index].display_name if seed_result == "seeded" else "这里不能播种，请先锄地。"
		else:
			last_action_message = "请先选择工具。"
		return
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
			_play_tool_animation(tool.tool_id)
			_play_tool_swing()
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
				_play_tool_animation(tool.tool_id)
				_play_tool_swing()
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
	_play_tool_animation(tool.tool_id)
	_play_tool_swing()
	last_tool_time_msec = now
	last_action_message = "使用%s采集成功，体力-%d。" % [tool.display_name, stamina_cost]
	stamina_changed.emit(stamina, MAX_STAMINA)

func _play_tool_animation(tool_id: String) -> void:
	var art := get_node_or_null("CharacterArt") as Sprite2D
	if art != null:
		# Tool actions must not rotate the whole character around their feet.
		art.rotation = 0.0

func _can_fish_here() -> bool:
	if get_parent().get("region_name") != "river":
		return false
	if _near_fishing_spot():
		return true
	var near_left_bank := global_position.x >= 570.0 and global_position.x <= 680.0 and facing_direction.x > 0.0
	var near_right_bank := global_position.x >= 920.0 and global_position.x <= 1030.0 and facing_direction.x < 0.0
	return near_left_bank or near_right_bank

func _near_fishing_spot() -> bool:
	for spot in get_tree().get_nodes_in_group("fishing_spots"):
		if is_instance_valid(spot) and global_position.distance_to(spot.global_position) < 82.0:
			return true
	return false

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
	_update_held_tool()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.35)

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
	var frame_width := IDLE_FRAME_WIDTH
	var frame_height := IDLE_FRAME_HEIGHT
	var column := 0
	var row := 0
	if is_moving:
		frame_width = WALK_FRAME_WIDTH
		frame_height = WALK_FRAME_HEIGHT
		# 4x4 walk sheet rows: down, up, left, right.
		if absf(facing_direction.x) > absf(facing_direction.y):
			row = 2 if facing_direction.x < 0.0 else 3
		else:
			row = 0 if facing_direction.y > 0.0 else 1
		column = WALK_FRAME_SEQUENCE[walk_frame]
		character_art.scale = Vector2(0.24, 0.24)
	else:
		# Idle sheet remains the original 4x1 layout.
		if absf(facing_direction.x) > absf(facing_direction.y):
			column = 3 if facing_direction.x > 0.0 else 1
		else:
			column = 0 if facing_direction.y > 0.0 else 2
		character_art.scale = Vector2(0.06, 0.06)
	character_art.flip_h = false
	character_art.region_rect = Rect2(
		column * frame_width,
		row * frame_height,
		frame_width,
		frame_height
	)
	character_art.region_filter_clip_enabled = true
	queue_redraw()

func _update_held_tool() -> void:
	var held := get_node_or_null("HeldTool") as Sprite2D
	if held != null:
		# Tools remain usable through the hotbar, but are intentionally not drawn on the character.
		held.visible = false

func _get_facing_key() -> String:
	if absf(facing_direction.x) > absf(facing_direction.y):
		return "left" if facing_direction.x < 0.0 else "right"
	return "up" if facing_direction.y < 0.0 else "down"

func _play_seed_animation(plot: Node) -> void:
	if plot == null:
		return
	var tween := create_tween()
	tween.tween_property(plot, "scale", Vector2(0.88, 0.88), 0.08)
	tween.tween_property(plot, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _play_tool_swing() -> void:
	var held := get_node_or_null("HeldTool") as Sprite2D
	if held == null or not held.visible: return
	if action_tween != null and action_tween.is_valid():
		action_tween.kill()
	var start_rotation := held.rotation
	var tool_id := TOOL_DEFINITIONS[selected_tool_index].tool_id
	var swing_angle := 0.35 if tool_id == "watering_can" else (0.5 if tool_id == "fishing_rod" else 0.8)
	var swing_direction := -1.0 if _get_facing_key() == "left" else 1.0
	action_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	action_tween.tween_property(held, "rotation", start_rotation + swing_angle * swing_direction, 0.10)
	action_tween.tween_property(held, "rotation", start_rotation - swing_angle * 0.35 * swing_direction, 0.12)
	action_tween.tween_property(held, "rotation", start_rotation, 0.10)
	action_tween.finished.connect(_update_held_tool)

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
