extends Area2D

@export var spot_name := "河岸钓鱼点"

func _ready() -> void:
	add_to_group("fishing_spots")
	queue_redraw()

func _draw() -> void:
	# A restrained animated marker keeps the fishing locations readable over the map art.
	draw_circle(Vector2.ZERO, 18.0, Color(0.20, 0.63, 0.72, 0.18))
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color("#d8c478"), 2.0)
	draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, Color(0.92, 0.88, 0.63, 0.72), 1.5)

