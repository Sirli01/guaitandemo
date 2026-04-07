extends CanvasLayer

signal restart_requested

var _panel: Panel
var _title_label: Label
var _reason_label: Label
var _restart_btn: Button

var _is_visible: bool = false

func _ready() -> void:
	_build_ui()
	_connect_signals()
	print("[GameOverUI] 已初始化")

func _build_ui() -> void:
	_panel = Panel.new()
	_panel.name = "GameOverPanel"
	_panel.visible = false
	add_child(_panel)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.color = Color(0.0, 0.0, 0.0, 0.92)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	var spacer1 := Control.new()
	spacer1.custom_minimum_size = Vector2(0, 180)
	vbox.add_child(spacer1)

	_title_label = Label.new()
	_title_label.name = "GameOverTitle"
	_title_label.text = "[ GAME OVER ]"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.9, 0.1, 0.1, 1.0)
	_title_label.custom_minimum_size = Vector2(600, 60)
	vbox.add_child(_title_label)

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer2)

	_reason_label = Label.new()
	_reason_label.name = "ReasonLabel"
	_reason_label.text = ""
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.modulate = Color(0.7, 0.5, 0.5, 1.0)
	_reason_label.custom_minimum_size = Vector2(600, 40)
	vbox.add_child(_reason_label)

	var spacer3 := Control.new()
	spacer3.custom_minimum_size = Vector2(0, 60)
	vbox.add_child(spacer3)

	_restart_btn = Button.new()
	_restart_btn.name = "RestartButton"
	_restart_btn.text = "[ 重新开始 ]"
	_restart_btn.custom_minimum_size = Vector2(200, 50)
	_restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(_restart_btn)

func _connect_signals() -> void:
	GameManager.game_over_triggered.connect(_on_game_over_triggered)

func show_game_over(reason: String) -> void:
	_reason_label.text = reason
	_panel.visible = true
	_is_visible = true
	get_tree().paused = true
	print("[GameOverUI] 游戏结束: %s" % reason)

func _on_game_over_triggered(reason: String) -> void:
	show_game_over(reason)

func _on_restart_pressed() -> void:
	_panel.visible = false
	_is_visible = false
	get_tree().paused = false
	restart_requested.emit()
	print("[GameOverUI] 重新开始请求")
	get_tree().reload_current_scene()
