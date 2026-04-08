extends CharacterBody2D

# ============================================================
# 信号定义
# ============================================================
signal mouth_activated(position: Vector2)
signal player_devoured()

# ============================================================
# 常量
# ============================================================
const CHASE_SPEED: float = 220.0  # 追及速度 = 玩家跑步速度
const ACTIVATION_RANGE: float = 400.0  # 激活探测范围

# ============================================================
# 状态
# ============================================================
enum State { HIDDEN, CHASING, DEVOURING }

var current_state: State = State.HIDDEN
var _active_floor: String = ""
var _floor_explicitly_set: bool = false
var _target: Node = null
var _player: Node = null
var _devour_timer: float = 0.0

# ============================================================
# 视觉占位
# ============================================================
var _oval: Polygon2D = null

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	add_to_group("big_mouth")
	_setup_visual()
	_hide_mouth()
	print("[BigMouth] 巨嘴怪物就绪，目标楼层: %s" % _active_floor)

func _setup_visual() -> void:
	_oval = Polygon2D.new()
	_oval.name = "BigMouthVisual"
	# 黑色椭圆（宽扁）
	var pts := PackedVector2Array([
		Vector2(-30, 0),   # 左
		Vector2(-20, -15), # 左上
		Vector2(0, -20),   # 上
		Vector2(20, -15),  # 右上
		Vector2(30, 0),    # 右
		Vector2(20, 15),   # 右下
		Vector2(0, 20),    # 下
		Vector2(-20, 15)   # 左下
	])
	_oval.polygon = pts
	_oval.color = Color(0.05, 0.05, 0.05, 1.0)
	add_child(_oval)

# ============================================================
# 每帧处理
# ============================================================

func _physics_process(delta: float) -> void:
	match current_state:
		State.HIDDEN:
			_check_activation(delta)
		State.CHASING:
			_chase_target(delta)
		State.DEVOURING:
			_do_devour(delta)

	move_and_slide()

# ============================================================
# 激活检测
# ============================================================

func _check_activation(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return

	# 检查是否在正确楼层
	if not _is_correct_floor():
		return

	# 检查玩家是否在跑步（优先用 is_running() 方法，否则用反射读 _is_running）
	var is_running: bool = false
	if _player.has_method("is_running"):
		is_running = _player.is_running()
	elif "_is_running" in _player:
		is_running = _player.get("_is_running")
	if is_running:
		_activate()

# ============================================================
# 激活：从地面冲出
# ============================================================

func _activate() -> void:
	if current_state != State.HIDDEN:
		return

	current_state = State.CHASING
	_target = _player
	velocity = Vector2.ZERO

	# 从目标脚下冲出（出现在目标位置）
	if _target != null:
		global_position = _target.global_position

	mouth_activated.emit(global_position)
	print("[BigMouth] 冲出！目标: %s" % (_target.name if _target else "?"))

func _is_correct_floor() -> bool:
	# 优先用显式设置的楼层
	if _floor_explicitly_set:
		var current_scene: String = get_tree().current_scene.name if get_tree().current_scene else ""
		return current_scene.begins_with(_active_floor) or current_scene.to_lower().contains(_active_floor.to_lower())
	# fallback：用场景名判断
	var current_scene: String = get_tree().current_scene.name if get_tree().current_scene else ""
	return current_scene.begins_with("Floor3") or current_scene.begins_with("Level3")

# ============================================================
# 追击
# ============================================================

func _chase_target(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_cancel_chase()
		return

	var direction: Vector2 = (_target.global_position - global_position).normalized()
	velocity = direction * CHASE_SPEED

	# 检测是否接触目标
	if global_position.distance_to(_target.global_position) < 20.0:
		_begin_devour()

	# 检查目标是否停止跑步（反射 _is_running 变量）
	var still_running: bool = false
	if _target.has_method("is_running"):
		still_running = _target.is_running()
	elif "_is_running" in _target:
		still_running = _target.get("_is_running")
	if not still_running:
		_cancel_chase()

# ============================================================
# 吞噬
# ============================================================

func _begin_devour() -> void:
	if current_state != State.CHASING:
		return
	current_state = State.DEVOURING
	velocity = Vector2.ZERO
	_devour_timer = 0.0
	print("[BigMouth] 吞噬中……")

func _do_devour(delta: float) -> void:
	_devour_timer += delta
	if _devour_timer >= 0.5:
		# 吞噬完成
		if is_instance_valid(_target):
			print("被巨嘴吞噬")
			player_devoured.emit()
			if _target.is_in_group("player"):
				# 玩家被吞噬 → 游戏结束
				GameManager.trigger_game_over("被巨嘴吞噬")
			elif _target.has_method("die"):
				_target.die()
			else:
				_target.queue_free()
		_hide_mouth()
		current_state = State.HIDDEN

# ============================================================
# 取消追击
# ============================================================

func _cancel_chase() -> void:
	print("[BigMouth] 目标停止跑步，隐藏")
	velocity = Vector2.ZERO
	_target = null
	current_state = State.HIDDEN
	_hide_mouth()

func _hide_mouth() -> void:
	if _oval != null:
		_oval.visible = false

# ============================================================
# 外部接口
# ============================================================

func set_active_floor(floor_id: String) -> void:
	_active_floor = floor_id
	_floor_explicitly_set = true
	print("[BigMouth] 生效楼层: %s" % floor_id)

func get_active_floor() -> String:
	return _active_floor

func is_chasing() -> bool:
	return current_state == State.CHASING
