extends Node

# ============================================================
# 信号定义
# ============================================================
signal dialogue_started()
signal dialogue_finished()
signal dialogue_line_finished()
signal character_typed

# ============================================================
# 状态
# ============================================================
var _is_active: bool = false
var _current_speaker: String = ""
var _current_lines: Array[String] = []
var _current_line_index: int = 0
var _current_char_index: int = 0
var _full_line_displayed: bool = false
var _type_timer: float = 0.0

const CHAR_DELAY: float = 0.05  # 每字 0.05 秒

# ============================================================
# UI 节点引用
# ============================================================
var _dialogue_box: Control = null
var _speaker_label: Label = null
var _content_label: RichTextLabel = null
var _continue_prompt: Label = null

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_build_dialogue_box()
	print("[DialogueSystem] 就绪")

func _process(delta: float) -> void:
	if not _is_active:
		return
	_type_timer += delta
	if _type_timer >= CHAR_DELAY:
		_type_timer = 0.0
		_advance_character()

# ============================================================
# 构建对话面板
# ============================================================

func _build_dialogue_box() -> void:
	_dialogue_box = Control.new()
	_dialogue_box.name = "DialogueBox"
	_dialogue_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialogue_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_box.visible = false
	add_child(_dialogue_box)

	# 底层半透明黑底
	var bg := ColorRect.new()
	bg.name = "DialogueBG"
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialogue_box.add_child(bg)

	# 底部面板（约屏幕下方 25%）
	var panel := Panel.new()
	panel.name = "DialoguePanel"
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 0
	panel.offset_right = 0
	panel.offset_bottom = 200
	panel.offset_top = 0
	_dialogue_box.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(vbox)

	# 说话人
	_speaker_label = Label.new()
	_speaker_label.name = "SpeakerLabel"
	_speaker_label.text = ""
	_speaker_label.offset_top = 10
	_speaker_label.offset_left = 20
	_speaker_label.offset_right = 600
	_speaker_label.offset_bottom = 50
	_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6, 1.0))
	vbox.add_child(_speaker_label)

	# 对话内容
	_content_label = RichTextLabel.new()
	_content_label.name = "ContentLabel"
	_content_label.bbcode_enabled = false
	_content_label.text = ""
	_content_label.offset_left = 20
	_content_label.offset_right = 780
	_content_label.offset_bottom = 160
	_content_label.scroll_following = false
	vbox.add_child(_content_label)

	# 继续提示
	_continue_prompt = Label.new()
	_continue_prompt.name = "ContinuePrompt"
	_continue_prompt.text = "▶"
	_continue_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_continue_prompt.modulate = Color(1, 1, 1, 0)
	_continue_prompt.offset_left = 680
	_continue_prompt.offset_right = 780
	_continue_prompt.offset_bottom = 200
	vbox.add_child(_continue_prompt)

# ============================================================
# 外部接口
# ============================================================

func show_dialogue(speaker: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return
	_is_active = true
	_current_speaker = speaker
	_current_lines = lines
	_current_line_index = 0
	_full_line_displayed = false
	_type_timer = 0.0

	_speaker_label.text = speaker
	_dialogue_box.visible = true
	_full_line_displayed = false
	_current_char_index = 0
	_content_label.text = ""

	# 继续提示闪烁
	var tween := create_tween()
	tween.set_loops(-1)
	tween.tween_property(_continue_prompt, "modulate:a", 0.3, 0.5)
	tween.tween_property(_continue_prompt, "modulate:a", 1.0, 0.5)

	dialogue_started.emit()
	_apply_player_speed_penalty(true)

func skip_or_advance() -> void:
	if not _is_active:
		return

	if not _full_line_displayed:
		# 直接显示完整行
		_full_line_displayed = true
		_current_char_index = _current_lines[_current_line_index].length()
		_content_label.text = _current_lines[_current_line_index]
		dialogue_line_finished.emit()
		return

	# 显示下一行
	_current_line_index += 1
	if _current_line_index >= _current_lines.size():
		_close_dialogue()
		return

	_full_line_displayed = false
	_current_char_index = 0
	_content_label.text = ""
	dialogue_line_finished.emit()

# ============================================================
# 内部逻辑
# ============================================================

func _advance_character() -> void:
	if not _is_active:
		return
	if _full_line_displayed:
		return

	var line: String = _current_lines[_current_line_index]
	_current_char_index += 1

	if _current_char_index >= line.length():
		_full_line_displayed = true
		_content_label.text = line
		dialogue_line_finished.emit()
		return

	var partial: String = line.substr(0, _current_char_index)
	_content_label.text = partial

func _close_dialogue() -> void:
	_is_active = false
	_dialogue_box.visible = false
	dialogue_finished.emit()
	_apply_player_speed_penalty(false)
	print("[DialogueSystem] 对话结束")

func _apply_player_speed_penalty(enabled: bool) -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	for p in players:
		if p.has_method("set_dialogue_active"):
			p.set_dialogue_active(enabled)

# ============================================================
# 输入处理
# ============================================================

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		skip_or_advance()

# ============================================================
# 查询
# ============================================================

func is_dialogue_active() -> bool:
	return _is_active
