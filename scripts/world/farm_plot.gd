extends Node2D

enum PlotState { NORMAL, TILLED, WATERED, SEEDED, MATURE }

@export var grid_position := Vector2i.ZERO
var state: PlotState = PlotState.NORMAL
var crop_data: CropData
var growth_days := 0
var last_processed_day := 1
var crop_art: Sprite2D
var state_art: Sprite2D
const TILLED_ART := "res://assets/farming/farm_soil_tilled_cutout.png"
const SEEDED_ART := "res://assets/farming/farm_soil_tilled_cutout.png"
const WATERED_ART := "res://assets/objects/farm_soil_watered_patch.png"
const MATURE_ART := "res://assets/objects/farm_crop_mature_patch.png"
const CROP_ART_PATHS := {
	"wheat": {"seed": "res://assets/items/seed_wheat.png", "mature": "res://assets/items/crop_wheat_mature.png"},
	"carrot": {"seed": "res://assets/items/seed_carrot.png", "mature": "res://assets/items/crop_carrot_mature.png"},
	"moonberry": {"seed": "res://assets/items/seed_moonberry.png", "mature": "res://assets/items/crop_moonberry_mature.png"},
}

func _ready() -> void:
	add_to_group("farm_plots")
	_setup_crop_art()
	_setup_state_art()
	_load_state()
	TimeManager.day_started.connect(_on_day_started)
	queue_redraw()

func _setup_crop_art() -> void:
	crop_art = Sprite2D.new()
	crop_art.name = "CropArt"
	crop_art.scale = Vector2(0.055, 0.055)
	crop_art.position = Vector2(0, -6)
	crop_art.z_index = 1
	crop_art.visible = false
	add_child(crop_art)

func _setup_state_art() -> void:
	state_art = Sprite2D.new()
	state_art.name = "StateArt"
	state_art.scale = Vector2(0.055, 0.055)
	state_art.z_index = 0
	state_art.visible = false
	add_child(state_art)

func _update_crop_art() -> void:
	if crop_art == null:
		return
	if crop_data == null or state == PlotState.TILLED or state == PlotState.NORMAL or state == PlotState.MATURE:
		crop_art.visible = false
		if state_art != null:
			state_art.texture = load(MATURE_ART) as Texture2D if state == PlotState.MATURE else (load(TILLED_ART) as Texture2D if state == PlotState.TILLED else null)
			state_art.visible = state_art.texture != null and state != PlotState.NORMAL
		return
	var paths: Dictionary = CROP_ART_PATHS.get(crop_data.crop_id, {})
	var key := "mature" if state == PlotState.MATURE else "seed"
	var texture := load(str(paths.get(key, ""))) as Texture2D
	if texture == null:
		crop_art.visible = false
		return
	crop_art.texture = texture
	crop_art.visible = growth_days == 0 and state_art != null and state_art.visible
	if state_art != null:
		state_art.texture = load(WATERED_ART) as Texture2D if state == PlotState.WATERED else load(SEEDED_ART) as Texture2D
		state_art.visible = state_art.texture != null

func try_interact(tool_id: String, selected_crop: CropData) -> String:
	if tool_id == "hoe":
		if state == PlotState.NORMAL:
			state = PlotState.TILLED
			_save_state()
			_update_crop_art()
			queue_redraw()
			return "tilled"
		if state == PlotState.TILLED:
			if selected_crop == null:
				return "no_crop_selected"
			var seed_count: int = int(WorldManager.inventory.get(selected_crop.seed_item_id, 0))
			if seed_count <= 0:
				return "no_seeds"
			WorldManager.inventory[selected_crop.seed_item_id] = seed_count - 1
			crop_data = selected_crop
			growth_days = 0
			state = PlotState.SEEDED
			_save_state()
			_update_crop_art()
			queue_redraw()
			return "seeded"
		if state == PlotState.MATURE:
			WorldManager.inventory[crop_data.crop_id] = int(WorldManager.inventory.get(crop_data.crop_id, 0)) + 1
			var harvest_name := crop_data.display_name
			crop_data = null
			growth_days = 0
			state = PlotState.TILLED
			_save_state()
			_update_crop_art()
			queue_redraw()
			return "harvested_%s" % harvest_name
	if tool_id == "watering_can" and state == PlotState.SEEDED:
		state = PlotState.WATERED
		_save_state()
		_update_crop_art()
		queue_redraw()
		return "watered"
	return "invalid"

func _on_day_started(new_day: int) -> void:
	_process_days_until(new_day)

func _process_days_until(new_day: int) -> void:
	while last_processed_day < new_day:
		if state == PlotState.WATERED and crop_data != null:
			growth_days += 1
			state = PlotState.MATURE if growth_days >= crop_data.mature_days else PlotState.SEEDED
		last_processed_day += 1
		_save_state()
		_update_crop_art()
	queue_redraw()

func _save_state() -> void:
	WorldManager.farm_plots[grid_position] = {
		"state": int(state),
		"crop_id": crop_data.crop_id if crop_data else "",
		"growth_days": growth_days,
		"last_processed_day": last_processed_day,
	}

func _load_state() -> void:
	var saved: Dictionary = WorldManager.farm_plots.get(grid_position, {})
	if saved.is_empty():
		last_processed_day = TimeManager.day
		_save_state()
		return
	state = int(saved.get("state", PlotState.NORMAL)) as PlotState
	growth_days = int(saved.get("growth_days", 0))
	last_processed_day = int(saved.get("last_processed_day", TimeManager.day))
	var crop_id: String = str(saved.get("crop_id", ""))
	if crop_id != "":
		crop_data = CropCatalog.get_crop(crop_id)
	_process_days_until(TimeManager.day)
	_update_crop_art()

func _draw() -> void:
	if state == PlotState.NORMAL:
		return
	if state_art != null and state_art.visible and state_art.texture != null:
		return
	var base_color := Color("#9e825a")
	if state == PlotState.WATERED:
		base_color = Color("#5d7891")
	draw_rect(Rect2(-23, -23, 46, 46), base_color)
	draw_rect(Rect2(-23, -23, 46, 46), Color("#d5b879"), false, 2.0)
	if crop_data != null and state != PlotState.TILLED:
		var crop_color := crop_data.mature_color if state == PlotState.MATURE else (crop_data.growing_color if growth_days > 0 else crop_data.seed_color)
		draw_circle(Vector2.ZERO, 17.0 if state == PlotState.MATURE else 11.0, crop_color)
		if state != PlotState.MATURE:
			draw_line(Vector2(0, 12), Vector2(0, -12), crop_color.darkened(0.35), 3.0)
