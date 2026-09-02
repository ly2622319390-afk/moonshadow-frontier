extends Node2D

@export var npc_data: NPCData
const WALK_SPEED := 95.0
const CHARACTER_FRAME_WIDTH := 768.0
const CHARACTER_FRAME_HEIGHT := 1024.0
const NPC_ART_PATHS := {
	"edrik": {"idle": "res://assets/characters/npcs/edrik/edrik_idle_sheet.png", "walk": "res://assets/characters/npcs/edrik/edrik_walk_sheet.png"},
	"mira": {"idle": "res://assets/characters/npcs/mira/mira_idle_sheet.png", "walk": "res://assets/characters/npcs/mira/mira_walk_sheet.png"},
	"rowan": {"idle": "res://assets/characters/npcs/rowan/rowan_idle_sheet.png", "walk": "res://assets/characters/npcs/rowan/rowan_walk_sheet.png"},
	"ivy": {"idle": "res://assets/characters/npcs/ivy/ivy_idle_sheet.png", "walk": "res://assets/characters/npcs/ivy/ivy_walk_sheet.png"},
}
var current_action := ""
var target_position := Vector2.ZERO
var active_region := "none"
var character_art: Sprite2D
var facing_direction := Vector2.DOWN

func _ready() -> void:
	add_to_group("npcs")
	z_index = 8
	_setup_character_art()
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.day_started.connect(_on_day_started)
	_update_schedule()
	QuestManager.quest_changed.connect(_on_quest_changed)
	queue_redraw()

func _setup_character_art() -> void:
	if npc_data == null or not NPC_ART_PATHS.has(npc_data.npc_id):
		return
	var texture := load(str(NPC_ART_PATHS[npc_data.npc_id].idle)) as Texture2D
	if texture == null:
		return
	character_art = Sprite2D.new()
	character_art.name = "CharacterArt"
	character_art.texture = texture
	character_art.region_enabled = true
	character_art.region_rect = Rect2(0, 0, CHARACTER_FRAME_WIDTH, CHARACTER_FRAME_HEIGHT)
	character_art.scale = Vector2(0.06, 0.06)
	character_art.position = Vector2(0, -30)
	character_art.z_index = 1
	add_child(character_art)

func _update_character_art(is_moving: bool) -> void:
	if character_art == null or npc_data == null:
		return
	var paths: Dictionary = NPC_ART_PATHS.get(npc_data.npc_id, {})
	var desired_texture := load(str(paths.walk if is_moving else paths.idle)) as Texture2D
	if desired_texture != null and character_art.texture != desired_texture:
		character_art.texture = desired_texture
	var column := 0
	if absf(facing_direction.x) > absf(facing_direction.y):
		column = 3 if facing_direction.x > 0.0 else 2
	else:
		column = 0 if facing_direction.y > 0.0 else 1
	character_art.region_rect = Rect2(column * CHARACTER_FRAME_WIDTH, 0, CHARACTER_FRAME_WIDTH, CHARACTER_FRAME_HEIGHT)

func _process(delta: float) -> void:
	if active_region != _get_region_name():
		visible = false
		return
	visible = true
	var movement_offset := target_position - global_position
	var is_moving := movement_offset.length_squared() > 1.0
	if is_moving:
		facing_direction = movement_offset.normalized()
	global_position = global_position.move_toward(target_position, WALK_SPEED * delta)
	_update_character_art(is_moving)
	queue_redraw()

func _get_region_name() -> String:
	var node: Node = self
	while node != null:
		var value = node.get("region_name")
		if value != null:
			return str(value)
		node = node.get_parent()
	return "none"

func _on_time_changed(_day: int, _minutes: int, _period: String) -> void:
	_update_schedule()

func _on_day_started(_day: int) -> void:
	_update_schedule()

func _on_quest_changed() -> void:
	_update_schedule()

func _update_schedule() -> void:
	if npc_data == null:
		return
	if npc_data.npc_id == "ivy" and not QuestManager.moonstone_repaired:
		active_region = "none"
		current_action = "等待石碑修复"
		return
	if npc_data.npc_id == "rowan" and TimeManager.day % 3 != 0:
		active_region = "none"
		current_action = "不在边境"
		return
	var hour := TimeManager.minutes / 60
	for entry in npc_data.schedule:
		if hour >= int(entry.start) and hour < int(entry.end):
			active_region = str(entry.region)
			target_position = entry.target
			current_action = str(entry.action)
			return

func get_dialogue() -> String:
	return npc_data.dialogue if npc_data else ""

func get_display_name() -> String:
	return npc_data.display_name if npc_data else "NPC"

func _draw() -> void:
	if npc_data == null:
		return
	if character_art != null and character_art.texture != null and character_art.visible:
		return
	draw_circle(Vector2.ZERO, 13.0, npc_data.placeholder_color)
	draw_circle(Vector2(0, -14), 9.0, Color("#f2c29b"))
