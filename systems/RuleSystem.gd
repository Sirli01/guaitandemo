extends Node

# SoulColor 枚举：记录实体当前灵魂颜色
enum SoulColor { GOLD, BROWN, NONE }

# === 数据结构 ===
var _soul_occupancy: Dictionary = {}
var _soul_original_body: Dictionary = {}
var _locked_souls: Array = []
var _period_swapped: Dictionary = {}
var _returned_this_morning: bool = false

# ============================================================
# 核心函数
# ============================================================

# 规则一：当前是否在禁对视时段（23:00 - 次日 07:00）
func is_forbidden_period() -> bool:
	return GameManager.is_forbidden_period

# 规则二 + 五：判断 entity_a 和 entity_b 是否满足互换条件
func can_swap(entity_a: Node, entity_b: Node) -> bool:
	if not is_instance_valid(entity_a) or not is_instance_valid(entity_b):
		return false
	if entity_a == entity_b:
		return false
	if _soul_occupancy.get(entity_a) == entity_b.name or _soul_occupancy.get(entity_b) == entity_a.name:
		return false
	if _period_swapped.get(entity_a, false) or _period_swapped.get(entity_b, false):
		return false
	return true

# 执行灵魂互换（规则一 + 五）
func do_swap(entity_a: Node, entity_b: Node) -> void:
	if not can_swap(entity_a, entity_b):
		return
	if is_forbidden_period():
		_period_swapped[entity_a] = true
		_period_swapped[entity_b] = true

	var soul_a: String = _soul_occupancy.get(entity_a, entity_a.name)
	var soul_b: String = _soul_occupancy.get(entity_b, entity_b.name)

	_soul_occupancy[entity_a] = soul_b
	_soul_occupancy[entity_b] = soul_a

	if not _soul_original_body.has(soul_a):
		_soul_original_body[soul_a] = entity_a
	if not _soul_original_body.has(soul_b):
		_soul_original_body[soul_b] = entity_b

	_check_morning_reset()

# 规则三：永久锁定灵魂（互换期间一方死亡时调用）
func lock_soul(entity: Node) -> void:
	var soul: String = _soul_occupancy.get(entity, entity.name)
	if not _locked_souls.has(soul):
		_locked_souls.append(soul)

# 规则六：07:00 强制换回所有灵魂
func force_return_all() -> void:
	for entity in _soul_occupancy.keys():
		var soul: String = _soul_occupancy[entity]
		if _locked_souls.has(soul):
			continue
		if _soul_original_body.has(soul):
			var original: Node = _soul_original_body[soul]
			_soul_occupancy[original] = soul
		_soul_occupancy[entity] = soul
	_period_swapped.clear()
	_returned_this_morning = true

# 规则四：获取实体当前灵魂颜色（瞳孔颜色跟随灵魂）
func get_soul_color(entity: Node) -> SoulColor:
	var soul: String = _soul_occupancy.get(entity, entity.name)
	match soul:
		var s when s.begins_with("Player"):
			return SoulColor.GOLD
		var s when s.begins_with("Monster"):
			return SoulColor.BROWN
		_:
			return SoulColor.NONE

# ============================================================
# 内部辅助
# ============================================================

func _check_morning_reset() -> void:
	var hour: int = GameManager.get_game_hour()
	if hour == 7 and not _returned_this_morning:
		force_return_all()

# ============================================================
# 规则解锁（供规则残页调用）
# ============================================================

func unlock_rule(rule_id: String) -> void:
	print("[RuleSystem] 规则已解锁: %s" % rule_id)
