extends Node2D

@export_enum("farm", "town", "forest", "river", "mine") var region_name := "farm"
const MAP_SIZE := Vector2(1600, 900)
const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const EXIT_SCRIPT := preload("res://scripts/world/region_exit.gd")
const RESOURCE_NODE_SCRIPT := preload("res://scripts/world/resource_node.gd")
const FARM_PLOT_SCRIPT := preload("res://scripts/world/farm_plot.gd")
const QUEST_STONE_SCRIPT := preload("res://scripts/world/quest_stone.gd")
const BACKGROUND_PATHS := {
	"farm": "res://assets/scenes/imported/farm_background.png",
	"town": "res://assets/scenes/imported/town_background.png",
	"forest": "res://assets/scenes/imported/forest_background.png",
	"river": "res://assets/scenes/imported/river_background.png",
	"mine": "res://assets/scenes/imported/mine_background.png",
}
const RESOURCE_DEFINITIONS := {
	"tree": preload("res://resources/data/resources/tree.tres"),
	"stone": preload("res://resources/data/resources/stone.tres"),
	"wild_berries": preload("res://resources/data/resources/wild_berries.tres"),
	"herb": preload("res://resources/data/resources/herb.tres"),
	"mushroom": preload("res://resources/data/resources/mushroom.tres"),
	"reed": preload("res://resources/data/resources/reed.tres"),
	"copper_ore": preload("res://resources/data/resources/copper_ore.tres"),
	"iron_ore": preload("res://resources/data/resources/iron_ore.tres"),
	"moonlight_ore": preload("res://resources/data/resources/moonlight_ore.tres"),
}

func _ready() -> void:
	_create_background_art()
	_create_scene_objects()
	if not has_node("Player"):
		var created_player := PLAYER_SCENE.instantiate()
		created_player.name = "Player"
		add_child(created_player)
	var player := get_node("Player")
	player.global_position = _default_spawn()
	_create_boundaries()
	_create_exits()
	_create_resources()
	_create_farm_plots()
	_create_npcs()
	_create_quest_content()
	TimeManager.time_changed.connect(_on_time_changed)
	QuestManager.quest_changed.connect(_on_quest_changed)
	queue_redraw()

const SCENE_OBJECTS := {
	"farm": [
		{"name": "PlayerFarmhouse", "path": "res://assets/buildings/farmhouse.png", "position": Vector2(180, 180), "scale": 0.16, "z": 4},
		{"name": "FarmStoneWell", "path": "", "position": Vector2(300, 350), "scale": 0.10, "z": 5},
		{"name": "FarmScarecrow", "path": "res://assets/objects/scarecrow.png", "position": Vector2(760, 520), "scale": 0.09, "z": 4},
		{"name": "FarmCrate", "path": "res://assets/objects/wood_crate.png", "position": Vector2(280, 420), "scale": 0.09, "z": 4},
		{"name": "FarmWoodFence", "path": "res://assets/objects/wood_fence.png", "position": Vector2(560, 730), "scale": 0.08, "z": 4},
	],
	"town": [
		{"name": "GeneralStoreArt", "path": "res://assets/buildings/general_store.png", "position": Vector2(260, 250), "scale": 0.16, "z": 4},
		{"name": "BlacksmithArt", "path": "res://assets/buildings/blacksmith.png", "position": Vector2(760, 230), "scale": 0.16, "z": 4},
		{"name": "HerbShopArt", "path": "res://assets/buildings/herb_shop.png", "position": Vector2(1240, 270), "scale": 0.16, "z": 4},
		{"name": "TravelerStallArt", "path": "res://assets/buildings/traveler_stall.png", "position": Vector2(1040, 620), "scale": 0.13, "z": 4},
		{"name": "AlchemyWorkbenchArt", "path": "res://assets/buildings/alchemy_workbench.png", "position": Vector2(1380, 620), "scale": 0.11, "z": 5},
		{"name": "TownNoticeBoardArt", "path": "res://assets/buildings/notice_board.png", "position": Vector2(520, 560), "scale": 0.09, "z": 5},
	],
	"forest": [
		{"name": "WoodBridgeArt", "path": "res://assets/objects/wood_bridge.png", "position": Vector2(800, 760), "scale": 0.14, "z": 4},
		{"name": "MineEntranceArt", "path": "res://assets/buildings/mine_entrance.png", "position": Vector2(1450, 700), "scale": 0.14, "z": 4},
	],
	"river": [
		{"name": "WoodBridgeArt", "path": "res://assets/objects/wood_bridge.png", "position": Vector2(800, 450), "scale": 0.14, "z": 4},
	],
}

func _create_scene_objects() -> void:
	var object_layer: Node = get_node_or_null("ObjectLayer") if has_node("ObjectLayer") else self
	for data in SCENE_OBJECTS.get(region_name, []):
		var asset_path := str(data.path)
		if data.name == "FarmStoneWell":
			asset_path = "res://assets/buildings/farm_well_repaired.png" if WorldManager.well_repaired else "res://assets/buildings/farm_well_stone.png"
		var texture := load(asset_path) as Texture2D
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.name = str(data.name)
		sprite.texture = texture
		sprite.position = data.position
		sprite.scale = Vector2(float(data.scale), float(data.scale))
		sprite.z_index = int(data.z)
		object_layer.add_child(sprite)

func _create_background_art() -> void:
	var path := str(BACKGROUND_PATHS.get(region_name, ""))
	if path.is_empty():
		return
	var texture := load(path) as Texture2D
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

func _on_quest_changed() -> void:
	if region_name == "forest" and QuestManager.moonstone_repaired and not has_node("WitchSanctumExit"):
		_add_quest_exit()
	queue_redraw()

func _default_spawn() -> Vector2:
	return {"farm": Vector2(360, 450), "town": Vector2(240, 450), "forest": Vector2(240, 450), "river": Vector2(800, 220), "mine": Vector2(240, 450)}.get(region_name, Vector2(360, 450))

func _create_boundaries() -> void:
	var body := StaticBody2D.new()
	body.name = "MapBoundary"
	add_child(body)
	_add_boundary(body, "TopBoundary", Vector2(800, 0), Vector2(1600, 32))
	_add_boundary(body, "BottomBoundary", Vector2(800, 900), Vector2(1600, 32))
	_add_boundary(body, "LeftBoundary", Vector2(0, 450), Vector2(32, 900))
	_add_boundary(body, "RightBoundary", Vector2(1600, 450), Vector2(32, 900))

func _add_boundary(parent: Node, boundary_name: String, boundary_position: Vector2, boundary_size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	collision.name = boundary_name
	var shape := RectangleShape2D.new()
	shape.size = boundary_size
	collision.shape = shape
	collision.position = boundary_position
	parent.add_child(collision)

func _create_exits() -> void:
	var exits: Array = {
		"farm": [{"name": "TownExit", "position": Vector2(1545, 450), "target": "res://scenes/regions/Town.tscn", "region": "town", "spawn": Vector2(140, 450)}],
		"town": [{"name": "FarmExit", "position": Vector2(55, 450), "target": "res://scenes/regions/Farm.tscn", "region": "farm", "spawn": Vector2(1460, 450)}, {"name": "ForestExit", "position": Vector2(1545, 450), "target": "res://scenes/regions/Forest.tscn", "region": "forest", "spawn": Vector2(140, 450)}],
		"forest": [{"name": "TownExit", "position": Vector2(55, 450), "target": "res://scenes/regions/Town.tscn", "region": "town", "spawn": Vector2(1460, 450)}, {"name": "RiverExit", "position": Vector2(800, 845), "target": "res://scenes/regions/River.tscn", "region": "river", "spawn": Vector2(800, 160)}, {"name": "MineEntrance", "position": Vector2(1545, 700), "target": "res://scenes/regions/Mine.tscn", "region": "mine", "spawn": Vector2(140, 450)}],
		"river": [{"name": "ForestExit", "position": Vector2(800, 55), "target": "res://scenes/regions/Forest.tscn", "region": "forest", "spawn": Vector2(800, 730)}],
		"mine": [{"name": "ForestExit", "position": Vector2(55, 450), "target": "res://scenes/regions/Forest.tscn", "region": "forest", "spawn": Vector2(1460, 700)}]
	}.get(region_name, [])
	for data in exits:
		var area := Area2D.new()
		area.name = data.name
		area.position = data.position
		area.set_script(EXIT_SCRIPT)
		area.target_scene = data.target
		area.target_region = data.region
		area.spawn_position = data.spawn
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(70, 150)
		collision.shape = shape
		area.add_child(collision)
		add_child(area)

func _create_resources() -> void:
	var object_layer: Node = get_node_or_null("ObjectLayer") if has_node("ObjectLayer") else self
	var placements: Array = {
		"farm": [["tree", Vector2(900, 690)], ["wild_berries", Vector2(1050, 690)]],
		"forest": [["tree", Vector2(180, 180)], ["tree", Vector2(420, 230)], ["tree", Vector2(1100, 220)], ["wild_berries", Vector2(320, 470)], ["herb", Vector2(680, 600)], ["mushroom", Vector2(980, 620)]],
		"river": [["reed", Vector2(570, 250)], ["reed", Vector2(1030, 650)]],
		"mine": [["stone", Vector2(580, 400)], ["stone", Vector2(920, 500)], ["stone", Vector2(760, 650)]],
	}.get(region_name, [])
	for placement in placements:
		var resource_node := Area2D.new()
		resource_node.name = "%sNode" % placement[0]
		resource_node.position = placement[1]
		resource_node.set_script(RESOURCE_NODE_SCRIPT)
		resource_node.resource_data = RESOURCE_DEFINITIONS[placement[0]]
		object_layer.add_child(resource_node)

func _create_farm_plots() -> void:
	if region_name != "farm":
		return
	var plot_layer: Node = get_node_or_null("FarmPlotLayer") if has_node("FarmPlotLayer") else self
	for row in range(3):
		for column in range(4):
			var plot := Node2D.new()
			plot.name = "FarmPlot_%d_%d" % [column, row]
			plot.position = Vector2(420 + column * 68, 500 + row * 68)
			plot.set_script(FARM_PLOT_SCRIPT)
			plot.grid_position = Vector2i(column, row)
			plot.z_index = 2
			plot_layer.add_child(plot)

func _create_npcs() -> void:
	var npc_layer: Node = get_node_or_null("NPCLayer") if has_node("NPCLayer") else self
	for npc_data in NPCatalog.NPCS:
		var npc := Node2D.new()
		npc.name = "NPC_" + npc_data.npc_id
		npc.set_script(preload("res://scripts/world/npc_controller.gd"))
		npc.npc_data = npc_data
		npc.position = Vector2(200, 200)
		npc_layer.add_child(npc)

func _create_quest_content() -> void:
	if region_name != "forest":
		return
	var stone := Area2D.new()
	stone.name = "MoonstoneObelisk"
	stone.position = Vector2(920, 300)
	stone.set_script(QUEST_STONE_SCRIPT)
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 45.0
	collision.shape = shape
	stone.add_child(collision)
	add_child(stone)
	if QuestManager.moonstone_repaired:
		_add_quest_exit()

func _add_quest_exit() -> void:
	if has_node("WitchSanctumExit"):
		return
	var area := Area2D.new()
	area.name = "WitchSanctumExit"
	area.position = Vector2(1390, 120)
	area.set_script(EXIT_SCRIPT)
	area.target_scene = "res://scenes/regions/Sanctum.tscn"
	area.target_region = "sanctum"
	area.spawn_position = Vector2(140, 450)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(90, 150)
	collision.shape = shape
	area.add_child(collision)
	add_child(area)

func _draw() -> void:
	var has_background_art := get_node_or_null("SceneBackgroundArt") != null
	if has_background_art:
		# The generated scene image replaces the flat debug geometry below.
		draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), TimeManager.get_ambient_tint())
		var font := ThemeDB.fallback_font
		var region_names := {"farm": "农场", "town": "小镇", "forest": "森林", "river": "河流", "mine": "矿洞"}
		draw_string(font, Vector2(70, 80), region_names.get(region_name, region_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f4edd5"))
		draw_string(font, Vector2(70, 840), "走到黄色标记处进入其他区域", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f4edd5"))
		return
	var colors := {"farm": Color("#89ad68"), "town": Color("#8c9c83"), "forest": Color("#426b54"), "river": Color("#4f8eaf"), "mine": Color("#4c4b5b")}
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), colors.get(region_name, Color("#6f9b63")))
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), TimeManager.get_ambient_tint())
	if region_name == "farm":
		draw_rect(Rect2(130, 180, 230, 150), Color("#a97952"))
		draw_rect(Rect2(410, 180, 210, 150), Color("#a97952"))
		draw_rect(Rect2(660, 390, 850, 120), Color("#c5a873"))
		draw_rect(Rect2(380, 460, 300, 235), Color("#6c8f58"))
	elif region_name == "town":
		draw_rect(Rect2(110, 260, 330, 190), Color("#c3a77e"))
		draw_rect(Rect2(590, 210, 300, 220), Color("#a77c67"))
		draw_rect(Rect2(1050, 270, 350, 190), Color("#b7a06e"))
	elif region_name == "forest":
		for tree_position in [Vector2(180, 180), Vector2(420, 230), Vector2(700, 160), Vector2(1100, 220), Vector2(1350, 170), Vector2(300, 680), Vector2(1000, 700)]:
			draw_circle(tree_position, 48, Color("#29483d"))
			draw_circle(tree_position - Vector2(0, 28), 30, Color("#5d8c5a"))
	elif region_name == "river":
		draw_rect(Rect2(650, 0, 300, 900), Color("#65b2d0"))
		draw_rect(Rect2(0, 0, 650, 900), Color("#7a9b70"))
		draw_rect(Rect2(950, 0, 650, 900), Color("#7a9b70"))
	elif region_name == "mine":
		draw_circle(Vector2(800, 450), 210, Color("#343442"))
		draw_circle(Vector2(800, 450), 130, Color("#24242f"))
	var font := ThemeDB.fallback_font
	var region_names := {"farm": "农场", "town": "小镇", "forest": "森林", "river": "河流", "mine": "矿洞"}
	draw_string(font, Vector2(70, 80), region_names.get(region_name, region_name), HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("#f4edd5"))
	draw_string(font, Vector2(70, 840), "走到黄色标记处进入其他区域", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#f4edd5"))
