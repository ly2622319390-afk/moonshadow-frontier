extends CanvasLayer

## Stage 6 UI layer. It only reads game state and forwards existing actions.
## The gameplay managers and save format remain unchanged.

@export var development_mode := true

const TOOL_DEFINITIONS: Array[ToolData] = [
	preload("res://resources/data/tools/hoe.tres"),
	preload("res://resources/data/tools/axe.tres"),
	preload("res://resources/data/tools/pickaxe.tres"),
	preload("res://resources/data/tools/fishing_rod.tres"),
	preload("res://resources/data/tools/watering_can.tres"),
]
const TOOL_ICONS := {"hoe": "锄", "axe": "斧", "pickaxe": "镐", "fishing_rod": "竿", "watering_can": "壶"}
const ITEM_ICONS := {"wheat_seed": "麦", "carrot_seed": "胡", "moonberry_seed": "月"}
const TOOL_TEXTURES := {
	"hoe": "res://assets/tools/tool_hoe.png",
	"axe": "res://assets/tools/tool_axe.png",
	"pickaxe": "res://assets/tools/tool_pickaxe.png",
	"fishing_rod": "res://assets/tools/tool_fishing_rod.png",
	"watering_can": "res://assets/tools/tool_watering_can.png",
}
const ITEM_TEXTURES := {
	"wheat_seed": "res://assets/items/seed_wheat.png",
	"carrot_seed": "res://assets/items/seed_carrot.png",
	"moonberry_seed": "res://assets/items/seed_moonberry.png",
	"wheat": "res://assets/items/crop_wheat_item.png",
	"carrot": "res://assets/items/crop_carrot_item.png",
	"moonberry": "res://assets/items/crop_moonberry_item.png",
	"river_trout": "res://assets/items/fish_river_trout.png",
	"silver_scale_fish": "res://assets/items/fish_silver_scale.png",
	"moonlight_fish": "res://assets/items/moonlight_fish.png",
	"seal_fragment": "res://assets/items/seal_fragment.png",
	"witch_amulet": "res://assets/items/witch_amulet.png",
	"wood": "res://assets/items/resource_wood.png",
	"stone": "res://assets/items/resource_stone.png",
	"copper_ore": "res://assets/items/resource_copper_ore.png",
	"iron_ore": "res://assets/items/resource_iron_ore.png",
	"moonlight_ore": "res://assets/items/resource_moonlight_ore.png",
	"wild_berries": "res://assets/items/forage_wild_berries.png",
	"herb": "res://assets/items/forage_common_herb.png",
	"mushroom": "res://assets/items/forage_mushroom.png",
	"reed": "res://assets/items/forage_moonlight_plant.png",
}
const NPC_PORTRAITS := {
	"edrik": "res://assets/characters/npcs/edrik/edrik_portrait.png",
	"mira": "res://assets/characters/npcs/mira/mira_portrait.png",
	"rowan": "res://assets/characters/npcs/rowan/rowan_portrait.png",
	"ivy": "res://assets/characters/npcs/ivy/ivy_portrait.png",
}
const TOOL_IDS := ["hoe", "axe", "pickaxe", "fishing_rod", "watering_can"]
const SEED_IDS := ["wheat_seed", "carrot_seed", "moonberry_seed"]
const PERIOD_NAMES := {"morning": "早晨", "day": "白天", "dusk": "傍晚", "night": "夜晚"}
const CATEGORY_ORDER := ["种子", "作物", "鱼", "矿物", "采集物", "工具", "任务物品"]
const MAX_STAMINA := 100
const FLAT_PANEL_KEYS := ["status", "date_time", "quickbar", "interaction", "quest_tracker", "dialogue", "shop"]
const TEXTURE_BUTTON_KEYS := ["quickbar_slot", "inventory_slot"]
const UI_TEXTURES := {
	"status": "res://assets/ui/status_bar_background.png",
	"date_time": "res://assets/ui/adapted/date_time_panel_8x1.png",
	"stamina_frame": "res://assets/ui/adapted/stamina_bar_frame_8x1.png",
	"stamina_fill": "res://assets/ui/adapted/stamina_bar_fill_8x1.png",
	"coin": "res://assets/ui/coin_gold.png",
	"quickbar": "res://assets/ui/adapted/quickbar_background_8x1.png",
	"quickbar_slot": "res://assets/ui/quickbar_slot.png",
	"quickbar_selected": "res://assets/ui/quickbar_selected_frame.png",
	"inventory": "res://assets/ui/inventory_background.png",
	"inventory_slot": "res://assets/ui/inventory_slot.png",
	"inventory_selected": "res://assets/ui/inventory_selected_frame.png",
	"interaction": "res://assets/ui/interaction_prompt_panel.png",
	"dialogue": "res://assets/ui/npc_dialogue_panel.png",
	"quest_tracker": "res://assets/ui/quest_tracker_panel.png",
	"shop": "res://assets/ui/shop_window_background.png",
	"button_buy": "res://assets/ui/button_buy.png",
	"button_sell": "res://assets/ui/button_sell.png",
	"button_back": "res://assets/ui/button_back.png",
	"button_close": "res://assets/ui/button_close.png",
}

var ui_root: Control
var status_panel: PanelContainer
var time_label: Label
var weather_label: Label
var stamina_bar: ProgressBar
var stamina_value: Label
var gold_label: Label
var objective_label: Label
var quest_panel: PanelContainer
var quest_collapsed := false
var quest_toggle_button: Button
var hotbar: HBoxContainer
var hotbar_buttons: Array[Button] = []
var selected_slot := 0
var selected_item_id := ""
var action_panel: PanelContainer
var current_item_label: Label
var interaction_label: Label
var message_label: Label
var fishing_label: Label
var inventory_panel: PanelContainer
var inventory_grid: GridContainer
var inventory_category_bar: HBoxContainer
var inventory_category := "全部"
var debug_panel: PanelContainer
var debug_status_label: Label
var shop_panel: PanelContainer
var shop_gold_label: Label
var shop_message_label: Label
var dialogue_panel: PanelContainer
var dialogue_name_label: Label
var dialogue_text_label: Label
var dialogue_portrait: TextureRect
var dialogue_hint_label: Label
var feedback_label: Label
var feedback_tween: Tween
var last_feedback_source := ""

func _ready() -> void:
	layer = 20
	_build_ui()
	_connect_signals()
	_on_time_changed(TimeManager.day, TimeManager.minutes, TimeManager.get_period())
	_refresh_all()

func _build_ui() -> void:
	ui_root = Control.new()
	ui_root.name = "GameUI"
	ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui_root)
	_build_status_panel()
	_build_quest_panel()
	_build_hotbar()
	_build_action_panel()
	_build_feedback_label()
	_build_inventory_panel()
	_build_debug_panel()
	_build_shop_panel()
	_build_dialogue_panel()

func _build_feedback_label() -> void:
	feedback_label = _label("", 14, Color("#f7e7bd"))
	feedback_label.name = "ContextFeedback"
	feedback_label.visible = false
	feedback_label.z_index = 50
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label.add_theme_color_override("font_outline_color", Color("#2b211b"))
	feedback_label.add_theme_constant_override("outline_size", 5)
	feedback_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	feedback_label.size = Vector2(360, 30)
	ui_root.add_child(feedback_label)

func _connect_signals() -> void:
	TimeManager.time_changed.connect(_on_time_changed)
	FishingManager.fishing_changed.connect(_on_fishing_changed)
	ShopManager.shop_changed.connect(_on_shop_changed)
	QuestManager.quest_changed.connect(_on_quest_changed)
	SaveManager.save_message.connect(_on_save_message)

func _panel_style(color: Color, border_color: Color = Color("#80613b")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border_color
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func _button_style(color: Color, border_color: Color) -> StyleBoxFlat:
	var box := _panel_style(color, border_color)
	box.set_corner_radius_all(6)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box

func _apply_panel_style(panel: PanelContainer, color := Color("#30271fdd")) -> void:
	panel.add_theme_stylebox_override("panel", _panel_style(color))

func _texture_style(path: String, left: float, top: float, right: float, bottom: float) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(path) as Texture2D
	box.texture_margin_left = left
	box.texture_margin_top = top
	box.texture_margin_right = right
	box.texture_margin_bottom = bottom
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func _apply_texture_panel(panel: PanelContainer, texture_key: String, margins: Vector4) -> void:
	# Long 3:1/8:1 artwork is decorative, not a nine-patch source.
	# Repeating its corners causes the stretched spikes seen in the HUD screenshot.
	if texture_key in FLAT_PANEL_KEYS:
		return
	var box := _texture_style(str(UI_TEXTURES[texture_key]), margins.x, margins.y, margins.z, margins.w)
	if box.texture != null:
		panel.add_theme_stylebox_override("panel", box)

func _apply_texture_button(button: Button, texture_key: String, selected := false) -> void:
	if texture_key not in TEXTURE_BUTTON_KEYS:
		return
	var path_key := texture_key
	if selected:
		path_key = "inventory_selected" if texture_key == "inventory_slot" else "quickbar_selected"
	var box := _texture_style(str(UI_TEXTURES[path_key]), 22, 22, 22, 22)
	if box.texture != null:
		button.add_theme_stylebox_override("normal", box)
		button.add_theme_stylebox_override("hover", box)
		button.add_theme_stylebox_override("pressed", box)

func _apply_button_style(button: Button, selected := false) -> void:
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color("#f5ead2"))
	button.add_theme_color_override("font_hover_color", Color("#fff6dd"))
	button.add_theme_stylebox_override("normal", _button_style(Color("#49372add"), Color("#80613b")))
	button.add_theme_stylebox_override("hover", _button_style(Color("#6d512d"), Color("#e2b957")))
	button.add_theme_stylebox_override("pressed", _button_style(Color("#8a642e"), Color("#f2d178")))
	button.add_theme_stylebox_override("focus", _button_style(Color("#584329"), Color("#e2b957")))
	if selected:
		button.add_theme_stylebox_override("normal", _button_style(Color("#70532c"), Color("#f4d35e")))

func _label(text := "", size := 14, color := Color("#f5ead2")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _build_status_panel() -> void:
	status_panel = PanelContainer.new()
	status_panel.name = "StatusPanel"
	status_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	status_panel.offset_left = 20
	status_panel.offset_top = 20
	status_panel.offset_right = 330
	status_panel.offset_bottom = 158
	_apply_panel_style(status_panel, Color("#35281fe8"))
	_apply_texture_panel(status_panel, "status", Vector4(160, 70, 160, 70))
	ui_root.add_child(status_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	status_panel.add_child(column)
	column.add_child(_label("月影边境", 18, Color("#f4d35e")))
	var date_time_panel := PanelContainer.new()
	date_time_panel.name = "DateTimePanel"
	_apply_panel_style(date_time_panel, Color("#211a16aa"))
	_apply_texture_panel(date_time_panel, "date_time", Vector4(180, 90, 180, 90))
	time_label = _label("", 16)
	date_time_panel.add_child(time_label)
	column.add_child(date_time_panel)
	weather_label = _label("天气：晴朗", 13, Color("#d8cbb2"))
	column.add_child(weather_label)
	var stamina_row := HBoxContainer.new()
	stamina_row.add_child(_label("体力", 13))
	stamina_bar = ProgressBar.new()
	stamina_bar.custom_minimum_size = Vector2(185, 18)
	stamina_bar.show_percentage = false
	var stamina_background := StyleBoxFlat.new()
	stamina_background.bg_color = Color("#211b18")
	stamina_background.border_color = Color("#80613b")
	stamina_background.set_border_width_all(2)
	stamina_background.set_corner_radius_all(6)
	var stamina_fill := StyleBoxFlat.new()
	stamina_fill.bg_color = Color("#8fbf3f")
	stamina_fill.border_color = Color("#d9e98b")
	stamina_fill.set_border_width_all(1)
	stamina_fill.set_corner_radius_all(5)
	stamina_bar.add_theme_stylebox_override("background", stamina_background)
	stamina_bar.add_theme_stylebox_override("fill", stamina_fill)
	stamina_row.add_child(stamina_bar)
	stamina_value = _label("100/100", 12)
	stamina_row.add_child(stamina_value)
	column.add_child(stamina_row)
	var gold_row := HBoxContainer.new()
	var gold_icon := TextureRect.new()
	gold_icon.texture = load(str(UI_TEXTURES["coin"])) as Texture2D
	gold_icon.custom_minimum_size = Vector2(24, 24)
	gold_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_row.add_child(gold_icon)
	gold_label = _label("金币：100", 14, Color("#f4d35e"))
	gold_row.add_child(gold_label)
	column.add_child(gold_row)

func _build_quest_panel() -> void:
	quest_panel = PanelContainer.new()
	quest_panel.name = "QuestPanel"
	quest_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	quest_panel.offset_left = -360
	quest_panel.offset_top = 20
	quest_panel.offset_right = -20
	quest_panel.offset_bottom = 116
	_apply_panel_style(quest_panel, Color("#30271fd9"))
	_apply_texture_panel(quest_panel, "quest_tracker", Vector4(150, 100, 150, 100))
	ui_root.add_child(quest_panel)
	var column := VBoxContainer.new()
	var title_row := HBoxContainer.new()
	title_row.add_child(_label("当前目标", 14, Color("#f4d35e")))
	quest_toggle_button = Button.new()
	quest_toggle_button.name = "QuestToggle"
	quest_toggle_button.text = "收起"
	quest_toggle_button.custom_minimum_size = Vector2(58, 26)
	quest_toggle_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	quest_toggle_button.pressed.connect(_toggle_quest_panel)
	_apply_button_style(quest_toggle_button)
	title_row.add_child(quest_toggle_button)
	column.add_child(title_row)
	objective_label = _label("", 13)
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size = Vector2(300, 38)
	column.add_child(objective_label)
	quest_panel.add_child(column)

func _toggle_quest_panel() -> void:
	quest_collapsed = not quest_collapsed
	objective_label.visible = not quest_collapsed
	if quest_toggle_button:
		quest_toggle_button.text = "展开" if quest_collapsed else "收起"
	quest_panel.offset_bottom = 64 if quest_collapsed else 116

func _build_hotbar() -> void:
	var bar_panel := PanelContainer.new()
	bar_panel.name = "HotbarPanel"
	bar_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	bar_panel.anchor_left = 0.5
	bar_panel.anchor_right = 0.5
	bar_panel.offset_left = -360
	bar_panel.offset_top = -104
	bar_panel.offset_right = 360
	bar_panel.offset_bottom = -14
	_apply_panel_style(bar_panel, Color("#30271fe8"))
	_apply_texture_panel(bar_panel, "quickbar", Vector4(180, 100, 180, 100))
	ui_root.add_child(bar_panel)
	hotbar = HBoxContainer.new()
	hotbar.name = "Hotbar"
	hotbar.add_theme_constant_override("separation", 6)
	bar_panel.add_child(hotbar)
	for index in range(8):
		var button := Button.new()
		button.name = "Slot_%d" % (index + 1)
		button.custom_minimum_size = Vector2(82, 72)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.icon = null
		button.text = ""
		button.pressed.connect(_select_slot.bind(index))
		_apply_texture_button(button, "quickbar_slot")
		hotbar_buttons.append(button)
		hotbar.add_child(button)
	_update_hotbar()

func _build_action_panel() -> void:
	action_panel = PanelContainer.new()
	action_panel.name = "ActionPanel"
	action_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	action_panel.offset_left = -320
	action_panel.offset_top = -145
	action_panel.offset_right = -20
	action_panel.offset_bottom = -20
	_apply_panel_style(action_panel, Color("#35281fe8"))
	_apply_texture_panel(action_panel, "interaction", Vector4(360, 180, 360, 180))
	ui_root.add_child(action_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	current_item_label = _label("", 16, Color("#f4d35e"))
	# The selected tool is already identified by the highlighted hotbar slot.
	# Context prompts should only describe the nearby target (bed, NPC, resource, etc.).
	current_item_label.visible = false
	column.add_child(current_item_label)
	interaction_label = _label("", 13)
	interaction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction_label.custom_minimum_size = Vector2(210, 30)
	column.add_child(interaction_label)
	message_label = _label("", 12, Color("#d8cbb2"))
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(210, 24)
	column.add_child(message_label)
	fishing_label = _label("", 12, Color("#b7d7dd"))
	fishing_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(fishing_label)
	action_panel.add_child(column)

func _build_inventory_panel() -> void:
	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.offset_left = -390
	inventory_panel.offset_top = -270
	inventory_panel.offset_right = 390
	inventory_panel.offset_bottom = 250
	_apply_panel_style(inventory_panel, Color("#39291efc"))
	_apply_texture_panel(inventory_panel, "inventory", Vector4(180, 160, 180, 160))
	inventory_panel.visible = false
	ui_root.add_child(inventory_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	var title_row := HBoxContainer.new()
	title_row.add_child(_label("物品栏", 20, Color("#f4d35e")))
	var close := Button.new()
	close.text = "关闭  Tab / I"
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(_toggle_inventory)
	_apply_button_style(close)
	_apply_texture_button(close, "button_close")
	title_row.add_child(close)
	column.add_child(title_row)
	inventory_category_bar = HBoxContainer.new()
	inventory_category_bar.add_theme_constant_override("separation", 4)
	column.add_child(inventory_category_bar)
	for category in ["全部"] + CATEGORY_ORDER:
		var category_button := Button.new()
		category_button.text = category
		category_button.custom_minimum_size = Vector2(72, 30)
		category_button.pressed.connect(_set_inventory_category.bind(category))
		_apply_button_style(category_button)
		inventory_category_bar.add_child(category_button)
	inventory_grid = GridContainer.new()
	inventory_grid.name = "ItemGrid"
	inventory_grid.columns = 7
	inventory_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(inventory_grid)
	var hint := _label("点击物品可放入快捷栏；悬停查看说明。", 12, Color("#bcae94"))
	column.add_child(hint)
	inventory_panel.add_child(column)

func _build_dialogue_panel() -> void:
	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "NPCDialoguePanel"
	dialogue_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	dialogue_panel.anchor_left = 0.5
	dialogue_panel.anchor_right = 0.5
	dialogue_panel.offset_left = -500
	dialogue_panel.offset_top = -210
	dialogue_panel.offset_right = 500
	dialogue_panel.offset_bottom = -28
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_panel_style(dialogue_panel, Color("#39291efc"))
	_apply_texture_panel(dialogue_panel, "dialogue", Vector4(360, 160, 360, 160))
	dialogue_panel.visible = false
	ui_root.add_child(dialogue_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	dialogue_portrait = TextureRect.new()
	dialogue_portrait.name = "Portrait"
	dialogue_portrait.custom_minimum_size = Vector2(132, 132)
	dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(dialogue_portrait)
	var text_column := VBoxContainer.new()
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dialogue_name_label = _label("", 20, Color("#f4d35e"))
	text_column.add_child(dialogue_name_label)
	dialogue_text_label = _label("", 17, Color("#f5ead2"))
	dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_column.add_child(dialogue_text_label)
	dialogue_hint_label = _label("按 E 或 Esc 关闭", 12, Color("#bcae94"))
	text_column.add_child(dialogue_hint_label)
	row.add_child(text_column)
	dialogue_panel.add_child(row)

func _build_debug_panel() -> void:
	debug_panel = PanelContainer.new()
	debug_panel.name = "DebugPanel"
	debug_panel.set_anchors_preset(Control.PRESET_CENTER)
	debug_panel.offset_left = -210
	debug_panel.offset_top = -170
	debug_panel.offset_right = 210
	debug_panel.offset_bottom = 170
	_apply_panel_style(debug_panel, Color("#3a2c25f5"))
	debug_panel.visible = false
	ui_root.add_child(debug_panel)
	var column := VBoxContainer.new()
	column.add_child(_label("开发调试", 18, Color("#f4d35e")))
	column.add_child(_label("仅开发模式可见 · F3 开关", 12, Color("#d8cbb2")))
	var pause := Button.new()
	pause.name = "PauseTime"
	pause.text = "暂停 / 继续时间"
	pause.pressed.connect(TimeManager.toggle_pause)
	_apply_button_style(pause)
	column.add_child(pause)
	var skip := Button.new()
	skip.name = "SkipDay"
	skip.text = "跳过一天"
	skip.pressed.connect(TimeManager.advance_day)
	_apply_button_style(skip)
	column.add_child(skip)
	var times := HBoxContainer.new()
	for hour in [8, 18, 22]:
		var time_button := Button.new()
		time_button.text = "%02d:00" % hour
		time_button.pressed.connect(TimeManager.set_debug_hour.bind(hour))
		_apply_button_style(time_button)
		times.add_child(time_button)
	column.add_child(times)
	var reset := Button.new()
	reset.name = "ResetTestData"
	reset.text = "重置测试数据"
	reset.pressed.connect(_reset_test_data)
	_apply_button_style(reset)
	column.add_child(reset)
	debug_status_label = _label("", 12, Color("#d8cbb2"))
	column.add_child(debug_status_label)
	debug_panel.add_child(column)

func _build_shop_panel() -> void:
	shop_panel = PanelContainer.new()
	shop_panel.name = "ShopPanel"
	shop_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	shop_panel.offset_left = -360
	shop_panel.offset_top = 110
	shop_panel.offset_right = -20
	shop_panel.offset_bottom = -20
	_apply_panel_style(shop_panel, Color("#35281ff5"))
	_apply_texture_panel(shop_panel, "shop", Vector4(180, 160, 180, 160))
	shop_panel.visible = false
	ui_root.add_child(shop_panel)
	var scroll := ScrollContainer.new()
	shop_panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)
	scroll.add_child(column)
	column.add_child(_label("边境商店", 18, Color("#f4d35e")))
	shop_gold_label = _label("", 13)
	column.add_child(shop_gold_label)
	column.add_child(_label("购买种子", 14, Color("#d8cbb2")))
	for item_id in SEED_IDS:
		var buy_button := Button.new()
		buy_button.text = "%s  ·  %d 金币" % [ItemCatalog.get_item_name(item_id), ItemCatalog.get_buy_price(item_id)]
		buy_button.pressed.connect(_buy_item.bind(item_id))
		_apply_button_style(buy_button)
		_apply_texture_button(buy_button, "button_buy")
		column.add_child(buy_button)
	column.add_child(_label("工具升级", 14, Color("#d8cbb2")))
	for tool_id in ["hoe", "axe", "pickaxe", "watering_can"]:
		var upgrade_button := Button.new()
		upgrade_button.name = "Upgrade_" + tool_id
		upgrade_button.pressed.connect(_upgrade_tool.bind(tool_id))
		_apply_button_style(upgrade_button)
		column.add_child(upgrade_button)
	var well_button := Button.new()
	well_button.text = "修复农场水井 · 80 金币"
	well_button.pressed.connect(_upgrade_well)
	_apply_button_style(well_button)
	column.add_child(well_button)
	column.add_child(_label("出售物品（每次 1 个）", 14, Color("#d8cbb2")))
	for item_id in ItemCatalog.ITEMS.keys():
		if ItemCatalog.get_sell_price(item_id) <= 0 or item_id.ends_with("_seed"):
			continue
		var sell_button := Button.new()
		sell_button.name = "Sell_" + item_id
		sell_button.text = "%s  ·  %d 金币" % [ItemCatalog.get_item_name(item_id), ItemCatalog.get_sell_price(item_id)]
		sell_button.pressed.connect(_sell_item.bind(item_id))
		_apply_button_style(sell_button)
		_apply_texture_button(sell_button, "button_sell")
		column.add_child(sell_button)
	shop_message_label = _label("", 12, Color("#d8cbb2"))
	shop_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(shop_message_label)
	var close_button := Button.new()
	close_button.text = "关闭商店（E）"
	close_button.pressed.connect(ShopManager.close)
	_apply_button_style(close_button)
	_apply_texture_button(close_button, "button_close")
	column.add_child(close_button)
	var save_row := HBoxContainer.new()
	for action in ["保存", "读取", "新游戏"]:
		var save_button := Button.new()
		save_button.text = action
		save_button.pressed.connect(_save_action.bind(action))
		_apply_button_style(save_button)
		_apply_texture_button(save_button, "button_back")
		save_row.add_child(save_button)
	column.add_child(save_row)
	var shop_upgrade := Button.new()
	shop_upgrade.text = "升级商店 · 150 金币"
	shop_upgrade.pressed.connect(_upgrade_shop)
	_apply_button_style(shop_upgrade)
	column.add_child(shop_upgrade)

func _process(_delta: float) -> void:
	_refresh_all()
	_update_interaction_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if dialogue_panel != null and dialogue_panel.visible and (event.keycode == KEY_E or event.keycode == KEY_ESCAPE):
			dialogue_panel.visible = false
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_F3 and development_mode:
			debug_panel.visible = not debug_panel.visible
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_TAB or event.keycode == KEY_I:
			_toggle_inventory()
			get_viewport().set_input_as_handled()
			return
		if event.keycode >= KEY_1 and event.keycode <= KEY_8:
			_select_slot(event.keycode - KEY_1)
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_E and _near_npc(_get_player()):
			var npc := _nearest_npc(_get_player())
			if npc:
				var player := _get_player()
				if player and player.has_method("_try_npc_interaction"):
					player.call("_try_npc_interaction")
				_show_dialogue(npc)
				get_viewport().set_input_as_handled()
				return
		if event.keycode == KEY_E and _near_tool_interaction():
			var player := _get_player()
			if player and player.has_method("_try_tool_action"):
				player.call("_try_tool_action")
				get_viewport().set_input_as_handled()

func _get_player() -> Node2D:
	return get_tree().current_scene.get_node_or_null("Player") if get_tree().current_scene else null

func _refresh_all() -> void:
	var player := _get_player()
	if player:
		if selected_slot < 5 and int(player.get("selected_tool_index")) != selected_slot:
			selected_slot = clampi(int(player.get("selected_tool_index")), 0, 4)
		stamina_bar.value = int(player.get("stamina"))
		stamina_bar.max_value = MAX_STAMINA
		stamina_value.text = "%d/%d" % [int(player.get("stamina")), MAX_STAMINA]
		var action_text := str(player.get("last_action_message"))
		if action_text.begins_with("1-5："):
			action_text = ""
		message_label.text = action_text
		if action_text != last_feedback_source:
			last_feedback_source = action_text
			if _is_failed_interaction(action_text):
				_show_context_feedback(action_text, player.global_position)
	gold_label.text = "金币：%d" % WorldManager.gold
	objective_label.text = QuestManager.get_objective_text()
	_update_current_item()
	_update_hotbar()
	_update_fishing_label()
	_update_shop_panel()

func _on_time_changed(day: int, _minutes: int, period: String) -> void:
	time_label.text = "第 %d 天  %s · %s" % [day, TimeManager.get_clock_text(), PERIOD_NAMES.get(period, period)]
	if TimeManager.time_paused:
		time_label.text += " · 已暂停"

func _on_quest_changed() -> void:
	if objective_label:
		objective_label.text = QuestManager.get_objective_text()

func _update_current_item() -> void:
	if selected_slot < 5:
		var tool: ToolData = TOOL_DEFINITIONS[selected_slot]
		current_item_label.text = tool.display_name
	else:
		var item_id: String = SEED_IDS[selected_slot - 5]
		current_item_label.text = ItemCatalog.get_item_name(item_id)

func _update_hotbar() -> void:
	if hotbar_buttons.is_empty():
		return
	for index in range(hotbar_buttons.size()):
		var button := hotbar_buttons[index]
		var item_id := ""
		var count := 0
		if index < 5:
			var tool: ToolData = TOOL_DEFINITIONS[index]
			item_id = tool.tool_id
			count = 1
		else:
			item_id = SEED_IDS[index - 5]
			count = int(WorldManager.inventory.get(item_id, 0))
		_build_slot_visual(button, item_id, Vector2(82, 72), false, count, index + 1)
		button.tooltip_text = _slot_tooltip(index)
		_apply_button_style(button, index == selected_slot)
		_apply_texture_button(button, "quickbar_slot", index == selected_slot)

func _slot_tooltip(index: int) -> String:
	if index < 5:
		return TOOL_DEFINITIONS[index].display_name
	var item_id: String = SEED_IDS[index - 5]
	return "%s\n数量：%d" % [ItemCatalog.get_item_name(item_id), int(WorldManager.inventory.get(item_id, 0))]

func _select_slot(index: int) -> void:
	selected_slot = clampi(index, 0, 7)
	var player := _get_player()
	if player == null:
		return
	if selected_slot < 5 and player.has_method("_select_tool"):
		player.call("_select_tool", selected_slot)
	else:
		var crop_index := selected_slot - 5
		if crop_index >= 0 and crop_index < 3:
			player.set("selected_crop_index", crop_index)
			player.set("last_action_message", "已选择种子：%s" % ItemCatalog.get_item_name(SEED_IDS[crop_index]))
	_update_current_item()
	_update_hotbar()

func _toggle_inventory() -> void:
	inventory_panel.visible = not inventory_panel.visible
	if inventory_panel.visible:
		_refresh_inventory()
		ShopManager.close()

func _set_inventory_category(category: String) -> void:
	inventory_category = category
	_refresh_inventory()

func _refresh_inventory() -> void:
	if inventory_grid == null:
		return
	for child in inventory_grid.get_children():
		child.queue_free()
	var items: Array[String] = []
	for item_id in ItemCatalog.ITEMS.keys():
		var count := int(WorldManager.inventory.get(item_id, 0))
		var category := str(ItemCatalog.get_info(item_id).get("category", "未知"))
		if count > 0 and (inventory_category == "全部" or inventory_category == category):
			items.append(str(item_id))
	if inventory_category == "全部" or inventory_category == "工具":
		for tool_id in TOOL_IDS:
			items.append(tool_id)
	for item_id in items:
		var item_button := Button.new()
		item_button.custom_minimum_size = Vector2(112, 108)
		item_button.icon = null
		item_button.text = ""
		var item_count := 1 if item_id in TOOL_IDS else int(WorldManager.inventory.get(item_id, 0))
		_build_slot_visual(item_button, item_id, Vector2(112, 108), true, item_count, -1)
		item_button.tooltip_text = _inventory_item_tooltip(item_id)
		item_button.pressed.connect(_assign_to_hotbar.bind(item_id))
		_apply_button_style(item_button, item_id == selected_item_id)
		_apply_texture_button(item_button, "inventory_slot", item_id == selected_item_id)
		inventory_grid.add_child(item_button)

func _build_slot_visual(button: Button, item_id: String, slot_size: Vector2, show_name: bool, count: int, hotkey: int) -> void:
	var old := button.get_node_or_null("SlotVisual")
	if old != null:
		old.queue_free()
	var visual := Control.new()
	visual.name = "SlotVisual"
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(visual)
	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _get_item_texture(item_id)
	icon.position = Vector2((slot_size.x - 52.0) * 0.5, 6.0)
	icon.size = Vector2(52, 52)
	visual.add_child(icon)
	if icon.texture == null:
		var fallback := _label(str(TOOL_ICONS.get(item_id, ITEM_ICONS.get(item_id, "?"))), 24, Color("#f4d35e"))
		fallback.position = Vector2((slot_size.x - 34.0) * 0.5, 14.0)
		fallback.size = Vector2(34, 34)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(fallback)
	if hotkey > 0:
		var key_label := _label(str(hotkey), 12, Color("#fff5d6"))
		key_label.position = Vector2(6, 4)
		key_label.size = Vector2(20, 18)
		key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		key_label.add_theme_color_override("font_outline_color", Color("#2b211b"))
		key_label.add_theme_constant_override("outline_size", 4)
		key_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(key_label)
	if show_name:
		var name := TOOL_DEFINITIONS[TOOL_IDS.find(item_id)].display_name if item_id in TOOL_IDS else ItemCatalog.get_item_name(item_id)
		var name_label := _label(name, 12, Color("#f5ead2"))
		name_label.position = Vector2(4, 62)
		name_label.size = Vector2(slot_size.x - 8, 22)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.clip_text = true
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		visual.add_child(name_label)
	var count_label := _label("x%d" % count, 12, Color("#fff5d6"))
	count_label.position = Vector2(slot_size.x - 38, slot_size.y - 22)
	count_label.size = Vector2(34, 18)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.add_theme_color_override("font_outline_color", Color("#2b211b"))
	count_label.add_theme_constant_override("outline_size", 4)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Tools are permanent equipment; only stackable items show a quantity in the hotbar.
	count_label.visible = not (item_id in TOOL_IDS and not show_name)
	visual.add_child(count_label)

func _inventory_item_text(item_id: String) -> String:
	var info := ItemCatalog.get_info(item_id)
	var count := int(WorldManager.inventory.get(item_id, 0))
	if item_id in TOOL_IDS:
		count = 1
	var display_name := TOOL_DEFINITIONS[TOOL_IDS.find(item_id)].display_name if item_id in TOOL_IDS else str(info.get("name", item_id))
	var icon_fallback: String = str(TOOL_ICONS.get(item_id, ITEM_ICONS.get(item_id, ""))) if _get_item_texture(item_id) == null else ""
	return "%s%s\nx%d" % [icon_fallback, display_name, count]

func _get_item_texture(item_id: String) -> Texture2D:
	var path := str(TOOL_TEXTURES.get(item_id, ITEM_TEXTURES.get(item_id, "")))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _inventory_item_tooltip(item_id: String) -> String:
	var info := ItemCatalog.get_info(item_id)
	var category := "工具" if item_id in TOOL_IDS else str(info.get("category", "未知"))
	var count := 1 if item_id in TOOL_IDS else int(WorldManager.inventory.get(item_id, 0))
	var display_name := TOOL_DEFINITIONS[TOOL_IDS.find(item_id)].display_name if item_id in TOOL_IDS else str(info.get("name", item_id))
	return "%s\n分类：%s\n数量：%d" % [display_name, category, count]

func _assign_to_hotbar(item_id: String) -> void:
	selected_item_id = item_id
	var slot := TOOL_IDS.find(item_id)
	if slot < 0:
		slot = SEED_IDS.find(item_id)
		if slot >= 0:
			slot += 5
	if slot >= 0:
		_select_slot(slot)
	_refresh_inventory()

func _update_interaction_prompt() -> void:
	var player := _get_player()
	if player == null:
		return
	var prompt := ""
	var anchor := player.global_position
	var region := str(get_tree().current_scene.get("region_name"))
	var has_prompt := false
	if _near_resource(player):
		var resource := _nearest_resource(player)
		if resource:
			var data: ResourceData = resource.get("resource_data")
			var tool_names := {"axe": "斧头", "pickaxe": "镐子", "hoe": "锄头", "fishing_rod": "鱼竿"}
			prompt = "按 E 采集%s · 需要%s（空格也可使用工具）" % [data.display_name, tool_names.get(data.required_tool_id, data.required_tool_id)]
			anchor = resource.global_position
			has_prompt = true
	elif _near_npc(player):
		prompt = "按 E 与 NPC 交互"
		anchor = _nearest_npc(player).global_position
		has_prompt = true
	elif region == "town" and player.global_position.distance_to(Vector2(275, 355)) < 170.0:
		prompt = "按 E 进入商店"
		anchor = Vector2(275, 355)
		has_prompt = true
	elif region == "farm" and player.global_position.distance_to(Vector2(245, 255)) < 130.0:
		prompt = "按 E 睡觉，进入下一天"
		anchor = Vector2(245, 255)
		has_prompt = true
	interaction_label.text = prompt
	if has_prompt or FishingManager.is_active():
		_position_action_panel(anchor)
	action_panel.visible = has_prompt or FishingManager.is_active()

func _is_failed_interaction(message: String) -> bool:
	if message.is_empty():
		return false
	if message.begins_with("已选择") or message.begins_with("使用") or message.begins_with("翻地成功") or message.begins_with("播种") or message.begins_with("浇水成功") or message.begins_with("收获") or message.begins_with("抛竿成功"):
		return false
	for token in ["没有", "不足", "无法", "需要", "请先", "已经用完", "不可用", "无法作用", "不是"]:
		if message.contains(token):
			return true
	return false

func _show_context_feedback(message: String, world_position: Vector2) -> void:
	if feedback_label == null:
		return
	feedback_label.text = message
	feedback_label.modulate = Color.WHITE
	feedback_label.visible = true
	var screen_position := get_viewport().get_canvas_transform() * world_position
	var viewport_size := get_viewport().get_visible_rect().size
	var x := clampf(screen_position.x - 150.0, 12.0, maxf(12.0, viewport_size.x - 372.0))
	var y := clampf(screen_position.y - 58.0, 12.0, maxf(12.0, viewport_size.y - 44.0))
	feedback_label.position = Vector2(x, y)
	if feedback_tween != null and feedback_tween.is_valid():
		feedback_tween.kill()
	feedback_tween = create_tween()
	feedback_tween.tween_interval(1.6)
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.35)
	feedback_tween.tween_callback(func(): feedback_label.visible = false)

func _position_action_panel(anchor: Vector2) -> void:
	if action_panel == null:
		return
	action_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var screen_position := get_viewport().get_canvas_transform() * anchor
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := Vector2(238, 78)
	var x := clampf(screen_position.x + 22.0, 12.0, maxf(12.0, viewport_size.x - panel_size.x - 12.0))
	var y := clampf(screen_position.y - panel_size.y - 18.0, 12.0, maxf(12.0, viewport_size.y - panel_size.y - 12.0))
	action_panel.offset_left = x
	action_panel.offset_top = y
	action_panel.offset_right = x + panel_size.x
	action_panel.offset_bottom = y + panel_size.y

func _near_tool_interaction() -> bool:
	var player := _get_player()
	if player == null:
		return false
	return _near_farm_plot(player) or _near_resource(player)

func _near_farm_plot(player: Node2D) -> bool:
	return _nearest_farm_plot(player) != null

func _nearest_farm_plot(player: Node2D) -> Node:
	var nearest: Node = null
	var nearest_distance := 100.0
	for plot in get_tree().get_nodes_in_group("farm_plots"):
		if not is_instance_valid(plot):
			continue
		var distance := player.global_position.distance_to(plot.global_position)
		if distance < nearest_distance:
			nearest = plot
			nearest_distance = distance
	return nearest

func _near_resource(player: Node2D) -> bool:
	return _nearest_resource(player) != null

func _nearest_resource(player: Node2D) -> Node:
	var nearest: Node = null
	var nearest_distance := 100.0
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if not is_instance_valid(node) or not bool(node.get("is_available")):
			continue
		var distance: float = player.global_position.distance_to(node.global_position)
		if distance < nearest_distance:
			nearest = node
			nearest_distance = distance
	return nearest

func _near_npc(player: Node2D) -> bool:
	return _nearest_npc(player) != null

func _nearest_npc(player: Node2D) -> Node:
	if player == null:
		return null
	var nearest: Node = null
	var nearest_distance := 65.0
	for npc in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(npc) or not npc.visible:
			continue
		var distance := player.global_position.distance_to(npc.global_position)
		if distance < nearest_distance:
			nearest = npc
			nearest_distance = distance
	return nearest

func _show_dialogue(npc: Node) -> void:
	if dialogue_panel == null or npc == null:
		return
	var npc_id := str(npc.npc_data.npc_id) if npc.get("npc_data") != null else ""
	dialogue_name_label.text = npc.get_display_name()
	dialogue_text_label.text = npc.get_dialogue()
	var portrait_path := str(NPC_PORTRAITS.get(npc_id, ""))
	dialogue_portrait.texture = load(portrait_path) as Texture2D if not portrait_path.is_empty() else null
	dialogue_panel.visible = true

func _update_fishing_label() -> void:
	if FishingManager.state == FishingManager.FishingState.IDLE:
		fishing_label.text = ""
	elif FishingManager.state == FishingManager.FishingState.WAITING:
		fishing_label.text = "钓鱼：等待咬钩"
	elif FishingManager.state == FishingManager.FishingState.HOOKED and FishingManager.selected_fish:
		var progress := int(FishingManager.catch_progress / FishingManager.selected_fish.required_catch_seconds * 100.0)
		fishing_label.text = "%s · 收线 %d%%" % [FishingManager.status_text, progress]
	else:
		fishing_label.text = "钓鱼：" + FishingManager.status_text

func _on_fishing_changed() -> void:
	_update_fishing_label()

func _update_shop_panel() -> void:
	if shop_panel == null:
		return
	shop_panel.visible = ShopManager.is_open
	if not ShopManager.is_open:
		return
	shop_gold_label.text = "金币：%d  · 今日收入：%d" % [WorldManager.gold, WorldManager.daily_income]
	for tool_id in ["hoe", "axe", "pickaxe", "watering_can"]:
		var button := shop_panel.find_child("Upgrade_" + tool_id, true, false) as Button
		if button:
			var tool_name: String = tool_id
			for tool_data in TOOL_DEFINITIONS:
				if tool_data.tool_id == tool_id:
					tool_name = tool_data.display_name
					break
			button.text = "升级%s · 等级 %d · 120 金币" % [tool_name, int(WorldManager.tool_levels.get(tool_id, 0))]

func _on_shop_changed() -> void:
	_update_shop_panel()

func _buy_item(item_id: String) -> void:
	var result := ShopManager.buy(item_id)
	shop_message_label.text = "购买成功：%s" % ItemCatalog.get_item_name(item_id) if result == "bought" else "金币不足或商品不可购买。"

func _sell_item(item_id: String) -> void:
	var result := ShopManager.sell(item_id)
	shop_message_label.text = "出售成功：%s" % ItemCatalog.get_item_name(item_id) if result == "sold" else "背包中没有可出售的该物品。"

func _upgrade_tool(tool_id: String) -> void:
	var result := WorldManager.upgrade_tool(tool_id)
	shop_message_label.text = "升级成功：%s" % ItemCatalog.get_item_name(tool_id) if result == "upgraded" else "金币不足或该工具已达到最高等级。"

func _upgrade_well() -> void:
	var result := WorldManager.upgrade_well()
	shop_message_label.text = "水井修复完成。" if result == "upgraded" else "金币不足或水井已经修复。"

func _upgrade_shop() -> void:
	var result := WorldManager.upgrade_shop()
	shop_message_label.text = "商店升级完成。" if result == "upgraded" else "金币不足或商店已经是最高等级。"

func _save_action(action: String) -> void:
	if action == "保存":
		SaveManager.save_game()
	elif action == "读取":
		SaveManager.load_game()
	else:
		SaveManager.new_game()

func _on_save_message(text: String) -> void:
	if shop_message_label:
		shop_message_label.text = text

func _reset_test_data() -> void:
	SaveManager.new_game()
	debug_status_label.text = "测试数据已重置。"
