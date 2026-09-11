extends Control

var bar_position := 0.5
var fish_position := 0.5
var overlap := 0.18

func update_positions(new_bar_position: float, new_fish_position: float) -> void:
	bar_position = clampf(new_bar_position, 0.0, 1.0)
	fish_position = clampf(new_fish_position, 0.0, 1.0)
	queue_redraw()

func _draw() -> void:
	var track := Rect2(0.0, 4.0, size.x, size.y - 8.0)
	draw_style_box(_make_box(Color("#241b18"), Color("#d5a84a"), 3, 8), track)
	var target_width := track.size.x * overlap
	var target_x := clampf(track.position.x + track.size.x * fish_position - target_width * 0.5, track.position.x, track.end.x - target_width)
	draw_style_box(_make_box(Color("#5da85b"), Color("#c8ef9c"), 2, 6), Rect2(target_x, track.position.y + 3.0, target_width, track.size.y - 6.0))
	var marker_x := track.position.x + track.size.x * bar_position
	draw_circle(Vector2(marker_x, track.get_center().y), 9.0, Color("#f6d365"))
	draw_circle(Vector2(marker_x, track.get_center().y), 5.0, Color("#fff4bd"))

func _make_box(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	return box
