extends CanvasLayer

enum EndingState { FADE_IN, PAPER_REVEAL, TEXT_REVEAL, FINAL_MESSAGE, DONE }

var _state: EndingState = EndingState.FADE_IN
var _paper: ColorRect
var _text_label: Label
var _final_label: Label
var _tween: Tween

func _ready() -> void:
	_build_ui()
	_start_ending_sequence()
	print("[SuspenseEnding] 悬疑结局开始")

func _build_ui() -> void:
	# 全黑背景
	var bg := ColorRect.new()
	bg.name = "BlackBg"
	bg.color = Color(0, 0, 0, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 纸条/便签（中间偏上）
	_paper = ColorRect.new()
	_paper.name = "Paper"
	_paper.color = Color(0.95, 0.93, 0.85, 1.0)
	_paper.custom_minimum_size = Vector2(320, 200)
	_paper.modulate.a = 0.0
	add_child(_paper)
	_paper.set_anchors_preset(Control.PRESET_CENTER)
	_paper.offset_left = -160
	_paper.offset_right = 160
	_paper.offset_top = -250
	_paper.offset_bottom = -50

	# 纸条上的文字
	_text_label = Label.new()
	_text_label.name = "PaperText"
	_text_label.text = "规则第三条："
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.modulate = Color(0.1, 0.1, 0.1, 1.0)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_text_label.custom_minimum_size = Vector2(280, 160)
	_paper.add_child(_text_label)
	_text_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_text_label.offset_left = 20
	_text_label.offset_right = -20
	_text_label.offset_top = 20
	_text_label.offset_bottom = -20

	# 最终字幕
	_final_label = Label.new()
	_final_label.name = "FinalLabel"
	_final_label.text = ""
	_final_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_label.modulate = Color(0.7, 0.7, 0.7, 0.0)
	_final_label.custom_minimum_size = Vector2(600, 60)
	add_child(_final_label)
	_final_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_final_label.offset_bottom = -100
	_final_label.offset_top = -160
	_final_label.custom_minimum_size = Vector2(600, 60)

func _start_ending_sequence() -> void:
	get_tree().paused = true

	# 第一阶段：淡入黑屏
	await get_tree().create_timer(1.5).timeout
	_state = EndingState.PAPER_REVEAL
	_reveal_paper()

func _reveal_paper() -> void:
	_state = EndingState.PAPER_REVEAL

	# 纸条淡入
	var tween := create_tween()
	tween.tween_property(_paper, "modulate:a", 1.0, 1.2)

	await tween.finished

	# 第二阶段：纸条上文字逐行出现
	_state = EndingState.TEXT_REVEAL
	_reveal_text_line_by_line()

func _reveal_text_line_by_line() -> void:
	var lines: Array = [
		"规则第三条：",
		"",
		"如果你看到金色的瞳孔，",
		"说明你已经被盯上了。",
		"",
		"不要逃跑，不要躲藏。",
		"直视它，它就会消失。",
		"",
		"...但如果它消失了，",
		"说明你姐姐已经... ",
		"",
		"...她说的每一句话...",
	]

	_text_label.text = ""
	var full_text: String = ""
	var index: int = 0

	for line: String in lines:
		await get_tree().create_timer(0.5).timeout
		full_text += line + "\n"
		_text_label.text = full_text
		index += 1

	# 最后一秒，添加"她说谎"
	await get_tree().create_timer(1.0).timeout

	var final_text: String = full_text + "\n[color=#cc0000]她说谎。[/color]"
	_text_label.text = final_text

	await get_tree().create_timer(2.5).timeout

	# 第三阶段：显示 Demo 结束字幕
	_show_final_message()

func _show_final_message() -> void:
	_state = EndingState.FINAL_MESSAGE

	var tween := create_tween()
	tween.tween_property(_final_label, "modulate:a", 1.0, 2.0)
	tween.tween_interval(2.0)
	tween.tween_property(_final_label, "text", "Demo 结束", 0.01)
	tween.tween_interval(1.5)

	await tween.finished

	# 添加返回主菜单按钮
	_show_return_button()

func _show_return_button() -> void:
	var btn := Button.new()
	btn.name = "ReturnBtn"
	btn.text = "[ 返回主菜单 ]"
	btn.custom_minimum_size = Vector2(200, 50)
	add_child(btn)
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn.offset_bottom = -30
	btn.offset_top = -80
	btn.pressed.connect(_on_return_pressed)

	var tween := create_tween()
	tween.tween_property(btn, "modulate:a", 1.0, 1.0)

func _on_return_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
