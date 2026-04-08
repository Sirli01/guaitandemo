extends Node

# ============================================================
# 信号定义
# ============================================================
signal safe_zone_entered(zone_name: String)
signal safe_zone_exited(zone_name: String)

# ============================================================
# 当前状态
# ============================================================
var _current_safe_zone: String = ""
var is_in_safe_zone: bool = false
var _registered_zones: Array[Node] = []

func _ready() -> void:
	print("[SafeZoneSystem] 就绪")

# ============================================================
# 外部接口：进入 / 离开安全区（由 Area2D 区域调用）
# ============================================================

func enter_safe_zone(zone_name: String) -> void:
	if is_in_safe_zone and _current_safe_zone == zone_name:
		return
	_current_safe_zone = zone_name
	is_in_safe_zone = true
	safe_zone_entered.emit(zone_name)
	_apply_player_safe_status(true)
	print("[SafeZoneSystem] 进入安全区: %s" % zone_name)

func exit_safe_zone(zone_name: String) -> void:
	if not is_in_safe_zone:
		return
	if _current_safe_zone != zone_name:
		return
	_current_safe_zone = ""
	is_in_safe_zone = false
	safe_zone_exited.emit(zone_name)
	_apply_player_safe_status(false)
	print("[SafeZoneSystem] 离开安全区: %s" % zone_name)

# ============================================================
# 玩家安全状态应用
# ============================================================

func _apply_player_safe_status(in_safe: bool) -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_property("is_in_safe_room"):
			p.is_in_safe_room = in_safe

# ============================================================
# 查询
# ============================================================

func get_current_zone() -> String:
	return _current_safe_zone

func is_player_in_safe_zone() -> bool:
	return is_in_safe_zone
