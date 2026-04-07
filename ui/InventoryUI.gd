extends CanvasLayer

const ItemClass = preload("res://items/Item.gd")

var _panel: Panel
var _grid_container: GridContainer
var _detail_name: Label
var _detail_type: Label
var _detail_desc: Label
var _use_button: Button

var _slot_buttons: Array[Button] = []
var _selected_item: ItemClass = null
var _player: Node = null

const SLOT_COUNT: int = 20
const COLUMNS: int = 5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_tree().get_first_node_in_group("player")
	_build_ui()
	_connect_signals()
	print("[InventoryUI] 动态UI已生成，按 Tab 打开背包")

func _build_ui() -> void:
	# === 背景面板 ===
	_panel = Panel.new()
	_panel.name = "Panel"
	_panel.visible = false
	add_child(_panel)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(700, 400)

	# === 标题 ===
	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "背包"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(700, 30)
	title.position = Vector2(0, 0)
	_panel.add_child(title)

	# === 关闭提示 ===
	var close_hint := Label.new()
	close_hint.name = "CloseHint"
	close_hint.text = "按 Tab 关闭"
	close_hint.position = Vector2(0, 370)
	close_hint.modulate = Color(0.5, 0.5, 0.5, 1)
	_panel.add_child(close_hint)

	# === 道具格子 GridContainer ===
	_grid_container = GridContainer.new()
	_grid_container.name = "GridContainer"
	_grid_container.columns = COLUMNS
	_grid_container.position = Vector2(50, 50)
	_grid_container.custom_minimum_size = Vector2(600, 200)
	_panel.add_child(_grid_container)

	for i: int in SLOT_COUNT:
		var slot := Button.new()
		slot.name = "Slot_%d" % i
		slot.text = ""
		slot.custom_minimum_size = Vector2(100, 50)
		slot.pressed.connect(_on_slot_pressed.bind(i))
		_grid_container.add_child(slot)
		_slot_buttons.append(slot)

	# === 详情面板（格子右侧） ===
	var detail_panel := Panel.new()
	detail_panel.name = "ItemDetailPanel"
	detail_panel.position = Vector2(50, 270)
	detail_panel.custom_minimum_size = Vector2(600, 90)
	_panel.add_child(detail_panel)

	_detail_name = Label.new()
	_detail_name.name = "NameLabel"
	_detail_name.text = ""
	_detail_name.position = Vector2(10, 5)
	_detail_name.custom_minimum_size = Vector2(580, 25)
	detail_panel.add_child(_detail_name)

	_detail_type = Label.new()
	_detail_type.name = "TypeLabel"
	_detail_type.text = ""
	_detail_type.position = Vector2(10, 30)
	_detail_type.modulate = Color(0.7, 0.7, 0.7, 1)
	detail_panel.add_child(_detail_type)

	_detail_desc = Label.new()
	_detail_desc.name = "DescriptionLabel"
	_detail_desc.text = ""
	_detail_desc.position = Vector2(10, 50)
	_detail_desc.custom_minimum_size = Vector2(580, 35)
	detail_panel.add_child(_detail_desc)

	_use_button = Button.new()
	_use_button.name = "UseButton"
	_use_button.text = "使用"
	_use_button.visible = false
	_use_button.position = Vector2(480, 3)
	_use_button.pressed.connect(_on_use_button_pressed)
	detail_panel.add_child(_use_button)

func _connect_signals() -> void:
	ItemSystem.inventory_changed.connect(_on_inventory_changed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		_toggle_inventory()

func _toggle_inventory() -> void:
	_panel.visible = not _panel.visible
	get_tree().paused = _panel.visible
	if _panel.visible:
		_panel.position = (get_viewport().get_visible_rect().size - _panel.custom_minimum_size) / 2.0
		_refresh_slots()
		_clear_detail()
	else:
		_clear_detail()

func _on_inventory_changed() -> void:
	if _panel.visible:
		_refresh_slots()

func _refresh_slots() -> void:
	var inventory: Array = ItemSystem.get_inventory()
	for i: int in SLOT_COUNT:
		if i < inventory.size():
			var item: ItemClass = inventory[i]
			_slot_buttons[i].text = item.display_name
			_slot_buttons[i].disabled = false
		else:
			_slot_buttons[i].text = ""
			_slot_buttons[i].disabled = true

func _on_slot_pressed(index: int) -> void:
	var inventory: Array = ItemSystem.get_inventory()
	if index >= inventory.size():
		_clear_detail()
		return
	var item: ItemClass = inventory[index]
	_selected_item = item
	_show_item_detail(item)

func _show_item_detail(item: ItemClass) -> void:
	_detail_name.text = item.display_name
	_detail_type.text = _get_type_string(item.item_type)
	_detail_desc.text = item.description
	_use_button.visible = not item.is_key_item

func _get_type_string(item_type: int) -> String:
	match item_type:
		0: return "[生存]"
		1: return "[智斗]"
		2: return "[规则]"
		3: return "[剧情]"
		_: return "[未知]"

func _on_use_button_pressed() -> void:
	if _selected_item == null:
		return
	ItemSystem.use_item(_selected_item.item_id, _player)
	_selected_item = null
	_clear_detail()

func _clear_detail() -> void:
	_detail_name.text = ""
	_detail_type.text = ""
	_detail_desc.text = ""
	_use_button.visible = false
	_selected_item = null
