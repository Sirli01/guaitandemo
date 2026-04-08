extends CharacterBody2D

# ============================================================
# 信号定义
# ============================================================
signal eye_contact_monster(monster: Node, target: Node)
signal monster_died()
signal player_controlling_monster(controlling: bool)
signal monster_bound(monster: Node)

# ============================================================
# 常量
# ============================================================
const WALK_SPEED: float = 96.0  # 玩家普通速度 120 的 80%

# ============================================================
# 状态
# ============================================================
enum State { PATROL, TRACKING, SOUL_SWAPPED, DYING }
var current_state: State = State.PATROL

var _player: Node = null
var _patrol_origin: Vector2 = Vector2.ZERO
var _patrol_timer: float = 0.0
var _is_patrolling_forward: bool = true

# 玩家是否在操控怪物身体
var _player_controlling: bool = false

# 绑定状态
var is_bound: bool = false

# 灵魂互换相关
var _swapped_with_player: bool = false
var _original_player_body: Node = null

# ============================================================
# 视觉占位
# ============================================================
var _body_rect: ColorRect = null

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	add_to_group("human_monster")
	_setup_visual()
	_patrol_origin = global_position
	print("[HumanMonster] 人形怪物就绪")

func _setup_visual() -> void:
	_body_rect = ColorRect.new()
	_body_rect.name = "HumanMonsterVisual"
	_body_rect.color = Color(0.05, 0.05, 0.05, 1.0)
	_body_rect.custom_minimum_size = Vector2(30, 60)  # 高矩形人形
	_body_rect.position = Vector2(-15, -30)
	add_child(_body_rect)

	# 碰撞体
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30, 60)
	collision.shape = shape
	add_child(collision)

# ============================================================
# 每帧处理
# ============================================================

func _physics_process(delta: float) -> void:
	match current_state:
		State.PATROL:
			_do_patrol(delta)
		State.TRACKING:
			_track_player(delta)
		State.SOUL_SWAPPED:
			_handle_soul_swap_state(delta)
		State.DYING:
			pass

	move_and_slide()

# ============================================================
# 巡逻行为
# ============================================================

func _do_patrol(delta: float) -> void:
	_patrol_timer += delta

	if _patrol_timer > 2.0:
		_patrol_timer = 0.0
		_is_patrolling_forward = not _is_patrolling_forward

	var dir: float = 1.0 if _is_patrolling_forward else -1.0
	velocity = Vector2(dir * WALK_SPEED * 0.5, 0)

	# 限制在巡逻范围内
	if abs(global_position.x - _patrol_origin.x) > 80:
		_is_patrolling_forward = not _is_patrolling_forward

	# 检测玩家靠近
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _player != null:
		var dist: float = global_position.distance_to(_player.global_position)
		if dist < 200.0:
			current_state = State.TRACKING
			print("[HumanMonster] 发现玩家，进入追踪")

# ============================================================
# 追踪玩家
# ============================================================

func _track_player(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		current_state = State.PATROL
		return

	if _swapped_with_player:
		current_state = State.SOUL_SWAPPED
		return

	# 接近玩家时减速（不对玩家造成致命伤害，只减速）
	var dist: float = global_position.distance_to(_player.global_position)
	if dist < 60.0:
		velocity = Vector2.ZERO
		# 减速玩家 50%
		if _player.has_method("apply_slow"):
			_player.apply_slow(0.5)
		return

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	velocity = direction * WALK_SPEED

# ============================================================
# 灵魂互换状态
# ============================================================

func _handle_soul_swap_state(delta: float) -> void:
	# 玩家操控怪物身体，此时玩家按 Shift 跑步会触发 BigMouth
	# 怪物身体不移动，velocity = 0
	velocity = Vector2.ZERO

	if _player != null and _player.has_method("is_running") and _player.is_running():
		# 玩家在怪物身体里跑步，触发 BigMouth
		_trigger_big_mouth()

# ============================================================
# 触发 BigMouth
# ============================================================

func _trigger_big_mouth() -> void:
	var big_mouths: Array = get_tree().get_nodes_in_group("big_mouth")
	for bm in big_mouths:
		if bm.has_method("set_active_floor"):
			bm.set_active_floor("floor3")
			print("[HumanMonster] 怪物身体内跑步，触发 BigMouth！")

# ============================================================
# 灵魂互换触发（由外部系统调用）
# ============================================================

func on_soul_swap_happened(monster: Node, target: Node) -> void:
	if monster != self:
		return
	_swapped_with_player = true
	_original_player_body = target
	_player_controlling = true
	current_state = State.SOUL_SWAPPED
	player_controlling_monster.emit(true)
	print("[HumanMonster] 灵魂互换完成，玩家操控怪物身体")

# ============================================================
# 死亡（07:00 触发）
# ============================================================

func trigger_death() -> void:
	if current_state == State.DYING:
		return
	current_state = State.DYING
	monster_died.emit()
	print("[HumanMonster] 怪物死亡")

	await get_tree().create_timer(1.0).timeout
	queue_free()

# ============================================================
# 外部接口
# ============================================================

func is_soul_swapped() -> bool:
	return _swapped_with_player

func get_patrol_origin() -> Vector2:
	return _patrol_origin

func set_patrol_center(pos: Vector2) -> void:
	_patrol_origin = pos

# ============================================================
# 绳子绑定（智斗路线核心）
# ============================================================

func bind_with_rope() -> void:
	if is_bound:
		return
	is_bound = true
	velocity = Vector2.ZERO
	monster_bound.emit(self)
	print("[HumanMonster] 已被麻绳绑定！")
