extends Node2D

const MAP_SIZE := Vector2(1600, 900)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	# Flat placeholder map: farm, road, town, and a river landmark.
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("#6f9b63"))
	draw_rect(Rect2(80, 100, 620, 680), Color("#88ad68"))
	draw_rect(Rect2(120, 170, 210, 150), Color("#a97952"))
	draw_rect(Rect2(370, 170, 240, 150), Color("#a97952"))
	draw_rect(Rect2(700, 380, 820, 140), Color("#c5a873"))
	draw_rect(Rect2(1240, 120, 280, 220), Color("#8b9b83"))
	draw_rect(Rect2(1300, 185, 160, 90), Color("#6b7180"))
	draw_rect(Rect2(1460, 398, 60, 104), Color("#d8c17a"))
	draw_rect(Rect2(740, 80, 110, 300), Color("#5f9fc4"))
	draw_rect(Rect2(740, 520, 110, 300), Color("#5f9fc4"))

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(120, 135), "农场", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#f4edd5"))
	draw_string(font, Vector2(1290, 155), "小镇", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#f4edd5"))
	draw_string(font, Vector2(1320, 375), "小镇出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#3e493d"))
	draw_string(font, Vector2(372, 735), "移动：WASD / 方向键", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#26352d"))
