extends Node2D
class_name Level1Controller

signal entered_safe_room(room_name: String)
signal left_safe_room(room_name: String)
signal elevator_activated
signal game_over_triggered(reason: String)

@export var monster_1_path: NodePath = ^"Monsters/Monster_1"
@export var elevator_path: NodePath = ^"Elevator"

const ELEVATOR_CARDS_REQUIRED: int = 2
const ItemClass = preload("res://items/Item.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")

var _elevator_cards_collected: int = 0
var _sister_apartment_left: bool = false
var _current_safe_room: String = ""

var _player: Node = null
var _monster_1: Node = null
var _elevator: Node = null

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_monster_1 = get_node_or_null(monster_1_path)
	_elevator = get_node_or_null(elevator_path)

	_disable_monster_1_if_exists()
	_setup_areas()
	_spawn_all_level_items()
	print("[Level1Controller] Level1 就绪")

# ============================================================
# 全自动道具生成系统
# ============================================================

func _spawn_all_level_items() -> void:
	# 格式：(item_id, Vector2(x, y), Color)
	# 坐标以像素为单位，可根据实际地图尺寸调整
	var items: Array = [
		["flashlight",     Vector2(200, 300),  Color(1.0, 0.9, 0.3)],   # 手电筒 - 妹妹公寓内
		["rule_page_1",   Vector2(450, 300),  Color(0.8, 0.6, 0.2)],   # 规则残页一 - 走廊
		["water_bottle",  Vector2(700, 500),  Color(0.3, 0.6, 1.0)],   # 矿泉水 - 走廊
		["sister_phone",  Vector2(300, 600),  Color(0.9, 0.3, 0.9)],   # 妹妹手机 - 走廊深处
		["diary_page",    Vector2(900, 400),  Color(0.6, 0.3, 0.1)],   # 日记残页 - 房间内
	]

	for item_data in items:
		var item_id: String = item_data[0]
		var pos: Vector2 = item_data[1]
		var color: Color = item_data[2]
		_spawn_physical_item(item_id, pos, color)

func _spawn_physical_item(item_id: String, spawn_pos: Vector2, color: Color) -> void:
	# ★ 直接实例化脚本，脚本已挂载在此节点上
	var entity: Node = PhysicalItemClass.new()
	entity.name = "PhysItem_%s" % item_id
	entity.global_position = spawn_pos

	# ★ 直接属性赋值（不用 set()，更稳定）
	entity.item_id = item_id

	# ★ 碰撞层配置（让 Player 的 Area2D 能检测到）
	entity.collision_layer = 2
	entity.collision_mask = 0
	entity.monitorable = true

	# ★ 添加碰撞体
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	entity.add_child(collision)

	# ★ 添加视觉色块
	var visual := ColorRect.new()
	visual.color = color
	visual.size = Vector2(28, 28)
	visual.position = Vector2(-14, -14)
	entity.add_child(visual)

	# ★ 加入场景
	add_child(entity)
	print("[Level1Controller] 实体道具已生成: %s @ %v" % [item_id, spawn_pos])

# ============================================================
# 区域检测
# ============================================================

func _setup_areas() -> void:
	var sister_apartment: Area2D = get_node_or_null("Rooms/SisterApartment")
	var corridor: Area2D = get_node_or_null("Rooms/Corridor")
	var locked_room: Area2D = get_node_or_null("Rooms/LockedRoom_1")

	if sister_apartment and sister_apartment.has_signal("body_entered"):
		sister_apartment.body_entered.connect(_on_sister_apartment_entered)
		sister_apartment.body_exited.connect(_on_sister_apartment_exited)

	if corridor and corridor.has_signal("body_entered"):
		corridor.body_entered.connect(_on_corridor_entered)

	if locked_room:
		if locked_room.has_signal("body_entered"):
			locked_room.body_entered.connect(_on_locked_room_entered)
		if locked_room.has_signal("body_exited"):
			locked_room.body_exited.connect(_on_locked_room_exited)

# ============================================================
# 1. 玩家离开妹妹公寓 → 激活 Monster_1
# ============================================================

func _on_sister_apartment_entered(body: Node) -> void:
	if body == _player:
		_current_safe_room = "SisterApartment"
		_player.is_in_safe_room = true
		entered_safe_room.emit("SisterApartment")
		print("[Level1Controller] 玩家进入妹妹公寓（安全区）")

func _on_sister_apartment_exited(body: Node) -> void:
	if body == _player:
		_player.is_in_safe_room = false
		_current_safe_room = ""
		left_safe_room.emit("SisterApartment")
		print("[Level1Controller] 玩家离开妹妹公寓")
		if not _sister_apartment_left:
			_sister_apartment_left = true
			_activate_monster_1()

# ============================================================
# 2. 走廊
# ============================================================

func _on_corridor_entered(body: Node) -> void:
	if body == _player:
		_player.is_in_safe_room = false
		print("[Level1Controller] 玩家进入走廊")

# ============================================================
# 3. 带锁房间
# ============================================================

func _on_locked_room_entered(body: Node) -> void:
	if body == _player:
		_current_safe_room = "LockedRoom_1"
		_player.is_in_safe_room = true
		entered_safe_room.emit("LockedRoom_1")
		print("[Level1Controller] 玩家进入带锁房间（安全区）")

func _on_locked_room_exited(body: Node) -> void:
	if body == _player:
		_current_safe_room = ""
		_player.is_in_safe_room = false
		left_safe_room.emit("LockedRoom_1")

# ============================================================
# 4. 电梯权限卡
# ============================================================

func on_elevator_card_collected() -> void:
	_elevator_cards_collected += 1
	print("[Level1Controller] 电梯权限卡: %d/%d" % [_elevator_cards_collected, ELEVATOR_CARDS_REQUIRED])
	if _elevator_cards_collected >= ELEVATOR_CARDS_REQUIRED:
		_activate_elevator()

func _activate_elevator() -> void:
	if _elevator != null and _elevator.has_method("activate"):
		_elevator.activate()
		elevator_activated.emit()
		print("[Level1Controller] 电梯已激活")

# ============================================================
# 5. 怪物激活/禁用
# ============================================================

func _activate_monster_1() -> void:
	if _monster_1 != null:
		_monster_1.set_process(true)
		_monster_1.set_physics_process(true)
		if "current_state" in _monster_1:
			_monster_1.current_state = _monster_1.State.PATROL
		print("[Level1Controller] Monster_1 已激活")

func _disable_monster_1_if_exists() -> void:
	if _monster_1 != null:
		_monster_1.set_process(false)
		_monster_1.set_physics_process(false)

# ============================================================
# 6. 游戏结束
# ============================================================

func trigger_game_over(reason: String) -> void:
	game_over_triggered.emit(reason)
	GameManager.trigger_game_over(reason)
	print("[Level1Controller] 游戏结束，原因: %s" % reason)

# ============================================================
# 对外接口
# ============================================================

func get_player() -> Node:
	return _player

func get_current_safe_room() -> String:
	return _current_safe_room

func is_in_safe_room() -> bool:
	return _current_safe_room != ""
