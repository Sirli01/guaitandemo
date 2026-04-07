extends CharacterBody2D

signal stamina_exhausted
signal debuff_active(buff_type: String)
signal game_over_starvation

const WALK_SPEED: float = 120.0
const RUN_SPEED: float = 220.0
const RUN_SPEED_BOOST: float = 264.0

# ============================================================
# 移动状态
# ============================================================
var _is_running: bool = false
var _stamina: float = 100.0
var _stamina_max: float = 100.0
var _stamina_temp_max_bonus: float = 0.0
var _temp_stamina_timer: float = 0.0
var _has_speed_boost: bool = false

# ============================================================
# 生存双轨
# ============================================================
var _hydration: float = 80.0
var _satiety: float = 80.0
var _hunger_drain_accum: float = 0.0

# ============================================================
# 外部控制
# ============================================================
var is_in_safe_room: bool = false

# ============================================================
# 运动子状态
# ============================================================
var _is_moving: bool = false
var _move_input: Vector2 = Vector2.ZERO
var _last_facing: Vector2 = Vector2.DOWN

# ============================================================
# 交互系统
# ============================================================
var _interaction_area: Area2D
var _nearby_interactable: Node = null
var _interaction_prompt: Label = null

# ============================================================
# 核心函数
# ============================================================

func _physics_process(delta: float) -> void:
	_move_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if _move_input != Vector2.ZERO:
		_last_facing = _move_input.normalized()
		_is_moving = true
		if Input.is_action_pressed("sprint"):
			_try_run(delta)
		else:
			_walk(delta)
	else:
		_is_moving = false
		velocity = Vector2.ZERO
		_restore_stamina(delta, true)
		_is_running = false


	_update_survival(delta)
	_apply_debuff(delta)
	move_and_slide()
	_update_interaction_prompt()

func _try_run(delta: float) -> void:
	if _stamina <= 0.0:
		_is_running = false
		_walk(delta)
		return
	_is_running = true
	var speed: float = RUN_SPEED_BOOST if _has_speed_boost else RUN_SPEED
	velocity = _move_input * speed
	_consume_stamina(delta * 8.0)

func _walk(delta: float) -> void:
	_is_running = false
	velocity = _move_input * WALK_SPEED
	# ★ 走路也微微消耗体力（0.3/s），增加生存压迫感
	_consume_stamina(delta * 0.3)

# ============================================================
# 体力核心函数
# ============================================================

func _consume_stamina(amount: float) -> void:
	var effective_max: float = _stamina_max + _stamina_temp_max_bonus
	_stamina = clamp(_stamina - amount, 0.0, effective_max)
	if _stamina <= 0.0:
		stamina_exhausted.emit()

func _restore_stamina(delta: float, idle: bool) -> void:
	if not idle:
		return
	var rate: float = 3.0 * _get_stamina_recovery_multiplier()
	_consume_stamina(delta * -rate)

func _get_stamina_recovery_multiplier() -> float:
	return 2.0 if is_in_safe_room else 1.0

# ============================================================
# 生存双轨逻辑
# ============================================================

func _update_survival(delta: float) -> void:
	if is_in_safe_room:
		_hunger_drain_accum = 0.0
		return

	var drain_rate: float = 4.0 if _is_running else 2.0
	var drain_interval: float = 60.0
	var effective_drain: float = drain_rate * (delta / drain_interval)

	_hunger_drain_accum += effective_drain
	if _hunger_drain_accum >= 1.0:
		var drain_int: int = int(_hunger_drain_accum)
		_hunger_drain_accum -= float(drain_int)
		_hydration = max(_hydration - float(drain_int), 0.0)
		_satiety = max(_satiety - float(drain_int), 0.0)
		_check_starvation_gameover()

# ============================================================
# debuff
# ============================================================

func _apply_debuff(delta: float) -> void:
	var hydration_zero: bool = _hydration <= 0.0
	var satiety_zero: bool = _satiety <= 0.0

	if hydration_zero:
		_stamina_max = max(_stamina_max - delta * 0.5, 0.0)
		debuff_active.emit("dehydration")
		if _stamina_max < 20.0:
			debuff_active.emit("stamina_collapsed")

	if satiety_zero:
		_stamina_max = max(_stamina_max - delta * 0.5, 0.0)
		debuff_active.emit("starvation")
		if _stamina_max < 20.0:
			debuff_active.emit("stamina_collapsed")

	if hydration_zero and satiety_zero:
		game_over_starvation.emit()

func _check_starvation_gameover() -> void:
	if _hydration <= 0.0 and _satiety <= 0.0:
		game_over_starvation.emit()

# ============================================================
# 外部恢复接口
# ============================================================

func restore_water(amount: float) -> void:
	_hydration = clamp(_hydration + amount, 0.0, 100.0)

func restore_food(amount: float) -> void:
	_satiety = clamp(_satiety + amount, 0.0, 100.0)

# ============================================================
# 交互消耗
# ============================================================

func spend_stamina_interact() -> void:
	_consume_stamina(15.0)

func spend_stamina_break() -> void:
	_consume_stamina(15.0)

# ============================================================
# 功能饮料
# ============================================================

func apply_stamina_drink() -> void:
	_stamina_temp_max_bonus = _stamina_max * 0.3
	_temp_stamina_timer = 300.0
	_has_speed_boost = true
	_consume_stamina(-20.0)
	print("[Player] 功能饮料生效：体力上限 +30%%，跑步速度 +20%%，持续 300 秒")

func _process(delta: float) -> void:
	if _temp_stamina_timer > 0.0:
		_temp_stamina_timer -= delta
		if _temp_stamina_timer <= 0.0:
			_stamina_temp_max_bonus = 0.0
			_has_speed_boost = false
			_stamina = min(_stamina, _stamina_max)

# ============================================================
# 交互系统实现
# ============================================================

func _setup_interaction_area() -> void:
	_interaction_area = Area2D.new()
	_interaction_area.name = "InteractionArea"
	var shape := CircleShape2D.new()
	shape.radius = 50.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	_interaction_area.add_child(collision)
	# ★ 关键修复：检测范围是 Area2D，用 area_entered 而不是 body_entered
	_interaction_area.area_entered.connect(_on_interaction_area_entered)
	_interaction_area.area_exited.connect(_on_interaction_area_exited)
	# ★ collision_layer = 0 不发出，collision_mask = 2 检测 layer 2 上的 Area2D
	_interaction_area.collision_layer = 0
	_interaction_area.collision_mask = 2
	add_child(_interaction_area)

	# 交互提示 Label
	_interaction_prompt = Label.new()
	_interaction_prompt.name = "InteractionPrompt"
	_interaction_prompt.text = "按 E 交互"
	_interaction_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interaction_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_interaction_prompt.modulate = Color(1, 1, 1, 0)
	_interaction_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_interaction_prompt.position = Vector2(-60, -60)
	add_child(_interaction_prompt)

func _on_interaction_area_entered(area: Area2D) -> void:
	# ★ 改用 area_entered，检测进入检测范围的 Area2D
	if area.is_in_group("interactable"):
		_nearby_interactable = area
		_show_interaction_prompt(area)

func _on_interaction_area_exited(area: Area2D) -> void:
	if area == _nearby_interactable:
		_nearby_interactable = null
		_hide_interaction_prompt()

func _show_interaction_prompt(area: Area2D) -> void:
	var hint: String = area.get("interaction_hint") if "interaction_hint" in area else "按 E 交互"
	_interaction_prompt.text = hint
	_interaction_prompt.modulate = Color(1, 1, 1, 1)

func _hide_interaction_prompt() -> void:
	_interaction_prompt.modulate = Color(1, 1, 1, 0)

func _update_interaction_prompt() -> void:
	if _nearby_interactable == null:
		return
	_interaction_prompt.global_position = global_position + Vector2(0, -50)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact()

func _try_interact() -> void:
	if _nearby_interactable == null:
		return
	if not is_instance_valid(_nearby_interactable):
		_nearby_interactable = null
		return
	# ★ 普通拾取不扣体力（砸门等重动作由对应系统单独扣）
	_nearby_interactable.interact(self)
	_hide_interaction_prompt()
	_nearby_interactable = null

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	add_to_group("player")
	_setup_interaction_area()
	# ★ 白模占位视觉（让玩家可见）
	var visual := ColorRect.new()
	visual.name = "PlayerVisual"
	visual.color = Color.GREEN
	visual.custom_minimum_size = Vector2(32, 32)
	visual.position = Vector2(-16, -16)
	add_child(visual)
	print("[Player] 已加入 'player' 分组，体力:%.1f 水分:%.1f 饱腹:%.1f" % [_stamina, _hydration, _satiety])
