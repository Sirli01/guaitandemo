extends CanvasLayer

var _stamina_bar: ProgressBar
var _hydration_bar: ProgressBar
var _satiety_bar: ProgressBar
var _clock_label: Label
var _warning_label: Label
var _route_hint_label: Label
var _objective_label: Label

# ReadingPanel controls
var _reading_panel: ColorRect
var _reading_title: Label
var _reading_content: RichTextLabel
var _reading_close_btn: Button

var _player: Node = null
var _game_manager: Node = null
var _warning_flash_timer: float = 0.0
var _is_warning_active: bool = false
var _warning_color: Color = Color.RED

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_game_manager = get_node_or_null("/root/GameManager")
	_build_ui()
	_connect_signals()
	print("[HUD] 动态UI已生成")

func _build_ui() -> void:
	# ============================================================
	# 体力条面板（左上角）
	# ============================================================
	var stamina_panel := HBoxContainer.new()
	stamina_panel.name = "StaminaPanel"
	add_child(stamina_panel)  # ★ 先 add_child，锚点才能正确计算
	stamina_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stamina_panel.offset_left = 10
	stamina_panel.offset_top = 10
	stamina_panel.offset_right = 270
	stamina_panel.offset_bottom = 50

	var stamina_lbl := Label.new()
	stamina_lbl.name = "StaminaLabel"
	stamina_lbl.text = "体力"
	stamina_lbl.custom_minimum_size = Vector2(40, 0)
	stamina_panel.add_child(stamina_lbl)

	_stamina_bar = ProgressBar.new()
	_stamina_bar.name = "StaminaBar"
	_stamina_bar.max_value = 100.0
	_stamina_bar.value = 100.0
	_stamina_bar.min_value = 0.0
	_stamina_bar.custom_minimum_size = Vector2(200, 20)
	stamina_panel.add_child(_stamina_bar)

	# ============================================================
	# 任务目标面板（体力条下方）
	# ============================================================
	_objective_label = Label.new()
	_objective_label.name = "ObjectiveLabel"
	_objective_label.text = ""
	_objective_label.modulate = Color(0.9, 0.85, 0.6, 1.0)
	_objective_label.add_to_group("hud_objective")
	add_child(_objective_label)
	_objective_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_objective_label.offset_left = 10
	_objective_label.offset_top = 55
	_objective_label.offset_right = 500
	_objective_label.offset_bottom = 85
	_objective_label.custom_minimum_size = Vector2(490, 30)

	# ============================================================
	# 生存双轨面板（右上角）
	# ============================================================
	var survival_panel := HBoxContainer.new()
	survival_panel.name = "SurvivalPanel"
	add_child(survival_panel)  # ★ 先 add_child
	survival_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	survival_panel.offset_left = -280
	survival_panel.offset_top = 10
	survival_panel.offset_right = -10
	survival_panel.offset_bottom = 70

	# 水分（蓝色）
	var hyd_panel := VBoxContainer.new()
	hyd_panel.name = "HydrationPanel"
	survival_panel.add_child(hyd_panel)

	var hyd_lbl := Label.new()
	hyd_lbl.name = "HydrationLabel"
	hyd_lbl.text = "水分"
	hyd_lbl.custom_minimum_size = Vector2(40, 0)
	hyd_panel.add_child(hyd_lbl)

	_hydration_bar = ProgressBar.new()
	_hydration_bar.name = "HydrationBar"
	_hydration_bar.max_value = 100.0
	_hydration_bar.value = 80.0
	_hydration_bar.min_value = 0.0
	_hydration_bar.custom_minimum_size = Vector2(110, 16)
	hyd_panel.add_child(_hydration_bar)

	# 饱腹（橙色）
	var sat_panel := VBoxContainer.new()
	sat_panel.name = "SatietyPanel"
	survival_panel.add_child(sat_panel)

	var sat_lbl := Label.new()
	sat_lbl.name = "SatietyLabel"
	sat_lbl.text = "饱腹"
	sat_lbl.custom_minimum_size = Vector2(40, 0)
	sat_panel.add_child(sat_lbl)

	_satiety_bar = ProgressBar.new()
	_satiety_bar.name = "SatietyBar"
	_satiety_bar.max_value = 100.0
	_satiety_bar.value = 80.0
	_satiety_bar.min_value = 0.0
	_satiety_bar.custom_minimum_size = Vector2(110, 16)
	sat_panel.add_child(_satiety_bar)

	# ============================================================
	# 时钟（顶部居中）
	# ============================================================
	var clock_panel := HBoxContainer.new()
	clock_panel.name = "ClockPanel"
	add_child(clock_panel)  # ★ 先 add_child
	clock_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	clock_panel.offset_left = -50
	clock_panel.offset_top = 10
	clock_panel.offset_right = 50
	clock_panel.offset_bottom = 50

	_clock_label = Label.new()
	_clock_label.name = "ClockLabel"
	_clock_label.text = "21:00"
	_clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock_label.custom_minimum_size = Vector2(100, 0)
	clock_panel.add_child(_clock_label)

	# ============================================================
	# 警告标签（屏幕正中偏上）
	# ============================================================
	_warning_label = Label.new()
	_warning_label.name = "WarningLabel"
	_warning_label.text = ""
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_warning_label.modulate = Color(1, 0, 0, 0)
	add_child(_warning_label)  # ★ 先 add_child
	_warning_label.set_anchors_preset(Control.PRESET_CENTER)
	_warning_label.offset_left = -250
	_warning_label.offset_right = 250
	_warning_label.offset_top = 120
	_warning_label.offset_bottom = 180
	_warning_label.custom_minimum_size = Vector2(500, 60)

	# ============================================================
	# 路线提示（底部居中）
	# ============================================================
	_route_hint_label = Label.new()
	_route_hint_label.name = "RouteHintLabel"
	_route_hint_label.text = ""
	_route_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_hint_label.modulate = Color(1, 0.8, 0, 0)
	add_child(_route_hint_label)  # ★ 先 add_child
	_route_hint_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_route_hint_label.offset_left = -200
	_route_hint_label.offset_right = 200
	_route_hint_label.offset_bottom = -60
	_route_hint_label.offset_top = -100
	_route_hint_label.custom_minimum_size = Vector2(400, 40)

	# ============================================================
	# ReadingPanel（剧情/规则文本阅读界面）
	# ============================================================
	_reading_panel = ColorRect.new()
	_reading_panel.name = "ReadingPanel"
	_reading_panel.visible = false
	add_child(_reading_panel)
	_reading_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_reading_panel.color = Color(0.05, 0.05, 0.05, 0.95)
	# ★ 关键：暂停时依然响应关闭按钮点击
	_reading_panel.process_mode = Node.PROCESS_MODE_ALWAYS

	var reading_vbox := VBoxContainer.new()
	reading_vbox.name = "ReadingVBox"
	_reading_panel.add_child(reading_vbox)
	reading_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	reading_vbox.process_mode = Node.PROCESS_MODE_ALWAYS

	_reading_title = Label.new()
	_reading_title.name = "ReadingTitle"
	_reading_title.text = ""
	_reading_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reading_title.custom_minimum_size = Vector2(0, 50)
	reading_vbox.add_child(_reading_title)

	_reading_content = RichTextLabel.new()
	_reading_content.name = "ReadingContent"
	_reading_content.text = ""
	_reading_content.bbcode_enabled = true
	_reading_content.scroll_following = true
	_reading_content.custom_minimum_size = Vector2(600, 350)
	reading_vbox.add_child(_reading_content)

	_reading_close_btn = Button.new()
	_reading_close_btn.name = "ReadingCloseBtn"
	_reading_close_btn.text = "[ 关闭 ]"
	_reading_close_btn.pressed.connect(_on_reading_close)
	_reading_close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	reading_vbox.add_child(_reading_close_btn)

func _connect_signals() -> void:
	if _player != null:
		if _player.has_signal("stamina_exhausted"):
			_player.stamina_exhausted.connect(_on_player_stamina_exhausted)
		if _player.has_signal("debuff_active"):
			_player.debuff_active.connect(_on_player_debuff_active)
		if _player.has_signal("game_over_starvation"):
			_player.game_over_starvation.connect(_on_game_over_starvation)

	if _game_manager != null:
		if _game_manager.has_signal("forbidden_period_start"):
			_game_manager.forbidden_period_start.connect(_on_forbidden_period_start)
		if _game_manager.has_signal("forbidden_period_end"):
			_game_manager.forbidden_period_end.connect(_on_forbidden_period_end)
		if _game_manager.has_signal("lore_read"):
			_game_manager.lore_read.connect(_on_lore_read)
		if _game_manager.has_signal("objective_updated"):
			_game_manager.objective_updated.connect(_on_objective_updated)

func _process(delta: float) -> void:
	_update_stamina()
	_update_survival()
	_update_clock()
	_update_warning_flash(delta)

func _update_stamina() -> void:
	if _player == null:
		return
	var stamina: float = _player.get("_stamina") if "_stamina" in _player else 100.0
	var stamina_max: float = _player.get("_stamina_max") if "_stamina_max" in _player else 100.0
	var temp_bonus: float = _player.get("_stamina_temp_max_bonus") if "_stamina_temp_max_bonus" in _player else 0.0
	var effective_max: float = stamina_max + temp_bonus

	_stamina_bar.max_value = max(effective_max, 1.0)
	_stamina_bar.value = clamp(stamina, 0.0, effective_max)

	if stamina < 30.0:
		_stamina_bar.modulate = Color.RED
	else:
		_stamina_bar.modulate = Color.GREEN

func _update_survival() -> void:
	if _player == null:
		return
	var hydration: float = _player.get("_hydration") if "_hydration" in _player else 80.0
	var satiety: float = _player.get("_satiety") if "_satiety" in _player else 80.0

	_hydration_bar.value = clamp(hydration, 0.0, 100.0)
	_satiety_bar.value = clamp(satiety, 0.0, 100.0)

	if hydration < 20.0:
		_hydration_bar.modulate = Color.RED
	else:
		_hydration_bar.modulate = Color.BLUE

	if satiety < 20.0:
		_satiety_bar.modulate = Color.RED
	else:
		_satiety_bar.modulate = Color(1, 0.5, 0)

func _update_clock() -> void:
	if _game_manager == null:
		return
	var game_time: String = _game_manager.get("game_time_string") if "game_time_string" in _game_manager else "??:??"
	_clock_label.text = game_time

	var is_forbidden: bool = _game_manager.get("is_forbidden_period") if "is_forbidden_period" in _game_manager else false
	if is_forbidden:
		_clock_label.modulate = Color.RED
	else:
		_clock_label.modulate = Color.WHITE

func _on_player_debuff_active(buff_type: String) -> void:
	_show_warning("状态异常: %s" % buff_type)

func _on_player_stamina_exhausted() -> void:
	_show_warning("体力耗尽！")

func _on_game_over_starvation() -> void:
	_show_warning("饥饿过度！游戏结束")

func _show_warning(msg: String) -> void:
	_is_warning_active = true
	_warning_flash_timer = 0.0
	_warning_label.text = msg
	_warning_label.modulate = Color(1, 0, 0, 1)

func _update_warning_flash(delta: float) -> void:
	if not _is_warning_active:
		return
	_warning_flash_timer += delta
	var alpha: float = abs(sin(_warning_flash_timer * 6.0))
	_warning_label.modulate = Color(_warning_color.r, _warning_color.g, _warning_color.b, alpha)
	if _warning_flash_timer > 3.0:
		_is_warning_active = false
		_warning_label.modulate = Color(1, 0, 0, 0)

func _on_forbidden_period_start() -> void:
	_show_warning("禁对视时段开始！ 23:00-07:00")

func _on_forbidden_period_end() -> void:
	_show_warning("禁对视时段结束")

func show_route_hint(route: String) -> void:
	_route_hint_label.text = "路线: %s" % route
	_route_hint_label.modulate = Color(1, 0.8, 0, 1)

func hide_route_hint() -> void:
	_route_hint_label.modulate = Color(1, 0.8, 0, 0)

func update_counter_state_hint(hint: String) -> void:
	_show_warning(hint)

# ============================================================
# ReadingPanel 剧情文本阅读
# ============================================================

func show_reading_panel(title: String, content: String) -> void:
	_reading_title.text = title
	_reading_content.text = content
	_reading_panel.visible = true
	get_tree().paused = true
	print("[HUD] 显示阅读面板: %s" % title)

func _on_reading_close() -> void:
	_reading_panel.visible = false
	get_tree().paused = false
	print("[HUD] 关闭阅读面板")

func _on_lore_read(item_id: String, content: String) -> void:
	var title_map: Dictionary = {
		"sister_phone": "妹妹的手机备忘录",
		"diary_page": "日记残页",
		"resident_note": "住户遗书",
		"childhood_photo": "童年合照"
	}
	var title: String = title_map.get(item_id, "剧情道具")
	show_reading_panel(title, content)

func _on_objective_updated(objective: String) -> void:
	_objective_label.text = objective
