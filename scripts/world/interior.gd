extends Node2D

@export_enum("farmhouse", "general_store", "blacksmith", "herb_shop") var interior_id := "farmhouse"
const MAP_SIZE := Vector2(1600, 900)
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const HUD_SCRIPT := preload("res://scripts/ui/stage3_hud.gd")
const EXIT_SCRIPT := preload("res://scripts/world/interior_exit.gd")
const BACKGROUNDS := {
	"farmhouse": "res://assets/scenes/interiors/farmhouse_interior_clean.png",
	"general_store": "res://assets/scenes/interiors/general_store_interior_clean.png",
	"blacksmith": "res://assets/scenes/interiors/blacksmith_interior_clean.png",
	"herb_shop": "res://assets/scenes/imported_extra/store_interior.png",
}
const TITLES := {"farmhouse": "农舍", "general_store": "杂货店", "blacksmith": "铁匠铺", "herb_shop": "药草店"}

func _ready() -> void:
	var requested_id := str(WorldManager.current_region)
	if requested_id.begins_with("interior_"):
		interior_id = requested_id.trim_prefix("interior_")
	_create_background()
	if get_node_or_null("Player") == null:
		var player := PLAYER_SCENE.instantiate()
		player.name = "Player"
		player.position = Vector2(800, 650)
		add_child(player)
	var exit := Area2D.new()
	exit.name = "InteriorExit"
	exit.position = Vector2(800, 820)
	exit.set_script(EXIT_SCRIPT)
	exit.target_scene = _outside_scene()
	exit.target_region = _outside_region()
	exit.spawn_position = _outside_spawn()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(160, 80)
	collision.shape = shape
	exit.add_child(collision)
	add_child(exit)
	_create_boundaries()
	if interior_id == "general_store":
		_create_store_fixtures()
	queue_redraw()

func _create_store_fixtures() -> void:
	# The counter is both a visual anchor and a solid obstacle; the interaction
	# point sits just below it so the player can stand in front of the clerk.
	var fixtures := StaticBody2D.new()
	fixtures.name = "StoreFixtures"
	add_child(fixtures)
	_add_fixture_collision(fixtures, "CounterCollision", Vector2(1190, 330), Vector2(430, 110))
	_add_fixture_collision(fixtures, "LeftShelfCollision", Vector2(260, 245), Vector2(260, 70))
	_add_fixture_collision(fixtures, "BackShelfCollision", Vector2(810, 150), Vector2(420, 55))
	queue_redraw()

func _add_fixture_collision(parent: Node, collision_name: String, position: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	collision.name = collision_name
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = position
	parent.add_child(collision)

func _create_background() -> void:
	var texture := load(str(BACKGROUNDS.get(interior_id, ""))) as Texture2D
	if texture == null: return
	var background := Sprite2D.new()
	background.name = "InteriorBackground"
	background.texture = texture
	background.position = MAP_SIZE * 0.5
	background.scale = Vector2(MAP_SIZE.x / texture.get_width(), MAP_SIZE.y / texture.get_height())
	background.z_index = -10
	add_child(background)

func _create_boundaries() -> void:
	var body := StaticBody2D.new()
	body.name = "InteriorBoundary"
	add_child(body)
	for item in [[Vector2(800, 10), Vector2(1600, 20)], [Vector2(800, 890), Vector2(1600, 20)], [Vector2(10, 450), Vector2(20, 900)], [Vector2(1590, 450), Vector2(20, 900)]]:
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = item[1]
		collision.position = item[0]
		collision.shape = shape
		body.add_child(collision)

func _outside_scene() -> String:
	return "res://scenes/regions/Farm.tscn" if interior_id == "farmhouse" else "res://scenes/regions/Town.tscn"

func _outside_region() -> String:
	return "farm" if interior_id == "farmhouse" else "town"

func _outside_spawn() -> Vector2:
	return Vector2(245, 385) if interior_id == "farmhouse" else {"general_store": Vector2(275, 440), "blacksmith": Vector2(760, 385), "herb_shop": Vector2(1240, 440)}.get(interior_id, Vector2(240, 450))

func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(70, 80), TITLES.get(interior_id, "室内"), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f4edd5"))
	draw_string(font, Vector2(70, 840), "走到下方出口离开", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f4edd5"))
