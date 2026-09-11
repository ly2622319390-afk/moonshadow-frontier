extends Area2D

@export_file("*.tscn") var target_scene := ""
@export var target_region := ""
@export var spawn_position := Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var pulse := create_tween().set_loops()
	pulse.tween_property(self, "modulate:a", 0.55, 0.8)
	pulse.tween_property(self, "modulate:a", 1.0, 0.8)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and target_scene != "":
		WorldManager.change_region(target_scene, target_region, spawn_position)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 34.0, Color(0.18, 0.12, 0.08, 0.75))
	draw_circle(Vector2.ZERO, 27.0, Color(0.92, 0.70, 0.22, 0.20))
	draw_arc(Vector2.ZERO, 32.0, 0.0, TAU, 32, Color("#f4d35e"), 3.0)
	draw_line(Vector2(-19, -7), Vector2(0, -25), Color("#f4d35e"), 3.0)
	draw_line(Vector2(0, -25), Vector2(19, -7), Color("#f4d35e"), 3.0)
	draw_line(Vector2(-19, 7), Vector2(0, 25), Color("#f4d35e"), 3.0)
	draw_line(Vector2(0, 25), Vector2(19, 7), Color("#f4d35e"), 3.0)
