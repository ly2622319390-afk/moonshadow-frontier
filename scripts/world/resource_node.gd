extends Area2D

@export var resource_data: ResourceData
var is_available := true
var _respawn_timer: SceneTreeTimer

func _ready() -> void:
	add_to_group("resource_nodes")
	z_index = 5
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	collision.shape = shape
	add_child(collision)
	queue_redraw()

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
