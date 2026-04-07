extends Control

var _title_label: Label
var _start_btn: Button
var _quit_btn: Button
var _subtitle_label: Label

func _ready() -> void:
	_build_ui()
	print("[MainMenu] 主菜单已生成")

func _build_ui() -> void:
	# 全屏背景
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.02, 0.02, 0.04, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 垂直居中容器
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.custom_minimum_size = Vector2(400, 300)
	add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	# ★ 锚点计算兜底：确保容器绝对居中
	vbox.position = (get_viewport_rect().size - vbox.custom_minimum_size) / 2.0

	# 顶部留白
	var spacer_top := Control.new()
	spacer_top.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(spacer_top)

	# 标题
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "公寓怪谈"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.85, 0.75, 0.65, 1.0)
	_title_label.custom_minimum_size = Vector2(500, 80)
	vbox.add_child(_title_label)

	# 副标题
	_subtitle_label = Label.new()
	_subtitle_label.name = "SubtitleLabel"
	_subtitle_label.text = "Apartment Ghost Story"
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.modulate = Color(0.5, 0.5, 0.55, 1.0)
	_subtitle_label.custom_minimum_size = Vector2(500, 40)
	vbox.add_child(_subtitle_label)

	# 留白
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)

	# 开始游戏按钮
	_start_btn = Button.new()
	_start_btn.name = "StartButton"
	_start_btn.text = "[ 开始游戏 ]"
	_start_btn.custom_minimum_size = Vector2(240, 50)
	_start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(_start_btn)

	# 退出游戏按钮
	_quit_btn = Button.new()
	_quit_btn.name = "QuitButton"
	_quit_btn.text = "[ 退出游戏 ]"
	_quit_btn.custom_minimum_size = Vector2(240, 50)
	_quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(_quit_btn)

func _on_start_pressed() -> void:
	print("[MainMenu] 开始游戏...")
	get_tree().change_scene_to_file("res://levels/RoomScene.tscn")

func _on_quit_pressed() -> void:
	print("[MainMenu] 退出游戏...")
	get_tree().quit()
