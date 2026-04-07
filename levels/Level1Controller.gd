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
const DoorClass = preload("res://items/Door.gd")
const HidingSpotClass = preload("res://items/HidingSpot.gd")
const ElevatorClass = preload("res://items/Elevator.gd")
const NPCClass = preload("res://items/NPC.gd")

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
	_build_level_geometry()
	_player = get_tree().get_first_node_in_group("player")
	_monster_1 = get_node_or_null(monster_1_path)
	_elevator = get_node_or_null(elevator_path)
	_disable_monster_1_if_exists()
	_setup_areas()
	_spawn_all_level_items()
	_spawn_environment_entities()
	print("[Level1Controller] Level1 就绪")

# ============================================================
# 程序化几何生成（墙壁/地板/房间布局）
# ============================================================

func _build_level_geometry() -> void:
	var wall_color: Color = Color(0.25, 0.2, 0.2, 1.0)

	# === 妹妹公寓房间（左侧） ===
	_spawn_wall_rect(Vector2(50, 200), Vector2(200, 20), wall_color)   # 上墙
	_spawn_wall_rect(Vector2(50, 450), Vector2(200, 20), wall_color)   # 下墙
	_spawn_wall_rect(Vector2(50, 200), Vector2(20, 270), wall_color)  # 左墙
	_spawn_wall_rect(Vector2(230, 200), Vector2(20, 270), wall_color) # 右墙

	# === 走廊（中间） ===
	_spawn_wall_rect(Vector2(250, 200), Vector2(300, 20), wall_color)  # 走廊上墙
	_spawn_wall_rect(Vector2(250, 450), Vector2(300, 20), wall_color) # 走廊下墙

	# === 带锁房间（右侧） ===
	_spawn_wall_rect(Vector2(560, 150), Vector2(180, 20), wall_color)  # 上墙
	_spawn_wall_rect(Vector2(560, 500), Vector2(180, 20), wall_color)  # 下墙
	_spawn_wall_rect(Vector2(720, 150), Vector2(20, 370), wall_color)  # 右墙

	# 走廊右侧开口连接带锁房间

	# === 门（妹妹公寓出口） ===
	_spawn_door(Vector2(230, 300), "door_sister_to_corridor")

	# === 柜子/躲藏点（走廊） ===
	_spawn_hiding_spot(Vector2(380, 340), "hiding_corridor_1")

	# === 电梯（走廊尽头） ===
	_spawn_elevator(Vector2(500, 320), 1, 2, "ayou_id_card")

	print("[Level1Controller] 几何布局已生成")

func _spawn_wall_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var wall := StaticBody2D.new()
	wall.name = "Wall_%s" % pos
	wall.global_position = pos
	wall.collision_layer = 1
	wall.collision_mask = 0
	add_child(wall)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	wall.add_child(collision)

	var rect := ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = Vector2(-size.x / 2, -size.y / 2)
	wall.add_child(rect)

func _spawn_door(pos: Vector2, door_id: String) -> void:
	var door: Node = DoorClass.new()
	door.name = "Door_%s" % door_id
	door.global_position = pos
	door.door_id = door_id
	door.collision_layer = 2
	door.collision_mask = 0
	door.monitorable = true
	add_child(door)
	print("[Level1Controller] 门已生成: %s @ %v" % [door_id, pos])

func _spawn_hiding_spot(pos: Vector2, spot_id: String) -> void:
	var spot: Node = HidingSpotClass.new()
	spot.name = "HidingSpot_%s" % spot_id
	spot.global_position = pos
	spot.collision_layer = 2
	spot.collision_mask = 0
	spot.monitorable = true
	add_child(spot)

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 24.0
	collision.shape = shape
	spot.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color(0.4, 0.3, 0.2, 0.8)
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	spot.add_child(visual)

	print("[Level1Controller] 躲藏点已生成: %s @ %v" % [spot_id, pos])

func _spawn_elevator(pos: Vector2, floor_num: int, target: int, required_item: String) -> void:
	var elev: Node = ElevatorClass.new()
	elev.name = "Elevator_Floor%d" % floor_num
	elev.global_position = pos
	elev.floor_number = floor_num
	elev.target_floor = target
	elev.required_item_id = required_item
	elev.collision_layer = 2
	elev.collision_mask = 0
	elev.monitorable = true
	add_child(elev)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(50, 50)
	collision.shape = shape
	elev.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color(0.6, 0.5, 0.3, 1.0)
	visual.size = Vector2(46, 46)
	visual.position = Vector2(-23, -23)
	elev.add_child(visual)

	print("[Level1Controller] 电梯已生成: floor %d -> %d" % [floor_num, target])

# ============================================================
# 全自动道具生成系统
# ============================================================

func _spawn_all_level_items() -> void:
	var items: Array = [
		["flashlight",    Vector2(150, 320), Color(1.0, 0.9, 0.3)],
		["rule_page_1",  Vector2(320, 300), Color(0.8, 0.6, 0.2)],
		["water_bottle", Vector2(420, 380), Color(0.3, 0.6, 1.0)],
		["sister_phone", Vector2(180, 400), Color(0.9, 0.3, 0.9)],
	]
	for item_data in items:
		var item_id: String = item_data[0]
		var pos: Vector2 = item_data[1]
		var color: Color = item_data[2]
		_spawn_physical_item(item_id, pos, color)

func _spawn_physical_item(item_id: String, spawn_pos: Vector2, color: Color) -> void:
	var entity: Node = PhysicalItemClass.new()
	entity.name = "PhysItem_%s" % item_id
	entity.global_position = spawn_pos
	entity.item_id = item_id
	entity.collision_layer = 2
	entity.collision_mask = 0
	entity.monitorable = true
	add_child(entity)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	collision.shape = shape
	entity.add_child(collision)

	var visual := ColorRect.new()
	visual.color = color
	visual.size = Vector2(28, 28)
	visual.position = Vector2(-14, -14)
	entity.add_child(visual)

	print("[Level1Controller] 实体道具已生成: %s @ %v" % [item_id, spawn_pos])

func _spawn_environment_entities() -> void:
	# === 妹妹幻影 NPC ===
	var sister_npc: Node = NPCClass.new()
	sister_npc.name = "NPC_Sister"
	sister_npc.global_position = Vector2(140, 350)
	sister_npc.npc_name = "妹妹幻影"
	sister_npc.npc_color = Color(0.8, 0.6, 0.9, 1.0)
	sister_npc.dialogue_lines = [
		"姐姐... 你终于来了...",
		"我在这个公寓里等你好久了...",
		"规则... 规则里藏着你需要的东西...",
	]
	sister_npc.collision_layer = 2
	sister_npc.collision_mask = 0
	sister_npc.monitorable = true
	add_child(sister_npc)
	print("[Level1Controller] 妹妹幻影 NPC 已生成")

# ============================================================
# 区域检测
# ============================================================

func _setup_areas() -> void:
	var sister_apartment := Area2D.new()
	sister_apartment.name = "Rooms/SisterApartment"
	sister_apartment.global_position = Vector2(140, 320)
	sister_apartment.collision_layer = 4
	sister_apartment.collision_mask = 0
	add_child(sister_apartment)
	var ss_shape := RectangleShape2D.new()
	ss_shape.size = Vector2(160, 230)
	var ss_collision := CollisionShape2D.new()
	ss_collision.shape = ss_shape
	sister_apartment.add_child(ss_collision)
	sister_apartment.body_entered.connect(_on_sister_apartment_entered)
	sister_apartment.body_exited.connect(_on_sister_apartment_exited)

	var corridor := Area2D.new()
	corridor.name = "Rooms/Corridor"
	corridor.global_position = Vector2(400, 320)
	corridor.collision_layer = 4
	corridor.collision_mask = 0
	add_child(corridor)
	var corr_shape := RectangleShape2D.new()
	corr_shape.size = Vector2(140, 230)
	var corr_collision := CollisionShape2D.new()
	corr_collision.shape = corr_shape
	corridor.add_child(corr_collision)
	corridor.body_entered.connect(_on_corridor_entered)

	var locked_room := Area2D.new()
	locked_room.name = "Rooms/LockedRoom_1"
	locked_room.global_position = Vector2(640, 320)
	locked_room.collision_layer = 4
	locked_room.collision_mask = 0
	add_child(locked_room)
	var lr_shape := RectangleShape2D.new()
	lr_shape.size = Vector2(140, 330)
	var lr_collision := CollisionShape2D.new()
	lr_collision.shape = lr_shape
	locked_room.add_child(lr_collision)
	locked_room.body_entered.connect(_on_locked_room_entered)
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
