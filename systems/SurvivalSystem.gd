extends Node

# ============================================================
# 信号定义
# ============================================================
signal stamina_updated(current: float, maximum: float)
signal satiety_updated(current: float)
signal stamina_exhausted()
signal satiety_critical()
signal danger_zone_changed(in_danger: bool)

# ============================================================
# 体力（ stamina ）
# ============================================================
var stamina: float = 100.0
var stamina_max: float = 100.0

# ============================================================
# 饱食度（ satiety ）
# ============================================================
var satiety: float = 100.0
const SATIETY_MAX: float = 100.0

# ============================================================
# 危险区域标志
# ============================================================
var _in_danger_zone: bool = false

# ============================================================
# 内部状态
# ============================================================
var _player: Node = null

# ============================================================
# 常量
# ============================================================
# 饱食度每游戏分钟自然消耗 2%
const SATIETY_DRAIN_PER_MINUTE: float = 2.0
# 危险区域或跑步时消耗翻倍
const SATIETY_DRAIN_MULTIPLIER_DANGER: float = 2.0
const SATIETY_DRAIN_MULTIPLIER_RUNNING: float = 2.0

# 体力恢复速度（静止时每秒恢复）
const STAMINA_RESTORE_RATE: float = 10.0
# 安全区内体力恢复速度 x2
const STAMINA_RESTORE_RATE_SAFE: float = 20.0

# 饱食度决定体力上限：饱食度50% → 体力上限50
const STAMINA_CAP_SATIETY_FACTOR: float = 1.0

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	print("[SurvivalSystem] 就绪 | 体力:%.1f 饱食度:%.1f" % [stamina, satiety])

func _process(delta: float) -> void:
	_update_stamina_cap()
	_update_stamina_recovery(delta)
	_update_satiety_drain(delta)

# ============================================================
# 体力上限由饱食度决定
# ============================================================

func _update_stamina_cap() -> void:
	var new_max: float = max(satiety * STAMINA_CAP_SATIETY_FACTOR, 10.0)
	if new_max != stamina_max:
		stamina_max = new_max
		stamina = min(stamina, stamina_max)
		stamina_updated.emit(stamina, stamina_max)

# ============================================================
# 体力恢复（静止时）
# ============================================================

func _update_stamina_recovery(delta: float) -> void:
	# 只有在非危险区域才恢复
	if not _in_danger_zone:
		var rate: float = STAMINA_RESTORE_RATE_SAFE if SafeZoneSystem.is_player_in_safe_zone() else STAMINA_RESTORE_RATE
		var prev: float = stamina
		stamina = min(stamina + rate * delta, stamina_max)
		if stamina != prev:
			stamina_updated.emit(stamina, stamina_max)
			if stamina >= stamina_max:
				stamina_updated.emit(stamina, stamina_max)

# ============================================================
# 饱食度消耗（每游戏分钟 2%，用 TimeSystem 驱动）
# ============================================================

func _update_satiety_drain(delta: float) -> void:
	# 1现实秒 = 1游戏分钟，所以每帧 delta 秒 = delta 游戏分钟
	var drain: float = SATIETY_DRAIN_PER_MINUTE * delta

	# 危险区域消耗翻倍
	if _in_danger_zone:
		drain *= SATIETY_DRAIN_MULTIPLIER_DANGER

	# 跑步时（通过 Player 状态检测）
	if _player != null and _player.has_method("is_running"):
		if _player.is_running():
			drain *= SATIETY_DRAIN_MULTIPLIER_RUNNING

	var prev: float = satiety
	satiety = max(satiety - drain, 0.0)
	if satiety != prev:
		satiety_updated.emit(satiety)

		if satiety < 20.0 and prev >= 20.0:
			satiety_critical.emit()
			print("[SurvivalSystem] 饱食度过低！")

		if satiety <= 0.0:
			_trigger_starvation()

# ============================================================
# 外部接口：危险区域
# ============================================================

func set_danger_zone(in_danger: bool) -> void:
	if _in_danger_zone == in_danger:
		return
	_in_danger_zone = in_danger
	danger_zone_changed.emit(in_danger)
	print("[SurvivalSystem] 危险区域: %s" % ("进入" if in_danger else "离开"))

func is_in_danger_zone() -> bool:
	return _in_danger_zone

# ============================================================
# 外部接口：体力消耗/恢复
# ============================================================

func consume_stamina(amount: float) -> void:
	if amount <= 0:
		return
	var prev: float = stamina
	stamina = max(stamina - amount, 0.0)
	stamina_updated.emit(stamina, stamina_max)
	if stamina <= 0.0 and prev > 0.0:
		stamina_exhausted.emit()
		print("[SurvivalSystem] 体力耗尽！")

func restore_stamina(amount: float) -> void:
	if amount <= 0:
		return
	var prev: float = stamina
	stamina = min(stamina + amount, stamina_max)
	if stamina != prev:
		stamina_updated.emit(stamina, stamina_max)

# ============================================================
# 外部接口：饱食度（道具恢复）
# ============================================================

func add_satiety(amount: float) -> void:
	if amount <= 0:
		return
	var prev: float = satiety
	satiety = min(satiety + amount, SATIETY_MAX)
	if satiety != prev:
		satiety_updated.emit(satiety)
		print("[SurvivalSystem] 饱食度恢复: %.1f → %.1f" % [prev, satiety])

# ============================================================
# 饥饿致死
# ============================================================

func _trigger_starvation() -> void:
	print("[SurvivalSystem] 饱食度归零，饥饿致死！")
	if _player != null and _player.has_signal("game_over_starvation"):
		_player.game_over_starvation.emit()

# ============================================================
# 查询接口（供 HUD 等外部系统调用）
# ============================================================

func get_stamina() -> float:
	return stamina

func get_stamina_max() -> float:
	return stamina_max

func get_satiety() -> float:
	return satiety

func is_starving() -> bool:
	return satiety <= 0.0
