extends Node

signal fishing_changed

enum FishingState { IDLE, WAITING, HOOKED, RESULT }
const FISH: Array[FishData] = [
	preload("res://resources/data/fish/river_trout.tres"),
	preload("res://resources/data/fish/silver_scale_fish.tres"),
	preload("res://resources/data/fish/moonlight_fish.tres"),
]

var state := FishingState.IDLE
var selected_fish: FishData
var status_text := ""
var bar_position := 0.5
var fish_position := 0.5
var catch_progress := 0.0
var elapsed := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func _process(delta: float) -> void:
	if state != FishingState.HOOKED or selected_fish == null:
		return
	elapsed += delta
	bar_position += (-0.72 if Input.is_key_pressed(KEY_SPACE) else 0.58) * delta
	bar_position = clampf(bar_position, 0.0, 1.0)
	fish_position = 0.5 + sin(elapsed * 3.2 * selected_fish.difficulty) * 0.36
	if absf(bar_position - fish_position) <= 0.18:
		catch_progress += delta
	else:
		catch_progress = maxf(0.0, catch_progress - delta * 0.45)
	if catch_progress >= selected_fish.required_catch_seconds:
		_finish(true)
	elif elapsed >= 9.0:
		_finish(false)
	fishing_changed.emit()

func start_fishing() -> bool:
	if state != FishingState.IDLE:
		return false
	selected_fish = _choose_fish()
	if selected_fish == null:
		status_text = "当前时间没有鱼咬钩。"
		state = FishingState.RESULT
		TimeManager.advance_minutes(10)
		_reset_after_delay()
		return true
	state = FishingState.WAITING
	status_text = "已抛竿，等待鱼咬钩……"
	fishing_changed.emit()
	_wait_for_bite()
	return true

func _wait_for_bite() -> void:
	await get_tree().create_timer(_rng.randf_range(1.2, 2.8)).timeout
	if state != FishingState.WAITING:
		return
	state = FishingState.HOOKED
	bar_position = 0.5
	catch_progress = 0.0
	elapsed = 0.0
	status_text = "%s咬钩！按住空格抬升控制条。" % selected_fish.display_name
	fishing_changed.emit()

func _finish(success: bool) -> void:
	state = FishingState.RESULT
	if success:
		WorldManager.add_item(selected_fish.fish_id)
		var player := get_tree().current_scene.get_node_or_null("Player")
		if player:
			WorldManager.notify_item_collected(selected_fish.fish_id, player.global_position)
		status_text = "钓到了%s！" % selected_fish.display_name
	else:
		status_text = "%s挣脱了。" % selected_fish.display_name
	TimeManager.advance_minutes(20)
	fishing_changed.emit()
	_reset_after_delay()

func _reset_after_delay() -> void:
	await get_tree().create_timer(1.8).timeout
	state = FishingState.IDLE
	selected_fish = null
	status_text = ""
	fishing_changed.emit()

func _choose_fish() -> FishData:
	var candidates: Array[FishData] = []
	var total_weight := 0.0
	for fish in FISH:
		if TimeManager.get_period() in fish.allowed_periods:
			candidates.append(fish)
			total_weight += fish.appearance_weight
	if candidates.is_empty():
		return null
	var roll := _rng.randf_range(0.0, total_weight)
	var running := 0.0
	for fish in candidates:
		running += fish.appearance_weight
		if roll <= running:
			return fish
	return candidates.back()

func is_active() -> bool:
	return state == FishingState.WAITING or state == FishingState.HOOKED
