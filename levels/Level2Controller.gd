extends Node2D
class_name Level2Controller

signal entered_safe_room(room_name: String)
signal left_safe_room(room_name: String)
signal heels_sound_detected(position: Vector2)
signal xiaxia_mirror_triggered
signal game_over_triggered(reason: String)

@export var monsters_patrol: Array[NodePath] = []
@export var monster_heels_path: NodePath = ^"Monsters/Monster_Heels"
@export var heels_speaker_path: NodePath = ^"HeelsSpeaker"
@export var corridor_area_path: NodePath = ^"Rooms/Corridor_L2"
@export var mirror_zone_path: NodePath = ^"MirrorZone"
@export var hidden_room_path: NodePath = ^"Rooms/HiddenRoom"

var _player: Node = null
var _corridor_area: Area2D = null
var _mirror_zone: Area2D = null
var _hidden_room: Area2D = null

var _xiaxia_triggered: bool = false
var _elevator_cards_collected: int = 0
const ELEVATOR_CARDS_REQUIRED: int = 2

var _has_earplugs_equipped: bool = false
var _current_safe_room: String = ""

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_corridor_area = get_node(corridor_area_path)
	_mirror_zone = get_node(mirror_zone_path)
	_hidden_room = get_node(hidden_room_path)

	_setup_areas()
	_setup_heels_system()
	_setup_monsters()
	_connect_earplug_signal()
	print("[Level2Controller] Level2 就绪")

# ============================================================
# 区域检测
# ============================================================

func _setup_areas() -> void:
	if _corridor_area.has_signal("body_entered"):
		_corridor_area.body_entered.connect(_on_corridor_entered)
		_corridor_area.body_exited.connect(_on_corridor_exited)

	if _mirror_zone.has_signal("body_entered"):
		_mirror_zone.body_entered.connect(_on_mirror_zone_entered)

	if _hidden_room.has_signal("body_entered"):
		_hidden_room.body_entered.connect(_on_hidden_room_entered)

# ============================================================
# 高跟鞋音效系统
# ============================================================

func _setup_heels_system() -> void:
	var heels_speaker: Node = get_node(heels_speaker_path)
	if heels_speaker.has_method("start_heels_loop"):
		heels_speaker.start_heels_loop()

	if has_signal("heels_sound_detected"):
		# 监听 Monster_Heels 移动时发射的信号
		var monster_heels: Node = get_node(monster_heels_path)
		if monster_heels.has_signal("heels_step"):
			monster_heels.heels_step.connect(_on_heels_step)

func _on_heels_step(heels_position: Vector2) -> void:
	heels_sound_detected.emit(heels_position)
	_check_heels_player_lock(heels_position)

func _check_heels_player_lock(sound_position: Vector2) -> void:
	if _has_earplugs_equipped:
		print("[Level2Controller] 玩家佩戴耳塞，高跟鞋声被屏蔽")
		return

	if not _is_player_in_corridor():
		return

	print("[Level2Controller] 检测到高跟鞋声，玩家在走廊且无耳塞 → 触发怪物锁定")
	_lock_player_to_all_monsters()
	_trigger_heels_game_over_effect()

func _is_player_in_corridor() -> bool:
	if _player == null or _corridor_area == null:
		return false
	var bodies: Array = _corridor_area.get_overlapping_bodies()
	return bodies.has(_player)

func _lock_player_to_all_monsters() -> void:
	for path: NodePath in monsters_patrol:
		var monster: Node = get_node(path)
		if monster.has_method("force_chase"):
			monster.force_chase(_player)
		elif monster.has_method("on_player_detected"):
			monster.on_player_detected(_player)

# ============================================================
# 小夏剧情触发（镜子过场）
# ============================================================

func _on_mirror_zone_entered(body: Node) -> void:
	if body != _player:
		return
	if _xiaxia_triggered:
		return

	_xiaxia_triggered = true
	xiaxia_mirror_triggered.emit()
	print("[Level2Controller] 触发小夏镜子过场动画")

	# 过场动画播放完后（由场景脚本通知），给玩家发放规则残页3
	_give_rule_page_3()

	# 可选：临时禁用玩家输入，播放动画
	_player.set_process_input(false)
	# 动画播放完毕后，调用 _restore_player_input()
	# 这里预留接口，由过场动画场景调用
	restore_player_input_after_cutscene()

func _give_rule_page_3() -> void:
	var rule_page: Item = ItemRulePage3.new()
	ItemSystem.pickup(rule_page)
	rule_page.use(null)
	print("[Level2Controller] 规则残页（三）已发放给玩家")

func restore_player_input_after_cutscene() -> void:
	await get_tree().create_timer(0.5).timeout
	if _player != null:
		_player.set_process_input(true)
	print("[Level2Controller] 过场结束，玩家输入恢复")

# ============================================================
# 隔音耳塞信号连接
# ============================================================

func _connect_earplug_signal() -> void:
	# 监听 ItemEarplug 的 equipped/unequipped 信号
	# ItemEarplug 在背包使用后会发射这些信号
	# 这里通过 ItemSystem 的 inventory_changed 信号来检测
	pass

func _on_inventory_changed() -> void:
	_has_earplugs_equipped = ItemSystem.has_item("earplug")
	print("[Level2Controller] 背包变动，耳塞装备状态: %s" % _has_earplugs_equipped)

# ============================================================
# 怪物相关
# ============================================================

func _setup_monsters() -> void:
	for path: NodePath in monsters_patrol:
		var monster: Node = get_node(path)
		_connect_monster_signals(monster)

	var monster_heels: Node = get_node(monster_heels_path)
	_connect_monster_signals(monster_heels)
	if monster_heels.has_signal("heels_step"):
		monster_heels.heels_step.connect(_on_heels_step)

func _connect_monster_signals(monster: Node) -> void:
	if monster.has_signal("eye_contact"):
		monster.eye_contact.connect(_on_monster_eye_contact)
	if monster.has_signal("monster_died"):
		monster.monster_died.connect(_on_monster_died)
	if monster.has_signal("monster_bound"):
		monster.monster_bound.connect(_on_monster_bound)

func _on_monster_eye_contact(monster: Node, player: Node) -> void:
	if not RuleSystem.can_swap(monster, player):
		print("[Level2Controller] 对视不能互换，触发后果")
		GameManager.trigger_game_over("eye_contact_forbidden")
		return
	RuleSystem.do_swap(monster, player)
	print("[Level2Controller] 灵魂互换已执行")

func _on_monster_bound(monster: Node) -> void:
	GameManager.on_monster_bound(monster)

func _on_monster_died(monster: Node) -> void:
	GameManager.on_monster_killed(monster)

# ============================================================
# 隐藏房间
# ============================================================

func _on_hidden_room_entered(body: Node) -> void:
	if body != _player:
		return
	_current_safe_room = "HiddenRoom"
	_player.is_in_safe_room = true
	entered_safe_room.emit("HiddenRoom")
	print("[Level2Controller] 玩家进入隐藏房间（安全区）")

# ============================================================
# 走廊
# ============================================================

func _on_corridor_entered(body: Node) -> void:
	if body != _player:
		return
	_current_safe_room = ""
	print("[Level2Controller] 玩家进入走廊（非安全区）")

func _on_corridor_exited(body: Node) -> void:
	if body != _player:
		return
	if _current_safe_room == "Corridor_L2":
		_current_safe_room = ""
	print("[Level2Controller] 玩家离开走廊")

# ============================================================
# 电梯权限卡
# ============================================================

func on_elevator_card_collected() -> void:
	_elevator_cards_collected += 1
	print("[Level2Controller] 电梯权限卡: %d/%d" % [_elevator_cards_collected, ELEVATOR_CARDS_REQUIRED])
	if _elevator_cards_collected >= ELEVATOR_CARDS_REQUIRED:
		_activate_elevator()

func _activate_elevator() -> void:
	var elevator: Node = get_node_or_null("../../../Elevator")
	if elevator and elevator.has_method("activate"):
		elevator.activate()
		print("[Level2Controller] 电梯已激活")

# ============================================================
# 高跟鞋 Game Over 效果（智谋层面，非立刻死亡）
# ============================================================

func _trigger_heels_game_over_effect() -> void:
	# 高跟鞋声导致所有走廊怪物锁定玩家
	# 玩家被逼入死角，触发"无法逃脱"事件
	GameManager.trigger_game_over("heels_trapped")
	print("[Level2Controller] 高跟鞋声触发走廊困杀结局")

# ============================================================
# 预留：动画播放完毕回调
# ============================================================

func on_mirror_cutscene_finished() -> void:
	restore_player_input_after_cutscene()
