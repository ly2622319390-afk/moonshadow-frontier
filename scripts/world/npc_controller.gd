extends Node2D

@export var npc_data: NPCData
const WALK_SPEED := 95.0
var current_action := ""
var target_position := Vector2.ZERO
var active_region := "none"
var character_art: Sprite2D
const EDRIK_FRAME_SIZE := 256.0

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
	if npc_data == null or npc_data.npc_id != "edrik":
		return
	var texture := load("res://assets/characters/npcs/edrik/edrik_source_sheet.png") as Texture2D
	if texture == null:
		return
	character_art = Sprite2D.new()
	character_art.name = "CharacterArt"
	character_art.texture = texture
	character_art.region_enabled = true
	character_art.region_rect = Rect2(0, 0, EDRIK_FRAME_SIZE, EDRIK_FRAME_SIZE)
	character_art.scale = Vector2(0.25, 0.25)
	character_art.position = Vector2(0, -29)
	character_art.z_index = 1
	add_child(character_art)

func _process(delta: float) -> void:
	if active_region != get_parent().get("region_name"):
		visible = false
		return
	visible = true
	global_position = global_position.move_toward(target_position, WALK_SPEED * delta)
	queue_redraw()

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
