extends Node

signal time_updated(time_string: String, is_forbidden: bool)

# 1现实秒 = 1游戏分钟，1现实分钟 = 1游戏小时
# 游戏从20:00开始，给玩家3小时到达23:00禁时段
const START_HOUR: int = 20
const START_MINUTE: int = 0

var _elapsed_game_seconds: float = 0.0  # 用于累积时间的秒数
var _elapsed_game_minutes: int = START_HOUR * 60 + START_MINUTE  # 初始1200分钟

var time_string: String = "20:00"
var is_forbidden: bool = false

func _process(delta: float) -> void:
	# 1现实秒 = 1游戏分钟：累积现实秒数，每累满1秒增加1游戏分钟
	_elapsed_game_seconds += delta
	if _elapsed_game_seconds >= 1.0:
		var minutes_to_add: int = int(_elapsed_game_seconds)
		_elapsed_game_minutes += minutes_to_add
		_elapsed_game_seconds -= float(minutes_to_add)
		_update_time()

func _update_time() -> void:
	var total_minutes: int = _elapsed_game_minutes
	var hours: int = (total_minutes / 60) % 24
	var minutes: int = total_minutes % 60
	time_string = "%02d:%02d" % [hours, minutes]

	var prev_forbidden: bool = is_forbidden
	is_forbidden = (hours >= 23 or hours < 7)

	time_updated.emit(time_string, is_forbidden)

	if not prev_forbidden and is_forbidden:
		print("[TimeSystem] 禁时段开始: 23:00")
	elif prev_forbidden and not is_forbidden:
		print("[TimeSystem] 禁时段结束: 07:00")

func get_time_string() -> String:
	return time_string

func is_forbidden_time() -> bool:
	return is_forbidden
