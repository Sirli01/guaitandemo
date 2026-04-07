extends Node

signal forbidden_period_start
signal forbidden_period_end
signal key_item_acquired(item_id: String)
signal game_over_triggered(reason: String)
signal route_unlocked(route: String)
signal lore_read(item_id: String, content: String)
signal floor_transition_completed(new_floor: int)
signal objective_updated(objective: String)

# ============================================================
# 虚拟游戏时钟（基于 _process 累加，不依赖现实时间）
# ============================================================
var game_time_string: String = "21:00"
var current_objective: String = ""
var is_forbidden_period: bool = false
var _elapsed_seconds: float = 75600.0  # 21:00（给玩家2小时准备时间）
var _night_fall_triggered: bool = false

# ============================================================
# 收集进度追踪
# ============================================================
var collected_rule_pages: Array[String] = []
var collected_lore_items: Array[String] = []

const RULE_PAGE_COUNT: int = 6
const LORE_ITEM_COUNT: int = 5

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_connect_item_system_signals()
	print("[GameManager] 就绪，虚拟时钟已启动")

func _process(delta: float) -> void:
	_elapsed_seconds += delta * 60.0  # 现实1秒=游戏1分钟
	_update_game_time()
	_check_forbidden_period()

# ============================================================
# 虚拟时钟逻辑
# ============================================================

func _update_game_time() -> void:
	var total_minutes: int = int(_elapsed_seconds / 60.0)
	var hours: int = int(total_minutes / 60.0) % 24
	var minutes: int = total_minutes % 60
	game_time_string = "%02d:%02d" % [hours, minutes]

func _check_forbidden_period() -> void:
	var hours: int = int(_elapsed_seconds / 3600.0) % 24
	var was_forbidden: bool = is_forbidden_period

	if hours >= 23 or hours < 7:
		is_forbidden_period = true
		if not was_forbidden:
			forbidden_period_start.emit()
			_night_fall_triggered = true
			print("[GameManager] 禁对视时段开始 (23:00-07:00)")
	else:
		if was_forbidden and not is_forbidden_period:
			forbidden_period_end.emit()
			_night_fall_triggered = false
			print("[GameManager] 禁对视时段结束")

# ============================================================
# 外部查询接口（供 RuleSystem / HUD / FloorController 调用）
# ============================================================

func get_game_hour() -> int:
	return int(_elapsed_seconds / 3600.0) % 24

func get_elapsed_seconds() -> float:
	return _elapsed_seconds

# ============================================================
# 道具收集追踪
# ============================================================

func _connect_item_system_signals() -> void:
	ItemSystem.key_item_acquired.connect(_on_key_item_acquired)

func _on_key_item_acquired(item_id: String) -> void:
	key_item_acquired.emit(item_id)

	if item_id.begins_with("rule_page"):
		if not collected_rule_pages.has(item_id):
			collected_rule_pages.append(item_id)
			print("[GameManager] 规则残页已收集: %d/%d" % [collected_rule_pages.size(), RULE_PAGE_COUNT])
	elif item_id in ["diary_page", "ayou_id_card", "childhood_photo", "resident_note", "sister_phone"]:
		if not collected_lore_items.has(item_id):
			collected_lore_items.append(item_id)
			print("[GameManager] 剧情道具已收集: %d/%d" % [collected_lore_items.size(), LORE_ITEM_COUNT])

# ============================================================
# 结局判断
# ============================================================

func check_ending() -> String:
	if collected_rule_pages.size() >= RULE_PAGE_COUNT and collected_lore_items.size() >= LORE_ITEM_COUNT:
		return "hidden_ending"
	return "default_ending"

# ============================================================
# 结局触发
# ============================================================

func trigger_game_over(reason: String) -> void:
	game_over_triggered.emit(reason)
	get_tree().paused = true
	print("[GameManager] 游戏结束，原因: %s" % reason)

func on_swap_triggered(monster: Node, player: Node) -> void:
	print("[GameManager] 灵魂互换已触发: %s <-> %s" % [monster.name, player.name])

func on_night_fall() -> void:
	_night_fall_triggered = true
	print("[GameManager] 夜间事件已触发")

func on_morning_come() -> void:
	_night_fall_triggered = false
	print("[GameManager] 清晨已到，夜间状态重置")

func on_monster_bound(monster: Node) -> void:
	print("[GameManager] 怪物已被绑定: %s" % monster.name)

func on_monster_killed(monster: Node) -> void:
	print("[GameManager] 怪物已击杀: %s" % monster.name)

func on_key_item_collected(item_id: String) -> void:
	print("[GameManager] 关键道具获取: %s" % item_id)

func on_route_unlocked(route: String) -> void:
	route_unlocked.emit(route)
	print("[GameManager] 路线解锁: %s" % route)

func on_reached_window() -> void:
	print("[GameManager] 已到达窗户位置")

func update_objective(text: String) -> void:
	current_objective = text
	objective_updated.emit(text)
	print("[GameManager] 目标更新: %s" % text)

func on_lore_read(item_id: String, content: String) -> void:
	lore_read.emit(item_id, content)
	if not collected_lore_items.has(item_id):
		collected_lore_items.append(item_id)
		print("[GameManager] 剧情道具已收集: %d/%d" % [collected_lore_items.size(), LORE_ITEM_COUNT])

func on_lore_item_collected_late(item_id: String) -> void:
	if not collected_lore_items.has(item_id):
		collected_lore_items.append(item_id)
		print("[GameManager] 剧情道具已收集: %d/%d" % [collected_lore_items.size(), LORE_ITEM_COUNT])

# ============================================================
# 楼层切换逻辑
# ============================================================

func on_floor_transition(current_floor: int, target_floor: int) -> void:
	print("[GameManager] 楼层切换请求: %d 楼 → %d 楼" % [current_floor, target_floor])
	var scene_path: String = ""
	match target_floor:
		1:
			scene_path = "res://levels/Level1Controller.tscn"
		2:
			scene_path = "res://levels/Level2Controller.tscn"
		3:
			scene_path = "res://levels/Level3Controller.tscn"
		_:
			push_error("[GameManager] 未知楼层: %d" % target_floor)
			return
	_fade_and_switch_scene(scene_path, target_floor)

func _fade_and_switch_scene(scene_path: String, new_floor: int) -> void:
	get_tree().paused = true
	print("[GameManager] 场景淡出切换至: %s" % scene_path)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(scene_path)
	floor_transition_completed.emit(new_floor)
	get_tree().paused = false
	print("[GameManager] 楼层切换完成: %d 楼" % new_floor)
