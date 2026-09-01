extends Node

signal time_changed(day: int, minutes: int, period: String)
signal day_started(day: int)

const GAME_MINUTES_PER_REAL_SECOND := 4.0
const MINUTES_PER_DAY := 1440
const MORNING_START := 6 * 60

var day := 1
var minutes := MORNING_START
var time_paused := false
var _minute_accumulator := 0.0

func _process(delta: float) -> void:
	if time_paused:
		return
	_minute_accumulator += delta * GAME_MINUTES_PER_REAL_SECOND
	if _minute_accumulator >= 1.0:
		var elapsed_minutes: int = int(_minute_accumulator)
		_minute_accumulator -= elapsed_minutes
		_advance_minutes(elapsed_minutes)

func _advance_minutes(amount: int) -> void:
	minutes += amount
	while minutes >= MINUTES_PER_DAY:
		minutes -= MINUTES_PER_DAY
		_start_next_day()
	time_changed.emit(day, minutes, get_period())

func _start_next_day() -> void:
	day += 1
	minutes = MORNING_START
	day_started.emit(day)

func advance_day() -> void:
	_start_next_day()
	time_changed.emit(day, minutes, get_period())

func advance_minutes(amount: int) -> void:
	_advance_minutes(amount)

func set_debug_hour(hour: int) -> void:
	minutes = clampi(hour, 0, 23) * 60
	time_changed.emit(day, minutes, get_period())

func toggle_pause() -> void:
	time_paused = not time_paused
	time_changed.emit(day, minutes, get_period())

func get_period() -> String:
	if minutes >= 6 * 60 and minutes < 9 * 60:
		return "morning"
	if minutes >= 9 * 60 and minutes < 17 * 60:
		return "day"
	if minutes >= 17 * 60 and minutes < 20 * 60:
		return "dusk"
	return "night"

func get_clock_text() -> String:
	return "%02d:%02d" % [minutes / 60, minutes % 60]

func get_ambient_tint() -> Color:
	return {"morning": Color(1.0, 0.88, 0.68, 0.10), "day": Color(1, 1, 1, 0.0), "dusk": Color(0.95, 0.50, 0.28, 0.22), "night": Color(0.12, 0.16, 0.34, 0.42)}.get(get_period(), Color.WHITE)
