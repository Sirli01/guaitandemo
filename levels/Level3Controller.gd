extends Node2D
class_name Level3Controller

# ============================================================
# 反杀流程状态枚举
# ============================================================
enum CounterState {
	IDLE,           # 初始，等待触发
	MONSTER_BOUND,  # 怪物已被麻绳绑定
	SWAPPED,        # 玩家与怪物已完成灵魂互换
	CONTROLLING_MONSTER, # 操控怪物移动到窗边
	WINDOW_BROKEN,  # 窗户已砸破
	DROP_TRIGGERED, # 怪物灵魂跳窗，身体坠落
	TRAPPED,        # 智斗路线失败，玩家被困
}

# ============================================================
# 信号
# ============================================================
signal counter_state_changed(new_state: CounterState)
signal entered_safe_room(room_name: String)
signal game_over_triggered(reason: String)

# ============================================================
# 导出变量
# ============================================================
@export var monsters_patrol: Array[NodePath] = []
@export var monster_bound_zone_path: NodePath = ^"BindZone"
@export var break_window_zone_path: NodePath = ^"BreakWindowZone"
@export var windows_group_path: NodePath = ^"Windows"
@export var drop_zone_path: NodePath = ^"DropZone"

# ============================================================
# 状态
# ============================================================
var _counter_state: CounterState = CounterState.IDLE
var _player: Node = null
var _controlled_monster: Node = null
var _bound_monster: Node = null
var _current_window: Node = null
var _elevator_cards_collected: int = 0
const ELEVATOR_CARDS_REQUIRED: int = 3

var _smart_route_available: bool = false

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_setup_zones()
	_setup_monsters()
	_setup_windows()
	_check_smart_route()
	print("[Level3Controller] Level3 就绪，智斗路线可用: %s" % _smart_route_available)

func _check_smart_route() -> void:
	var has_rope: bool = ItemSystem.has_item("rope")
	var has_axe: bool = ItemSystem.has_item("fire_axe")
	_smart_route_available = has_rope and has_axe
	if _smart_route_available:
		_show_route_hint("智斗路线")
		GameManager.on_route_unlocked("smart_route")
	else:
		_show_route_hint("潜行路线")
		GameManager.on_route_unlocked("stealth_route")

func _show_route_hint(route: String) -> void:
	print("[Level3Controller] 路线已锁定: %s" % route)

# ============================================================
# 区域检测
# ============================================================

func _setup_zones() -> void:
	var bind_zone: Area2D = get_node(monster_bound_zone_path)
	var break_zone: Area2D = get_node(break_window_zone_path)
	var drop_zone: Area2D = get_node(drop_zone_path)

	bind_zone.body_entered.connect(_on_bind_zone_entered)
	break_zone.body_entered.connect(_on_break_window_zone_entered)
	drop_zone.body_entered.connect(_on_drop_zone_entered)

func _on_bind_zone_entered(body: Node) -> void:
	if body != _player:
		return
	if not _smart_route_available:
		return
	if not ItemSystem.has_item("rope"):
		return
	print("[Level3Controller] 进入绑定区域，可对怪物使用麻绳")

func _on_break_window_zone_entered(body: Node) -> void:
	if body != _player:
		return
	if _counter_state == CounterState.CONTROLLING_MONSTER:
		print("[Level3Controller] 已操控怪物到达窗户，可使用消防斧砸窗")
		GameManager.on_reached_window()

func _on_drop_zone_entered(body: Node) -> void:
	if body != _controlled_monster:
		return
	if _counter_state != CounterState.CONTROLLING_MONSTER:
		return
	print("[Level3Controller] 怪物灵魂跳窗，身体坠落")
	_trigger_drop()

# ============================================================
# 怪物信号
# ============================================================

func _setup_monsters() -> void:
	for path: NodePath in monsters_patrol:
		var monster: Node = get_node(path)
		if monster.has_signal("eye_contact"):
			monster.eye_contact.connect(_on_monster_eye_contact.bind(monster))
		if monster.has_signal("monster_bound"):
			monster.monster_bound.connect(_on_monster_bound.bind(monster))

func _on_monster_eye_contact(monster: Node, player: Node) -> void:
	# 如果怪物已被绑定，对视触发互换
	if _counter_state == CounterState.MONSTER_BOUND and monster == _bound_monster:
		_trigger_swap(monster, player)
	elif _counter_state == CounterState.IDLE:
		# 正常对视，但无法互换 → 触发危险
		if not RuleSystem.can_swap(monster, player):
			_trigger_trapped()
		else:
			_trigger_swap(monster, player)

func _on_monster_bound(monster: Node) -> void:
	_bound_monster = monster
	_set_counter_state(CounterState.MONSTER_BOUND)
	print("[Level3Controller] 怪物 %s 已被绑定，进入绑定状态" % monster.name)

# ============================================================
# 反杀流程状态机
# ============================================================

func _set_counter_state(new_state: CounterState) -> void:
	var old_state: CounterState = _counter_state
	_counter_state = new_state
	counter_state_changed.emit(new_state)
	print("[Level3Controller] 反杀状态: %s → %s" % [CounterState.keys()[old_state], CounterState.keys()[new_state]])

# ---- 步骤1：绑定怪物 ----
func attempt_bind_monster(monster: Node) -> bool:
	if not _smart_route_available:
		print("[Level3Controller] 缺少麻绳或斧头，无法智斗")
		return false
	if _counter_state != CounterState.IDLE:
		print("[Level3Controller] 当前状态不允许绑定操作")
		return false
	if monster.is_bound:
		print("[Level3Controller] 目标已被绑定")
		return false

	monster.bind_with_rope()
	_bound_monster = monster
	_set_counter_state(CounterState.MONSTER_BOUND)
	return true

# ---- 步骤2：灵魂互换 ----
func _trigger_swap(monster: Node, player: Node) -> void:
	if not RuleSystem.can_swap(monster, player):
		print("[Level3Controller] 不满足互换条件")
		_trigger_trapped()
		return

	RuleSystem.do_swap(monster, player)
	_controlled_monster = monster
	_set_counter_state(CounterState.SWAPPED)

	# 切换玩家操控到怪物身体
	_switch_control_to_monster(monster)
	_set_counter_state(CounterState.CONTROLLING_MONSTER)
	print("[Level3Controller] 灵魂互换完成，玩家操控怪物身体")

# ---- 步骤3：操控怪物走到窗边 ----
func _switch_control_to_monster(monster: Node) -> void:
	# 禁用玩家身体输入
	if _player != null:
		_player.set_process_input(false)
		_player.set_physics_process(false)

	# 启用怪物输入（怪物身体现在由玩家灵魂控制）
	monster.set_process_input(true)
	_controlled_monster = monster

	# 通知 FloorController 切换视野
	var fc: Node = get_parent().get_node_or_null("FloorController")
	if fc and fc.has_method("switch_control_to"):
		fc.switch_control_to(monster)

	print("[Level3Controller] 操控权切换到怪物身体")

# ---- 步骤4：砸窗 ----
func attempt_break_window(window: Node) -> bool:
	if _counter_state != CounterState.CONTROLLING_MONSTER:
		return false
	if not ItemSystem.has_item("fire_axe"):
		print("[Level3Controller] 缺少消防斧")
		return false

	if window.has_method("smash"):
		window.smash()
	_current_window = window
	_set_counter_state(CounterState.WINDOW_BROKEN)
	print("[Level3Controller] 窗户已砸破")
	return true

# ---- 步骤5：跳窗坠落 ----
func _trigger_drop() -> void:
	_set_counter_state(CounterState.DROP_TRIGGERED)

	# 怪物身体（现在由玩家灵魂控制）跳窗
	_controlled_monster.set_physics_process(false)
	if _controlled_monster.has_method("apply_drop"):
		_controlled_monster.apply_drop()

	# 锁定怪物灵魂（规则三：互换期间一方死亡，灵魂永久锁定）
	RuleSystem.lock_soul(_controlled_monster)

	# 触发过场，等待 07:00
	_show_drop_cutscene()

func _show_drop_cutscene() -> void:
	print("[Level3Controller] 显示坠楼过场动画（预留）")
	# 过场动画播放完毕后调用 _on_drop_cutscene_finished

func _on_drop_cutscene_finished() -> void:
	# 07:00 自动强制换回，怪物灵魂因身体消亡而被永久锁定
	_wait_for_morning()

func _wait_for_morning() -> void:
	print("[Level3Controller] 等待 07:00 强制换回...")
	# 由 FloorController 的 _on_morning_come() 处理

# ============================================================
# 失败路径：被困
# ============================================================

func _trigger_trapped() -> void:
	_set_counter_state(CounterState.TRAPPED)
	GameManager.trigger_game_over("smart_route_failed")
	print("[Level3Controller] 智斗路线失败，玩家被困")

# ============================================================
# 状态查询（供 UI 调用）
# ============================================================

func get_counter_state() -> CounterState:
	return _counter_state

func is_smart_route() -> bool:
	return _smart_route_available

func get_current_hint() -> String:
	match _counter_state:
		CounterState.IDLE:
			return "持有麻绳时对怪物使用，可绑定怪物" if _smart_route_available else "寻找麻绳和斧头"
		CounterState.MONSTER_BOUND:
			return "怪物已绑定！请在对视触发灵魂互换"
		CounterState.SWAPPED:
			return "互换成功！操控怪物移动到窗户"
		CounterState.CONTROLLING_MONSTER:
			return "操控怪物到达窗户后，使用消防斧砸窗"
		CounterState.WINDOW_BROKEN:
			return "窗户已破！引导怪物跳窗"
		CounterState.DROP_TRIGGERED:
			return "等待 07:00 强制换回..."
		CounterState.TRAPPED:
			return "智斗失败，游戏结束"
	return ""
