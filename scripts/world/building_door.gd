extends Area2D

@export var interior_id := "farmhouse"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not WorldManager.is_transitioning:
		WorldManager.change_region("res://scenes/regions/Interior.tscn", "interior_" + interior_id, Vector2(800, 650))

func _draw() -> void:
	draw_circle(Vector2.ZERO, 24.0, Color(0.95, 0.78, 0.28, 0.16))
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 20, Color("#f4d35e"), 2.0)
