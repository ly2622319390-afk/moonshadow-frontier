extends Area2D

@export_file("*.tscn") var target_scene := ""
@export var target_region := ""
@export var spawn_position := Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and target_scene != "":
		WorldManager.change_region(target_scene, target_region, spawn_position)

func _draw() -> void:
	draw_rect(Rect2(-35, -75, 70, 150), Color(1.0, 0.86, 0.35, 0.28), true)
	draw_line(Vector2(-35, -75), Vector2(35, -75), Color("#f4d35e"), 3.0)
	draw_line(Vector2(-35, 75), Vector2(35, 75), Color("#f4d35e"), 3.0)
