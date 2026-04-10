extends CanvasLayer

signal restart_requested

var _panel: Panel
var _title_label: Label
var _ending_text: RichTextLabel
var _restart_btn: Button

var _is_visible: bool = false

func _ready() -> void:
	_build_ui()
	_connect_signals()
	print("[EndingUI] 已初始化")

func _build_ui() -> void:
	_panel = Panel.new()
	_panel.name = "EndingPanel"
	_panel.visible = false
	add_child(_panel)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Panel 没有 color 属性，用 StyleBoxFlat 设置背景色
	var light_style := StyleBoxFlat.new()
	light_style.bg_color = Color(0.95, 0.95, 0.95, 1.0)
	_panel.add_theme_stylebox_override("panel", light_style)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 120)
	vbox.add_child(spacer1)

	_title_label = Label.new()
	_title_label.name = "EndingTitle"
	_title_label.text = ""
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.1, 0.1, 0.1, 1.0)
	_title_label.custom_minimum_size = Vector2(700, 60)
	vbox.add_child(_title_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer2)

	_ending_text = RichTextLabel.new()
	_ending_text.name = "EndingText"
	_ending_text.text = ""
	_ending_text.bbcode_enabled = true
	_ending_text.scroll_following = true
	_ending_text.custom_minimum_size = Vector2(700, 300)
	vbox.add_child(_ending_text)

	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer3)

	_restart_btn = Button.new()
	_restart_btn.name = "RestartButton"
	_restart_btn.text = "[ 重新开始 ]"
	_restart_btn.custom_minimum_size = Vector2(200, 50)
	_restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(_restart_btn)

func _connect_signals() -> void:
	pass

func show_ending(ending_type: String) -> void:
	match ending_type:
		"hidden_ending":
			_show_hidden_ending()
		"default_ending":
			_show_default_ending()
		_:
			_show_default_ending()
	_panel.visible = true
	_is_visible = true
	get_tree().paused = true
	print("[EndingUI] 显示结局: %s" % ending_type)

func _show_hidden_ending() -> void:
	var dark_style := StyleBoxFlat.new()
	dark_style.bg_color = Color(0.05, 0.05, 0.08, 1.0)
	_panel.add_theme_stylebox_override("panel", dark_style)
	_title_label.text = "[ 隐藏结局：灵魂互换 ]"
	_title_label.modulate = Color(0.9, 0.85, 0.7, 1.0)
	_ending_text.bbcode_enabled = true
	_ending_text.text = """[color=#e8d8b0]你和阿柚终于找到了彼此。
在规则残页和剧情道具的指引下，
你们成功破解了公寓的秘密，
并找到了灵魂互换的方法。

姐姐躺在床上，睁开眼睛。
瞳孔中的金色光芒已经消失——
那是属于"林晚"的标志。

而你，终于回到了自己的身体里。
公寓的诅咒终结了。
但那些在黑暗中徘徊的日子，
将永远成为你们共同的记忆。

—— 隐藏结局 · 完 ——[/color]"""

func _show_default_ending() -> void:
	_title_label.text = "[ 结局 ]"
	_title_label.modulate = Color(0.2, 0.2, 0.2, 1.0)
	_ending_text.bbcode_enabled = true
	_ending_text.text = """[color=#333333]你在规定时间内未能找到所有线索。
灵魂互换未能完成，
你和姐姐依然困在这具身体里。

公寓依然被黑暗笼罩。
下一次禁对视时段开始时，
你将再次面临选择。

—— 默认结局 · 完 ——[/color]"""

func _on_restart_pressed() -> void:
	_panel.visible = false
	_is_visible = false
	get_tree().paused = false
	restart_requested.emit()
	print("[EndingUI] 重新开始请求")
	get_tree().reload_current_scene()
