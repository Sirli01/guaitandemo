extends CharacterBody2D
class_name HeelMonster

# ============================================================
# 信号定义
# ============================================================
signal lock_acquired(target: Node)
signal lock_transferred(old_target: Node, new_target: Node)
signal target_killed(target: Node)
signal direction_indicator_visible(show: bool, direction: Vector2)

# ============================================================
# 常量
# ============================================================
const ROAM_SPEED: float = 30.0
const LOCK_RANGE: float = 800.0
const SEPARATION_THRESHOLD: float = 300.0
const LOCK_DURATION: float = 15.0

# ============================================================
# 状态变量
# ============================================================
var _locked_target: Node = null
var _lock_timer: float = 0.0
var _is_locked: bool = false
var _roam_target: Vector2 = Vector2.ZERO
var _roam_timer: float = 0.0
var _has_printed_lock_sound: bool = false

# ============================================================
# 方向指示器 UI
# ============================================================
var _direction_icon: Control = null
var _hud_reference: CanvasLayer = null

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	add_to_group("heel_monster")
	_set_roam_target()
	_setup_direction_icon()
	print("[HeelMonster] 高跟鞋怪物已生成，漫游轨迹：地图上方")

func _setup_direction_icon() -> void:
	# 创建方向指示图标（屏幕边缘的箭头）
	_direction_icon = Control.new()
	_direction_icon.name = "DirectionIcon"
	_direction_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_direction_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var arrow := Polygon2D.new()
	arrow.name = "Arrow"
	# 黑色三角形顶点（朝上的三角形）
	var points := PackedVector2Array([
		Vector2(0, -20),   # 上顶点
		Vector2(-15, 10),  # 左下
		Vector2(15, 10)    # 右下
	])
	arrow.polygon = points
	arrow.color = Color(0.0, 0.0, 0.0, 0.8)
	_direction_icon.add_child(arrow)

	# 添加到根节点的 CanvasLayer（如果存在 HUD）
	var root = get_tree().root
	if root.has_node("HUD"):
		_hud_reference = root.get_node("HUD")
		_hud_reference.add_child(_direction_icon)

	_direction_icon.visible = false

# ============================================================
# 每帧处理
# ============================================================

func _physics_process(delta: float) -> void:
	if not _is_locked:
		_do_roam(delta)
		_check_for_separated_targets()
	else:
		_maintain_lock(delta)

	_update_direction_icon_position()
	move_and_slide()

# ============================================================
# 漫游行为（地图上方缓慢移动）
# ============================================================

func _do_roam(delta: float) -> void:
	_roam_timer += delta
	if _roam_timer > 3.0:
		_set_roam_target()
		_roam_timer = 0.0

	var direction: Vector2 = (_roam_target - global_position).normalized()
	velocity = direction * ROAM_SPEED

	if global_position.distance_to(_roam_target) < 10.0:
		_set_roam_target()

func _set_roam_target() -> void:
	# 在地图上方区域随机选择漫游点（y < 200）
	var map_width: float = 1000.0
	var random_x: float = randf() * map_width
	_roam_target = Vector2(random_x, randf() * 150.0 + 30.0)

# ============================================================
# 锁定逻辑
# ============================================================

func _check_for_separated_targets() -> void:
	if _is_locked:
		return

	var npcs: Array = get_tree().get_nodes_in_group("npc")
	var separated_npcs: Array = []

	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		if _has_earplugs(npc):
			continue
		if is_in_safe_room(npc):
			continue
		if is_group_separated(npc):
			separated_npcs.append(npc)

	if not separated_npcs.is_empty():
		# 优先锁定脱离队伍的 NPC
		_acquire_lock(separated_npcs[0])

func _acquire_lock(target: Node) -> void:
	_locked_target = target
	_is_locked = true
	_lock_timer = 0.0
	_has_printed_lock_sound = false
	lock_acquired.emit(target)
	print("[HeelMonster] 高跟鞋声锁定：%s" % target.name)

func _maintain_lock(delta: float) -> void:
	if not is_instance_valid(_locked_target):
		_cancel_lock()
		return

	# 检查目标是否进入安全区
	if is_in_safe_room(_locked_target):
		_transfer_lock()
		return

	# 检查目标是否还脱离队伍
	if not is_group_separated(_locked_target):
		_cancel_lock()
		return

	# 检查目标是否还佩戴耳塞
	if _has_earplugs(_locked_target):
		_cancel_lock()
		return

	_lock_timer += delta

	# 第一次锁定时打印脚步声回声
	if not _has_printed_lock_sound:
		print("脚步声回声")
		_has_printed_lock_sound = true

	# 更新方向指示器
	_update_lock_direction()

	# 锁定超时，目标死亡
	if _lock_timer >= LOCK_DURATION:
		_kill_target()

func _cancel_lock() -> void:
	if is_instance_valid(_locked_target):
		print("[HeelMonster] 锁定解除：%s 重新融入群体" % _locked_target.name)
	_locked_target = null
	_is_locked = false
	_lock_timer = 0.0
	_has_printed_lock_sound = false
	direction_indicator_visible.emit(false, Vector2.ZERO)
	_hide_direction_icon()

func _transfer_lock() -> void:
	print("[HeelMonster] 目标进入安全区，锁定转移...")
	var old_target = _locked_target
	direction_indicator_visible.emit(false, Vector2.ZERO)
	_hide_direction_icon()

	# 寻找下一个脱离者
	var npcs: Array = get_tree().get_nodes_in_group("npc")
	var new_target: Node = null

	for npc in npcs:
		if not is_instance_valid(npc):
			continue
		if npc == old_target:
			continue
		if _has_earplugs(npc):
			continue
		if is_in_safe_room(npc):
			continue
		if is_group_separated(npc):
			new_target = npc
			break

	_cancel_lock()

	if new_target != null:
		_acquire_lock(new_target)
		lock_transferred.emit(old_target, new_target)

func _kill_target() -> void:
	if is_instance_valid(_locked_target):
		print("[HeelMonster] 锁定超时，%s 死亡" % _locked_target.name)
		target_killed.emit(_locked_target)

		# 调用目标的 die() 方法（如果存在）
		if _locked_target.has_method("die"):
			_locked_target.die()
		else:
			_locked_target.queue_free()

	_cancel_lock()

# ============================================================
# 公共查询函数
# ============================================================

func is_group_separated(npc: Node) -> bool:
	"""判断 NPC 是否脱离队伍（距离其他 NPC 超过 300px）"""
	if not is_instance_valid(npc):
		return false

	var npcs: Array = get_tree().get_nodes_in_group("npc")
	var other_count: int = 0

	for other in npcs:
		if not is_instance_valid(other):
			continue
		if other == npc:
			continue
		var distance: float = npc.global_position.distance_to(other.global_position)
		if distance <= SEPARATION_THRESHOLD:
			other_count += 1

	# 如果没有其他 NPC 在 300px 范围内，则认为脱队
	return other_count == 0

func is_locked() -> bool:
	return _is_locked

func get_locked_target() -> Node:
	return _locked_target

# ============================================================
# 辅助函数
# ============================================================

func _has_earplugs(npc: Node) -> bool:
	# 检查 NPC 是否有耳塞标记（通过 earplug_equipped 信号或属性）
	if npc.has_method("is_wearing_earplugs"):
		return npc.is_wearing_earplugs()
	if npc.has_method("get_item_equipped"):
		return npc.get_item_equipped() == "earplug"
	# 检查节点上是否有耳塞子节点
	for child in npc.get_children():
		if child.name == "Earplug" or child.name.begins_with("earplug"):
			return true
	return false

func is_in_safe_room(npc: Node) -> bool:
	# 检查 NPC 是否在安全区
	if npc.has_method("is_in_safe_room"):
		return npc.is_in_safe_room()
	if npc.has_property("is_in_safe_room"):
		return npc.is_in_safe_room
	return false

# ============================================================
# 方向指示器
# ============================================================

func _update_lock_direction() -> void:
	if not _is_locked or not is_instance_valid(_locked_target):
		return

	var target_pos: Vector2 = _locked_target.global_position
	var monster_pos: Vector2 = global_position
	var direction: Vector2 = (target_pos - monster_pos).normalized()

	direction_indicator_visible.emit(true, direction)

func _update_direction_icon_position() -> void:
	if _direction_icon == null or not _direction_icon.visible:
		return
	if not is_instance_valid(_locked_target):
		return

	# 计算方向角度
	var target_pos: Vector2 = _locked_target.global_position
	var monster_pos: Vector2 = global_position
	var direction: Vector2 = (target_pos - monster_pos).normalized()
	var angle: float = direction.angle()

	# 将图标放置在屏幕边缘，朝向目标方向
	var arrow = _direction_icon.get_node_or_null("Arrow")
	if arrow != null:
		arrow.rotation = angle + PI / 2  # 调整角度使三角形朝上指向目标

	# 根据方向将图标放到屏幕边缘
	var screen_center: Vector2 = get_viewport_rect().size / 2
	var icon_offset: Vector2 = direction * 300.0
	var icon_pos: Vector2 = screen_center + icon_offset

	# 限制在屏幕范围内
	var screen_size: Vector2 = get_viewport_rect().size
	icon_pos.x = clamp(icon_pos.x, 40, screen_size.x - 40)
	icon_pos.y = clamp(icon_pos.y, 40, screen_size.y - 40)

	_direction_icon.set_anchors_preset(Control.PRESET_CUSTOM)
	_direction_icon.offset_left = icon_pos.x - 20
	_direction_icon.offset_top = icon_pos.y - 20
	_direction_icon.offset_right = icon_pos.x + 20
	_direction_icon.offset_bottom = icon_pos.y + 20

func _hide_direction_icon() -> void:
	if _direction_icon != null:
		_direction_icon.visible = false

# ============================================================
# 不可交互、不可杀死
# ============================================================

func _input(event: InputEvent) -> void:
	# 高跟鞋怪物不可交互，忽略所有输入
	pass

func take_damage(amount: float) -> void:
	# 怪物不可被杀死的占位函数
	print("[HeelMonster] 攻击对高跟鞋怪物无效")
	pass
