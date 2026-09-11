extends Area2D

@export_file("*.tscn") var target_scene := "res://scenes/regions/Town.tscn"
@export var target_region := "town"
@export var spawn_position := Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		WorldManager.change_region(target_scene, target_region, spawn_position)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 34.0, Color(0.92, 0.70, 0.22, 0.16))
	draw_arc(Vector2.ZERO, 30.0, 0.0, TAU, 24, Color("#f4d35e"), 2.0)
