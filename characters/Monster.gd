extends CharacterBody2D
class_name Monster

enum State { PATROL, CHASE, LOST }

signal eye_contact(monster: Node, player: Node)
signal monster_died(monster: Node)
signal monster_bound(monster: Node)

@export var patrol_points: Array[NodePath] = []
@export var patrol_speed: float = 100.0
@export var chase_speed: float = 160.0
@export var sight_radius: float = 200.0
@export var sight_angle: float = 180.0
@export var eye_contact_distance: float = 80.0
@export var eye_contact_angle: float = 60.0

var current_state: State = State.PATROL
var is_bound: bool = false
var no_pupil: bool = true

var _patrol_index: int = 0
var _wait_timer: float = 0.0
var _chase_timer: float = 0.0
var _lost_timer: float = 0.0
var _target_point: Vector2 = Vector2.ZERO
var _player: Node = null

# ============================================================
# 状态机
# ============================================================

func _physics_process(delta: float) -> void:
	if is_bound:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match current_state:
		State.PATROL:
			_do_patrol(delta)
		State.CHASE:
			_do_chase(delta)
		State.LOST:
			_do_lost(delta)

	_detect_eye_contact()
	move_and_slide()

func _do_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return

	if _wait_timer > 0.0:
		_wait_timer -= delta
		velocity = Vector2.ZERO
		return

	var target: Node = get_node(patrol_points[_patrol_index])
	var direction: Vector2 = (target.global_position - global_position).normalized()
	velocity = direction * patrol_speed

	if global_position.distance_to(target.global_position) < 5.0:
		velocity = Vector2.ZERO
		_wait_timer = 1.5
		_patrol_index = (_patrol_index + 1) % patrol_points.size()

func _do_chase(delta: float) -> void:
	if not is_instance_valid(_player):
		_switch_state(State.LOST)
		return

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	velocity = direction * chase_speed
	_chase_timer += delta

	if global_position.distance_to(_player.global_position) < 10.0:
		velocity = Vector2.ZERO
		return

	if _chase_timer > 8.0:
		_switch_state(State.LOST)

func _do_lost(delta: float) -> void:
	_lost_timer += delta
	velocity = Vector2.ZERO
	if _lost_timer >= 3.0:
		_switch_state(State.PATROL)

func _switch_state(new_state: State) -> void:
	current_state = new_state
	_chase_timer = 0.0
	_lost_timer = 0.0
	_wait_timer = 0.0
	print("[Monster] 状态切换: %s -> %s" % (State.keys()[current_state], State.keys()[new_state]))

# ============================================================
# 感知入口（由场景脚本调用，传入玩家引用）
# ============================================================

func on_player_detected(player: Node) -> void:
	if is_bound:
		return
	_player = player
	if current_state == State.PATROL:
		_switch_state(State.CHASE)

func on_player_lost(player: Node) -> void:
	if current_state == State.CHASE:
		_switch_state(State.LOST)

# ============================================================
# 对视检测（锥形区域，正前方 60 度，80px）
# ============================================================

func _detect_eye_contact() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if is_bound:
		return

	var to_player: Vector2 = _player.global_position - global_position
	var distance: float = to_player.length()
	if distance > eye_contact_distance:
		return

	var forward: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	var angle_diff: float = rad_to_deg(forward.angle_to(to_player))
	if abs(angle_diff) > eye_contact_angle / 2.0:
		return

	eye_contact.emit(self, _player)

# ============================================================
# 被麻绳绑定
# ============================================================

func bind_with_rope() -> void:
	is_bound = true
	monster_bound.emit(self)
	print("[Monster] 已被麻绳绑定，移动停止")

# ============================================================
# 血量归零（由场景脚本调用）
# ============================================================

func take_damage(amount: float) -> void:
	# 此处省略血量逻辑，仅处理死亡
	monster_died.emit(self)
	print("[Monster] 血量归零，已死亡")

# ============================================================
# 验收测试
# ============================================================

func _ready() -> void:
	print("===== Monster 验收测试 =====")
	_test_state_transitions()
	print("===== 测试完成 =====")

func _test_state_transitions() -> void:
	print("[TEST] 初始状态: %s (应为 PATROL)" % State.keys()[current_state])
	_switch_state(State.CHASE)
	print("[TEST] 切换后状态: %s (应为 CHASE)" % State.keys()[current_state])
	_chase_timer = 9.0
	_do_chase(0.0)
	print("[TEST] chase_timer>8s 触发 LOST: %s (应为 LOST)" % State.keys()[current_state])
	_lost_timer = 3.0
	_do_lost(0.0)
	print("[TEST] lost_timer>=3s 返回 PATROL: %s (应为 PATROL)" % State.keys()[current_state])
	_bind_with_rope_test()
	_eye_contact_test()

func _bind_with_rope_test() -> void:
	bind_with_rope()
	print("[TEST] is_bound=%s (应为 true)" % is_bound)

func _eye_contact_test() -> void:
	var dummy_player := Node.new()
	dummy_player.name = "Player"
	var forward: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	var close_pos: Vector2 = global_position + forward * 40.0
	dummy_player.global_position = close_pos
	_player = dummy_player
	_detect_eye_contact()
	dummy_player.queue_free()
