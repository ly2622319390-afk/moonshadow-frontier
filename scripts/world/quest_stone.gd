extends Area2D

var stone_art: Sprite2D
const DAMAGED_ART := "res://assets/quests/moonstone_obelisk_damaged.png"
const REPAIRED_ART := "res://assets/quests/moonstone_obelisk_repaired.png"

func _ready() -> void:
	add_to_group("quest_stones")
	z_index = 4
	QuestManager.quest_changed.connect(_on_quest_changed)
	_setup_art()
	queue_redraw()

func _setup_art() -> void:
	stone_art = Sprite2D.new()
	stone_art.name = "MoonstoneObeliskArt"
	stone_art.scale = Vector2(0.10, 0.10)
	stone_art.position = Vector2(0, -18)
	stone_art.z_index = 1
	add_child(stone_art)
	_update_art()

func _update_art() -> void:
	if stone_art == null:
		return
	var path := REPAIRED_ART if QuestManager.moonstone_repaired else DAMAGED_ART
	stone_art.texture = load(path) as Texture2D

func try_interact() -> String:
	return QuestManager.interact_with_stone()

func _on_quest_changed() -> void:
	_update_art()
	queue_redraw()

func _draw() -> void:
	if stone_art != null and stone_art.texture != null:
		return
	var color := Color("#75c6df") if QuestManager.moonstone_repaired else Color("#615b70")
	draw_rect(Rect2(-30, -42, 60, 84), color)
	draw_line(Vector2(-12, -24), Vector2(10, 20), Color("#252532"), 5.0)
	draw_line(Vector2(12, -16), Vector2(-8, 28), Color("#252532"), 4.0)
