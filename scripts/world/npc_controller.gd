extends CharacterBody2D

@export var npc_data: NPCData
const WALK_SPEED := 95.0
const WALK_FRAME_WIDTH := 256.0
const WALK_FRAME_HEIGHT := 256.0
const IDLE_FRAME_WIDTH := 768.0
const IDLE_FRAME_HEIGHT := 1024.0
const NPC_ART_PATHS := {
	"edrik": {"idle": "res://assets/characters/npcs/edrik/edrik_idle_sheet.png", "walk": "res://assets/characters/npcs/edrik/edrik_walk_sheet.png"},
	"mira": {"idle": "res://assets/characters/npcs/mira/mira_idle_sheet.png", "walk": "res://assets/characters/npcs/mira/mira_walk_sheet.png"},
	"rowan": {"idle": "res://assets/characters/npcs/rowan/rowan_idle_sheet.png", "walk": "res://assets/characters/npcs/rowan/rowan_walk_sheet.png"},
	"ivy": {"idle": "res://assets/characters/npcs/ivy/ivy_idle_sheet.png", "walk": "res://assets/characters/npcs/ivy/ivy_walk_sheet.png"},
}
var current_action := ""
var target_position := Vector2.ZERO
var schedule_position := Vector2.ZERO
var detour_active := false
var active_region := "none"
var character_art: Sprite2D
var facing_direction := Vector2.DOWN
var walk_frame := 0
var walk_frame_elapsed := 0.0
var idle_time := 0.0
var rng := RandomNumberGenerator.new()
const WALK_FRAME_INTERVAL := 0.12
const WANDER_RADIUS := 42.0
const REGION_WAYPOINTS := {
	"town": [Vector2(520, 560), Vector2(900, 520), Vector2(1260, 500)],
	"forest": [Vector2(420, 470), Vector2(700, 420), Vector2(1040, 560)],
	"farm": [Vector2(620, 460), Vector2(900, 600)],
}
var waypoint_index := 0
var dialogue_paused := false

func _ready() -> void:
	add_to_group("npcs")
	z_index = 8
	rng.seed = hash(str(npc_data.npc_id if npc_data else "npc"))
	_setup_character_art()
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.day_started.connect(_on_day_started)
	QuestManager.quest_changed.connect(_on_quest_changed)
	_update_schedule(true)
	queue_redraw()

func _setup_character_art() -> void:
	if npc_data == null or not NPC_ART_PATHS.has(npc_data.npc_id): return
	character_art = Sprite2D.new()
	character_art.name = "CharacterArt"
	character_art.texture = load(str(NPC_ART_PATHS[npc_data.npc_id].idle)) as Texture2D
	character_art.region_enabled = true
	character_art.region_rect = Rect2(0, 0, IDLE_FRAME_WIDTH, IDLE_FRAME_HEIGHT)
	character_art.scale = Vector2(0.06, 0.06)
	character_art.position = Vector2(0, -30)
	character_art.z_index = 1
	add_child(character_art)

func _process(delta: float) -> void:
	if active_region != _get_region_name():
		visible = false
		return
	visible = true
	if dialogue_paused:
		velocity = Vector2.ZERO
		walk_frame = 0
		walk_frame_elapsed = 0.0
		_update_character_art(false)
		return
	idle_time += delta
	if detour_active and target_position.distance_to(global_position) < 6.0:
		detour_active = false
		target_position = schedule_position
		idle_time = 0.0
	if idle_time > 2.5 and target_position.distance_to(global_position) < 3.0:
		idle_time = 0.0
		var waypoints: Array = REGION_WAYPOINTS.get(_get_region_name(), [])
		if not waypoints.is_empty() and rng.randf() > 0.35:
			target_position = waypoints[waypoint_index % waypoints.size()]
			waypoint_index += 1
		else:
			var angle := rng.randf_range(0.0, TAU)
			target_position += Vector2.from_angle(angle) * rng.randf_range(0.0, WANDER_RADIUS)
		target_position.x = clampf(target_position.x, 60.0, 1540.0)
		target_position.y = clampf(target_position.y, 70.0, 830.0)
	var offset := target_position - global_position
	var moving := offset.length_squared() > 9.0
	if moving:
		facing_direction = offset.normalized()
		walk_frame_elapsed += delta
		if walk_frame_elapsed >= WALK_FRAME_INTERVAL:
			walk_frame_elapsed = fmod(walk_frame_elapsed, WALK_FRAME_INTERVAL)
			walk_frame = (walk_frame + 1) % 4
		velocity = offset.normalized() * WALK_SPEED
		move_and_slide()
		if get_slide_collision_count() > 0:
			var collision := get_slide_collision(0)
			var normal := collision.get_normal()
			# Pick a short tangent waypoint so buildings do not deadlock the schedule path.
			var tangent := Vector2(-normal.y, normal.x)
			if tangent.dot(offset) < 0.0:
				tangent = -tangent
			target_position = global_position + tangent * 70.0 + offset.normalized() * 45.0
			detour_active = true
			target_position.x = clampf(target_position.x, 60.0, 1540.0)
			target_position.y = clampf(target_position.y, 70.0, 830.0)
	else:
		velocity = Vector2.ZERO
		walk_frame = 0
		walk_frame_elapsed = 0.0
	_update_character_art(moving)

func _update_character_art(moving: bool) -> void:
	if character_art == null or npc_data == null: return
	var paths: Dictionary = NPC_ART_PATHS.get(npc_data.npc_id, {})
	var texture := load(str(paths.walk if moving else paths.idle)) as Texture2D
	if texture != null: character_art.texture = texture
	var frame_width := IDLE_FRAME_WIDTH
	var frame_height := IDLE_FRAME_HEIGHT
	var column := 0
	var row := 0
	if moving:
		frame_width = WALK_FRAME_WIDTH
		frame_height = WALK_FRAME_HEIGHT
		column = walk_frame
		# Walk sheet rows: down, right, up, left.
		if absf(facing_direction.x) > absf(facing_direction.y):
			row = 3 if facing_direction.x < 0.0 else 1
		else:
			row = 0 if facing_direction.y > 0.0 else 2
		character_art.scale = Vector2(0.24, 0.24)
	else:
		# Idle sheet remains the original down/right/up/left 4x1 layout.
		if absf(facing_direction.x) > absf(facing_direction.y):
			column = 3 if facing_direction.x < 0.0 else 1
		else:
			column = 0 if facing_direction.y > 0.0 else 2
		character_art.scale = Vector2(0.06, 0.06)
	character_art.flip_h = false
	character_art.region_rect = Rect2(column * frame_width, row * frame_height, frame_width, frame_height)

func _get_region_name() -> String:
	var node: Node = self
	while node:
		var value: Variant = node.get("region_name")
		if value != null: return str(value)
		node = node.get_parent()
	return "none"

func _on_time_changed(_day: int, _minutes: int, _period: String) -> void: _update_schedule(false)
func _on_day_started(_day: int) -> void: _update_schedule(true)
func _on_quest_changed() -> void: _update_schedule(false)

func _update_schedule(reset_position: bool) -> void:
	if npc_data == null: return
	if npc_data.npc_id == "ivy" and not QuestManager.moonstone_repaired:
		active_region = "none"; current_action = "等待石碑修复"; return
	if npc_data.npc_id == "rowan" and TimeManager.day % 3 != 0:
		active_region = "none"; current_action = "不在边境"; return
	var hour := TimeManager.minutes / 60
	for entry in npc_data.schedule:
		if hour >= int(entry.start) and hour < int(entry.end):
			active_region = str(entry.region)
			current_action = str(entry.action)
			if reset_position or active_region == _get_region_name():
				schedule_position = entry.target
				target_position = schedule_position
				detour_active = false
			return

func resume_schedule() -> void:
	dialogue_paused = false
	_update_schedule(false)

func begin_dialogue() -> void:
	dialogue_paused = true
	velocity = Vector2.ZERO
	target_position = global_position
	detour_active = false
	walk_frame = 0
	walk_frame_elapsed = 0.0


func get_dialogue() -> String: return npc_data.dialogue if npc_data else ""
func get_display_name() -> String: return npc_data.display_name if npc_data else "NPC"

func _draw() -> void:
	if npc_data == null or (character_art != null and character_art.texture != null and character_art.visible): return
	draw_circle(Vector2.ZERO, 13.0, npc_data.placeholder_color)
	draw_circle(Vector2(0, -14), 9.0, Color("#f2c29b"))
