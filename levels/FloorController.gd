extends Node2D
class_name FloorController

signal vision_changed(mode: String)

@export var monsters: Array[NodePath] = []
@export var backup_monsters: Array[NodePath] = []

var _player: Node = null
var _controlled_entity: Node = null
var _recorder_position: Vector2 = Vector2.ZERO
var _night_fall_activated: bool = false

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_setup_player()
	_setup_monsters()
	_connect_item_signals()
	_connect_game_manager_signals()
	print("[FloorController] 每层控制器就绪")

func _setup_player() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		push_warning("[FloorController] 未找到 Player 节点，请确保玩家在 'player' 分组中")

func _setup_monsters() -> void:
	for path: NodePath in monsters:
		var monster: Node = get_node(path)
		_connect_monster_signals(monster)

	for path: NodePath in backup_monsters:
		var monster: Node = get_node(path)
		monster.set_process(false)
		monster.set_physics_process(false)
		_connect_monster_signals(monster)

func _connect_monster_signals(monster: Node) -> void:
	if monster.has_signal("eye_contact"):
		monster.eye_contact.connect(_on_monster_eye_contact)
	if monster.has_signal("monster_bound"):
		monster.monster_bound.connect(_on_monster_bound)
	if monster.has_signal("monster_died"):
		monster.monster_died.connect(_on_monster_died)

func _connect_item_signals() -> void:
	ItemSystem.key_item_acquired.connect(_on_key_item_acquired)

func _connect_game_manager_signals() -> void:
	GameManager.forbidden_period_start.connect(_on_forbidden_period_start)
	GameManager.forbidden_period_end.connect(_on_forbidden_period_end)

# ============================================================
# 1. 监听 eye_contact 信号
# ============================================================

func _on_monster_eye_contact(monster: Node, player: Node) -> void:
	if not RuleSystem.can_swap(monster, player):
		print("[FloorController] 不能互换：不在禁对视时段或已达次数上限")
		GameManager.trigger_game_over("eye_contact_forbidden")
		return

	print("[FloorController] 检测到对视，开始灵魂互换")
	RuleSystem.do_swap(monster, player)

	var soul_color: RuleSystem.SoulColor = RuleSystem.get_soul_color(player)
	print("[FloorController] 玩家当前瞳孔颜色: %s" % soul_color)

	_activate_backup_monsters()
	GameManager.on_swap_triggered(monster, player)

# ============================================================
# 2. 监听禁对视时段信号（由 GameManager 虚拟时钟触发）
# ============================================================

func _on_forbidden_period_start() -> void:
	if _night_fall_activated:
		return
	_night_fall_activated = true
	print("[FloorController] 23:00 禁对视时段开始，怪物密度翻倍")
	_activate_backup_monsters()
	GameManager.on_night_fall()

func _on_forbidden_period_end() -> void:
	_night_fall_activated = false
	print("[FloorController] 07:00 禁对视时段结束，强制换回所有灵魂")
	RuleSystem.force_return_all()
	_switch_control_to_player()
	GameManager.on_morning_come()

func _activate_backup_monsters() -> void:
	for path: NodePath in backup_monsters:
		var monster: Node = get_node(path)
		monster.set_process(true)
		monster.set_physics_process(true)
		_connect_monster_signals(monster)
	print("[FloorController] 备用怪物节点已激活，数量: %d" % backup_monsters.size())

# ============================================================
# 3. 玩家操控切换
# ============================================================

func switch_control_to(entity: Node) -> void:
	if _controlled_entity != null and is_instance_valid(_controlled_entity):
		_disable_entity_input(_controlled_entity)

	_controlled_entity = entity
	_disable_player_input()
	_enable_entity_input(entity)
	vision_changed.emit("dark")
	print("[FloorController] 操控已切换至: %s，视野变黑" % entity.name)

func switch_control_to_player() -> void:
	if _controlled_entity != null and is_instance_valid(_controlled_entity):
		_disable_entity_input(_controlled_entity)
	_controlled_entity = null
	_enable_player_input()
	vision_changed.emit("normal")
	print("[FloorController] 操控已切换回玩家")

func _disable_player_input() -> void:
	if _player != null and is_instance_valid(_player):
		_player.set_process_input(false)

func _enable_player_input() -> void:
	if _player != null and is_instance_valid(_player):
		_player.set_process_input(true)

func _disable_entity_input(entity: Node) -> void:
	entity.set_process_input(false)

func _enable_entity_input(entity: Node) -> void:
	entity.set_process_input(true)

# ============================================================
# 4. 录音笔信号
# ============================================================

func _on_recorder_placed(position: Vector2) -> void:
	_recorder_position = position
	print("[FloorController] 录音笔放置在: %s，通知怪物前往调查" % position)
	for path: NodePath in monsters:
		var monster: Node = get_node(path)
		if monster.has_method("move_to_investigate"):
			monster.move_to_investigate(position)

# ============================================================
# 辅助
# ============================================================

func _on_monster_bound(monster: Node) -> void:
	print("[FloorController] 怪物 %s 已被绑定" % monster.name)
	GameManager.on_monster_bound(monster)

func _on_monster_died(monster: Node) -> void:
	print("[FloorController] 怪物 %s 已死亡" % monster.name)
	GameManager.on_monster_killed(monster)

func _on_key_item_acquired(item_id: String) -> void:
	print("[FloorController] 关键道具已获取: %s" % item_id)
	GameManager.on_key_item_collected(item_id)
