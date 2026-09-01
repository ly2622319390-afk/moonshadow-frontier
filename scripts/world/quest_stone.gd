extends Area2D

func _ready() -> void:
	add_to_group("quest_stones")
	z_index = 4
	QuestManager.quest_changed.connect(_on_quest_changed)
	queue_redraw()

func try_interact() -> String:
	return QuestManager.interact_with_stone()

func _on_quest_changed() -> void:
	queue_redraw()

func _draw() -> void:
	var color := Color("#75c6df") if QuestManager.moonstone_repaired else Color("#615b70")
	draw_rect(Rect2(-30, -42, 60, 84), color)
	draw_line(Vector2(-12, -24), Vector2(10, 20), Color("#252532"), 5.0)
	draw_line(Vector2(12, -16), Vector2(-8, 28), Color("#252532"), 4.0)
