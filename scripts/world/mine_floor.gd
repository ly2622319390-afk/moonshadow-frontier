extends Node2D

@export var floor_index := 1
const MAP_SIZE := Vector2(1600, 900)
const EXIT_SCRIPT := preload("res://scripts/world/region_exit.gd")
const RESOURCE_NODE_SCRIPT := preload("res://scripts/world/resource_node.gd")
const BACKGROUND_PATHS := {
	1: "res://assets/scenes/imported/mine_background.png",
	2: "res://assets/scenes/imported_extra/mine_floor_2.png",
}
const MINERALS := {
	"copper_ore": preload("res://resources/data/resources/copper_ore.tres"),
	"iron_ore": preload("res://resources/data/resources/iron_ore.tres"),
	"moonlight_ore": preload("res://resources/data/resources/moonlight_ore.tres"),
}
const MINERAL_WEIGHTS := {
	1: {"copper_ore": 0.60, "iron_ore": 0.30, "moonlight_ore": 0.10},
	2: {"copper_ore": 0.20, "iron_ore": 0.45, "moonlight_ore": 0.35},
}

func _ready() -> void:
	_create_background_art()
	_create_boundaries()
	_create_exits()
	_create_minerals()
	TimeManager.time_changed.connect(_on_time_changed)
	queue_redraw()

func _create_background_art() -> void:
	var texture := load(str(BACKGROUND_PATHS.get(floor_index, BACKGROUND_PATHS[1]))) as Texture2D
	if texture == null:
		return
	var background := Sprite2D.new()
	background.name = "SceneBackgroundArt"
	background.texture = texture
	background.position = MAP_SIZE * 0.5
	background.scale = Vector2(MAP_SIZE.x / texture.get_width(), MAP_SIZE.y / texture.get_height())
	background.z_index = -10
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(background)

func _on_time_changed(_day: int, _minutes: int, _period: String) -> void:
	queue_redraw()

func _create_boundaries() -> void:
	var body := StaticBody2D.new()
	body.name = "MineBoundary"
	add_child(body)
	_add_boundary(body, "TopBoundary", Vector2(800, 0), Vector2(1600, 32))
	_add_boundary(body, "BottomBoundary", Vector2(800, 900), Vector2(1600, 32))
	_add_boundary(body, "LeftBoundary", Vector2(0, 450), Vector2(32, 900))
	_add_boundary(body, "RightBoundary", Vector2(1600, 450), Vector2(32, 900))

func _add_boundary(parent: Node, boundary_name: String, position: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	collision.name = boundary_name
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = position
	parent.add_child(collision)

func _add_exit(exit_name: String, position: Vector2, target_scene: String, target_region: String, spawn: Vector2) -> void:
	var area := Area2D.new()
	area.name = exit_name
	area.position = position
	area.set_script(EXIT_SCRIPT)
	area.target_scene = target_scene
	area.target_region = target_region
	area.spawn_position = spawn
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(90, 150)
	collision.shape = shape
	area.add_child(collision)
	add_child(area)

func _create_exits() -> void:
	_add_exit("MineEntranceExit", Vector2(55, 450), "res://scenes/regions/Forest.tscn", "forest", Vector2(1460, 700))
	if floor_index == 1:
		_add_exit("StairsDown", Vector2(1450, 700), "res://scenes/regions/MineFloor2.tscn", "mine_2", Vector2(140, 180))
	else:
		_add_exit("StairsUp", Vector2(1450, 180), "res://scenes/regions/Mine.tscn", "mine_1", Vector2(140, 700))

func _create_minerals() -> void:
	var positions: Array = []
	if floor_index == 1:
		positions = [Vector2(480, 280), Vector2(760, 650), Vector2(1080, 350), Vector2(1250, 600)]
	else:
		positions = [Vector2(350, 650), Vector2(620, 300), Vector2(920, 620), Vector2(1100, 280), Vector2(1250, 560)]
	var rng := RandomNumberGenerator.new()
	rng.seed = floor_index * 1000 + TimeManager.day
	for position in positions:
		var mineral_id := _pick_mineral_id(rng)
		var node := Area2D.new()
		node.name = "%sNode" % mineral_id
		node.position = position
		node.set_script(RESOURCE_NODE_SCRIPT)
		node.resource_data = MINERALS[mineral_id]
		add_child(node)

func _pick_mineral_id(rng: RandomNumberGenerator) -> String:
	var roll := rng.randf()
	var cumulative := 0.0
	for mineral_id in MINERAL_WEIGHTS[floor_index]:
		cumulative += MINERAL_WEIGHTS[floor_index][mineral_id]
		if roll <= cumulative:
			return mineral_id
	return "moonlight_ore"

func _draw() -> void:
	if get_node_or_null("SceneBackgroundArt") != null:
		draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), TimeManager.get_ambient_tint())
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(70, 80), "矿洞 · 第 %d 层" % floor_index, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#eee8d0"))
		draw_string(font, Vector2(70, 840), "左侧：返回森林    右侧：楼梯出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#eee8d0"))
		return
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("#3f3e4c"))
	draw_rect(Rect2(90, 100, 1420, 700), Color("#555464"))
	draw_circle(Vector2(800, 450), 260, Color("#454452"))
	draw_line(Vector2(120, 450), Vector2(1480, 450), Color("#7a7587"), 18.0)
	draw_rect(Rect2(1370, 610 if floor_index == 1 else 90, 160, 180), Color("#252530"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(70, 80), "矿洞 · 第 %d 层" % floor_index, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#eee8d0"))
	draw_string(font, Vector2(70, 840), "左侧：返回森林    右侧：楼梯出口", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#eee8d0"))
