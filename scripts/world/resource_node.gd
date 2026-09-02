extends Area2D

@export var resource_data: ResourceData
var is_available := true
var _respawn_timer: SceneTreeTimer
var resource_art: Sprite2D
const RESOURCE_ART_PATHS := {
	"tree": "res://assets/objects/imported/tree.png",
	"stone": "res://assets/objects/resources/stone_node.png",
	"copper_ore": "res://assets/objects/resources/copper_ore_node.png",
	"iron_ore": "res://assets/objects/resources/iron_ore_node.png",
	"moonlight_ore": "res://assets/objects/resources/moonlight_ore_node.png",
	"wild_berries": "res://assets/objects/resources/wild_berries_bush.png",
	"herb": "res://assets/objects/resources/herb_plant.png",
	"mushroom": "res://assets/objects/resources/mushroom_cluster.png",
	"reed": "res://assets/objects/resources/reed_cluster.png",
}

func _ready() -> void:
	add_to_group("resource_nodes")
	z_index = 5
	_setup_resource_art()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	collision.shape = shape
	add_child(collision)
	queue_redraw()

func _setup_resource_art() -> void:
	if resource_data == null:
		return
	var path := str(RESOURCE_ART_PATHS.get(resource_data.resource_id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var texture := load(path) as Texture2D
	if texture == null:
		return
	resource_art = Sprite2D.new()
	resource_art.name = "ResourceArt"
	resource_art.texture = texture
	resource_art.scale = Vector2(0.07, 0.07)
	resource_art.position = Vector2(0, -12)
	resource_art.z_index = 1
	add_child(resource_art)

func try_collect(tool_id: String) -> String:
	if not is_available:
		return "unavailable"
	if resource_data == null:
		return "invalid"
	if resource_data.required_tool_id != tool_id:
		return "needs_%s" % resource_data.required_tool_id
	is_available = false
	monitoring = false
	visible = false
	WorldManager.temporary_drops.append({"resource_id": resource_data.resource_id, "display_name": resource_data.display_name, "collected_at_day": TimeManager.day})
	WorldManager.add_item(resource_data.resource_id)
	_respawn_timer = get_tree().create_timer(resource_data.respawn_seconds)
	_respawn_timer.timeout.connect(_respawn)
	return "collected"

func _respawn() -> void:
	is_available = true
	monitoring = true
	visible = true
	queue_redraw()

func _draw() -> void:
	if resource_data == null:
		return
	if resource_art != null and resource_art.texture != null and resource_art.visible:
		return
	if resource_data.placeholder_shape == "tree":
		draw_rect(Rect2(-10, 0, 20, 35), Color("#704b35"))
		draw_circle(Vector2(0, -10), 35, resource_data.placeholder_color)
		draw_circle(Vector2(-20, 0), 23, resource_data.placeholder_color)
		draw_circle(Vector2(20, 0), 23, resource_data.placeholder_color)
	elif resource_data.placeholder_shape == "reed":
		for offset in [-18.0, -6.0, 6.0, 18.0]:
			draw_line(Vector2(offset, 22), Vector2(offset + 5, -28), resource_data.placeholder_color, 5.0)
	else:
		draw_circle(Vector2.ZERO, 25, resource_data.placeholder_color)
		draw_circle(Vector2(-8, -6), 4, Color(1, 1, 1, 0.45))
