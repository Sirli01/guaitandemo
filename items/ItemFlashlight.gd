class_name ItemFlashlight
extends Item

signal flashlight_toggled(is_on: bool)
signal flashlight_off

var battery_life: float = 0.0
var _is_on: bool = false

func _init() -> void:
	item_id = "flashlight"
	display_name = "手电筒"
	item_type = ItemType.SURVIVAL
	description = "照亮黑暗区域。照向怪物可吸引注意力但不触发对视。需要电池供电。"
	is_key_item = false

func use(_target: Node) -> void:
	if battery_life <= 0.0:
		print("[ItemFlashlight] 手电筒电量耗尽，请先装入电池")
		return
	_is_on = not _is_on
	flashlight_toggled.emit(_is_on)
	print("[ItemFlashlight] 手电筒已%s" % ("开启" if _is_on else "关闭"))

func add_battery(seconds: float) -> void:
	battery_life += seconds
	print("[ItemFlashlight] 装入电池，当前电量 %.0f 秒" % battery_life)

func drain(delta: float) -> void:
	if not _is_on:
		return
	battery_life -= delta
	if battery_life <= 0.0:
		battery_life = 0.0
		_is_on = false
		flashlight_off.emit()
		print("[ItemFlashlight] 电量耗尽，手电筒自动关闭")
