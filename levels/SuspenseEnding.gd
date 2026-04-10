extends CanvasLayer

# ============================================================
# 悬念结局：细思极恐的收尾
# GDD：
# - 电梯门缓缓关上，众人以为终于逃出生天
# - 音效骤停
# - 姐姐低头看规则纸条，多了一行字："她在说谎"
# - 画面切黑，Demo 结束
# ============================================================

enum EndingState { ELEVATOR, SILENCE, PAPER_APPEAR, TEXT_REVEAL, LIAR_REVEAL, BLACKOUT, DONE }

var _state: EndingState = EndingState.ELEVATOR
var _bg: ColorRect
var _elevator_text: Label
var _paper: ColorRect
var _paper_text: Label
var _liar_label: Label
var _final_label: Label

func _ready() -> void:
	_build_ui()
	_start_ending_sequence()
	print("[SuspenseEnding] 悬疑结局开始")

func _build_ui() -> void:
	# 全黑背景
	_bg = ColorRect.new()
	_bg.name = "BlackBg"
	_bg.color = Color(0, 0, 0, 1.0)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	# 电梯内旁白
	_elevator_text = Label.new()
	_elevator_text.name = "ElevatorText"
	_elevator_text.text = ""
	_elevator_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_elevator_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_elevator_text.modulate = Color(0.7, 0.7, 0.7, 0.0)
	_elevator_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_elevator_text.custom_minimum_size = Vector2(500, 200)
	add_child(_elevator_text)
	_elevator_text.set_anchors_preset(Control.PRESET_CENTER)
	_elevator_text.offset_left = -250
	_elevator_text.offset_right = 250
	_elevator_text.offset_top = -100
	_elevator_text.offset_bottom = 100

	# 纸条
	_paper = ColorRect.new()
	_paper.name = "Paper"
	_paper.color = Color(0.95, 0.93, 0.85, 1.0)
	_paper.custom_minimum_size = Vector2(340, 220)
	_paper.modulate.a = 0.0
	add_child(_paper)
	_paper.set_anchors_preset(Control.PRESET_CENTER)
	_paper.offset_left = -170
	_paper.offset_right = 170
	_paper.offset_top = -200
	_paper.offset_bottom = 20

	# 纸条上的文字
	_paper_text = Label.new()
	_paper_text.name = "PaperText"
	_paper_text.text = ""
	_paper_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_paper_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_paper_text.modulate = Color(0.15, 0.12, 0.10, 1.0)
	_paper_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	_paper_text.custom_minimum_size = Vector2(300, 180)
	_paper.add_child(_paper_text)
	_paper_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	_paper_text.offset_left = 20
	_paper_text.offset_right = -20
	_paper_text.offset_top = 20
	_paper_text.offset_bottom = -20

	# "她在说谎" 最终一击
	_liar_label = Label.new()
	_liar_label.name = "LiarLabel"
	_liar_label.text = ""
	_liar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_liar_label.modulate = Color(0.8, 0.0, 0.0, 0.0)
	_liar_label.custom_minimum_size = Vector2(400, 60)
	add_child(_liar_label)
	_liar_label.set_anchors_preset(Control.PRESET_CENTER)
	_liar_label.offset_left = -200
	_liar_label.offset_right = 200
	_liar_label.offset_top = 60
	_liar_label.offset_bottom = 120

	# Demo 结束字幕
	_final_label = Label.new()
	_final_label.name = "FinalLabel"
	_final_label.text = ""
	_final_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_final_label.modulate = Color(0.5, 0.5, 0.5, 0.0)
	_final_label.custom_minimum_size = Vector2(600, 60)
	add_child(_final_label)
	_final_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_final_label.offset_bottom = -80
	_final_label.offset_top = -140

func _start_ending_sequence() -> void:
	get_tree().paused = true

	# 第一阶段：电梯内旁白
	_state = EndingState.ELEVATOR
	_elevator_text.text = "电梯缓缓运行……\n\n众人以为终于逃出生天了。"
	var tween1 := create_tween()
	tween1.tween_property(_elevator_text, "modulate:a", 1.0, 1.5)
	await tween1.finished

	await get_tree().create_timer(3.0).timeout

	# 第二阶段：音效骤停（文字暗示）
	_state = EndingState.SILENCE
	var tween2 := create_tween()
	tween2.tween_property(_elevator_text, "modulate:a", 0.0, 0.5)
	await tween2.finished

	await get_tree().create_timer(1.5).timeout

	# 第三阶段：纸条浮现
	_state = EndingState.PAPER_APPEAR
	var tween3 := create_tween()
	tween3.tween_property(_paper, "modulate:a", 1.0, 1.5)
	await tween3.finished

	# 第四阶段：纸条文字逐行显示
	_state = EndingState.TEXT_REVEAL
	var lines: Array = [
		"姐姐习惯性地低头",
		"看了一眼手里的规则纸条。",
		"",
		"纸条上的字都认识……",
		"",
		"但最下面……",
		"多了一行。",
	]
	var full_text: String = ""
	for line: String in lines:
		await get_tree().create_timer(0.6).timeout
		full_text += line + "\n"
		_paper_text.text = full_text

	await get_tree().create_timer(2.0).timeout

	# 第五阶段：关键一击——"她在说谎"
	_state = EndingState.LIAR_REVEAL
	_liar_label.text = "她 在 说 谎。"
	var tween4 := create_tween()
	tween4.tween_property(_liar_label, "modulate:a", 1.0, 1.0)
	await tween4.finished

	await get_tree().create_timer(3.0).timeout

	# 第六阶段：一切切黑
	_state = EndingState.BLACKOUT
	var tween5 := create_tween()
	tween5.tween_property(_paper, "modulate:a", 0.0, 0.8)
	tween5.parallel().tween_property(_liar_label, "modulate:a", 0.0, 0.8)
	await tween5.finished

	await get_tree().create_timer(2.0).timeout

	# 第七阶段：Demo 结束
	_state = EndingState.DONE
	_final_label.text = "Demo 结束"
	var tween6 := create_tween()
	tween6.tween_property(_final_label, "modulate:a", 1.0, 2.0)
	await tween6.finished

	await get_tree().create_timer(1.5).timeout
	_show_return_button()

func _show_return_button() -> void:
	var btn := Button.new()
	btn.name = "ReturnBtn"
	btn.text = "[ 返回主菜单 ]"
	btn.custom_minimum_size = Vector2(200, 50)
	add_child(btn)
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn.offset_bottom = -20
	btn.offset_top = -70
	btn.offset_left = -100
	btn.offset_right = 100
	btn.pressed.connect(_on_return_pressed)
	var tween := create_tween()
	tween.tween_property(btn, "modulate:a", 1.0, 1.0)

func _on_return_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
