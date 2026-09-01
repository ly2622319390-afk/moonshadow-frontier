extends Node2D

const MAP_SIZE := Vector2(1600, 900)
const EXIT_SCRIPT := preload("res://scripts/world/region_exit.gd")

func _ready() -> void:
	_create_boundaries()
	var exit := Area2D.new()
	exit.name = "ForestExit"
	exit.position = Vector2(55, 450)
	exit.set_script(EXIT_SCRIPT)
	exit.target_scene = "res://scenes/regions/Forest.tscn"
	exit.target_region = "forest"
	exit.spawn_position = Vector2(1390, 120)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(90, 150)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	exit.add_child(collision)
	add_child(exit)
	queue_redraw()

func _create_boundaries() -> void:
	var body := StaticBody2D.new()
	body.name = "SanctumBoundary"
	add_child(body)
	for data in [["Top", Vector2(800, 0), Vector2(1600, 32)], ["Bottom", Vector2(800, 900), Vector2(1600, 32)], ["Left", Vector2(0, 450), Vector2(32, 900)], ["Right", Vector2(1600, 450), Vector2(32, 900)]]:
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = data[2]
		collision.position = data[1]
		collision.shape = shape
		body.add_child(collision)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("#303d5d"))
	draw_circle(Vector2(800, 430), 230, Color("#53698c"))
	draw_circle(Vector2(800, 430), 115, Color("#85c9d6"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(70, 80), "女巫圣地", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f4edd5"))
	draw_string(font, Vector2(70, 840), "左侧出口：返回森林", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f4edd5"))
