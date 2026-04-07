extends Node2D
class_name Level2Controller

signal entered_safe_room(room_name: String)
signal left_safe_room(room_name: String)
signal heels_sound_detected(position: Vector2)
signal xiaxia_mirror_triggered
signal game_over_triggered(reason: String)

const ItemClass = preload("res://items/Item.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")
const DoorClass = preload("res://items/Door.gd")
const HidingSpotClass = preload("res://items/HidingSpot.gd")
const ElevatorClass = preload("res://items/Elevator.gd")
const NPCClass = preload("res://items/NPC.gd")

var _player: Node = null
var _corridor_area: Area2D = null
var _mirror_zone: Area2D = null
var _hidden_room: Area2D = null

var _xiaxia_triggered: bool = false
var _elevator_cards_collected: int = 0
const ELEVATOR_CARDS_REQUIRED: int = 2

var _has_earplugs_equipped: bool = false
var _current_safe_room: String = ""

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_build_level_geometry()
	_player = get_tree().get_first_node_in_group("player")
	_setup_zones()
	_spawn_all_level_items()
	_spawn_environment_entities()
	_connect_signals()
	print("[Level2Controller] Level2 就绪")

# ============================================================
# 程序化几何生成
# ============================================================

func _build_level_geometry() -> void:
	var wall_color: Color = Color(0.2, 0.18, 0.22, 1.0)

	# === 主走廊（水平长条）===
	_spawn_wall_rect(Vector2(400, 100), Vector2(700, 20), wall_color)   # 上墙
	_spawn_wall_rect(Vector2(400, 500), Vector2(700, 20), wall_color)  # 下墙
	_spawn_wall_rect(Vector2(50, 100), Vector2(20, 420), wall_color)   # 左墙
	_spawn_wall_rect(Vector2(750, 100), Vector2(20, 420), wall_color)  # 右墙

	# === 小夏房间（上方镜子区域）===
	_spawn_wall_rect(Vector2(200, 50), Vector2(200, 20), wall_color)   # 上墙
	_spawn_wall_rect(Vector2(200, 150), Vector2(20, 100), wall_color)  # 左墙
	_spawn_wall_rect(Vector2(380, 150), Vector2(20, 100), wall_color)  # 右墙

	# === 隐藏房间（下方密室）===
	_spawn_wall_rect(Vector2(550, 520), Vector2(200, 20), wall_color)  # 下墙
	_spawn_wall_rect(Vector2(450, 520), Vector2(20, 100), wall_color)  # 左墙
	_spawn_wall_rect(Vector2(750, 520), Vector2(20, 100), wall_color)  # 右墙

	# === 走廊门 ===
	_spawn_door(Vector2(150, 300), "door_l2_entrance")
	_spawn_door(Vector2(650, 300), "door_l2_exit")

	# === 躲藏点 ===
	_spawn_hiding_spot(Vector2(300, 300), "hiding_l2_1")
	_spawn_hiding_spot(Vector2(500, 400), "hiding_l2_2")

	# === 电梯 ===
	_spawn_elevator(Vector2(720, 300), 2, 3, "ayou_id_card")

	print("[Level2Controller] 几何布局已生成")

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

func _spawn_elevator(pos: Vector2, floor: int, target: int, required_item: String) -> void:
	var elev: Node = ElevatorClass.new()
	elev.name = "Elevator_Floor%d" % floor
	elev.global_position = pos
	elev.floor_number = floor
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

# ============================================================
# 区域检测
# ============================================================

func _setup_zones() -> void:
	_corridor_area = Area2D.new()
	_corridor_area.name = "Rooms/Corridor_L2"
	_corridor_area.global_position = Vector2(400, 300)
	_corridor_area.collision_layer = 4
	_corridor_area.collision_mask = 0
	add_child(_corridor_area)
	var corr_shape := RectangleShape2D.new()
	corr_shape.size = Vector2(600, 380)
	var corr_collision := CollisionShape2D.new()
	corr_collision.shape = corr_shape
	_corridor_area.add_child(corr_collision)
	_corridor_area.body_entered.connect(_on_corridor_entered)
	_corridor_area.body_exited.connect(_on_corridor_exited)

	_mirror_zone = Area2D.new()
	_mirror_zone.name = "MirrorZone"
	_mirror_zone.global_position = Vector2(290, 100)
	_mirror_zone.collision_layer = 4
	_mirror_zone.collision_mask = 0
	add_child(_mirror_zone)
	var mz_shape := RectangleShape2D.new()
	mz_shape.size = Vector2(90, 50)
	var mz_collision := CollisionShape2D.new()
	mz_collision.shape = mz_shape
	_mirror_zone.add_child(mz_collision)
	_mirror_zone.body_entered.connect(_on_mirror_zone_entered)

	_hidden_room = Area2D.new()
	_hidden_room.name = "Rooms/HiddenRoom"
	_hidden_room.global_position = Vector2(600, 470)
	_hidden_room.collision_layer = 4
	_hidden_room.collision_mask = 0
	add_child(_hidden_room)
	var hr_shape := RectangleShape2D.new()
	hr_shape.size = Vector2(150, 50)
	var hr_collision := CollisionShape2D.new()
	hr_collision.shape = hr_shape
	_hidden_room.add_child(hr_collision)
	_hidden_room.body_entered.connect(_on_hidden_room_entered)

# ============================================================
# 道具生成
# ============================================================

func _spawn_all_level_items() -> void:
	var items: Array = [
		["rule_page_2", Vector2(200, 200), Color(0.7, 0.5, 0.2)],
		["food_ration",  Vector2(450, 400), Color(0.8, 0.4, 0.2)],
		["battery",      Vector2(600, 250), Color(1.0, 0.8, 0.0)],
		["earplug",      Vector2(350, 450), Color(0.5, 0.3, 0.6)],
	]
	for item_data in items:
		_spawn_physical_item(item_data[0], item_data[1], item_data[2])

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

func _spawn_environment_entities() -> void:
	# === 小夏 NPC ===
	var xiaxia_npc: Node = NPCClass.new()
	xiaxia_npc.name = "NPC_Xiaxia"
	xiaxia_npc.global_position = Vector2(290, 200)
	xiaxia_npc.npc_name = "小夏"
	xiaxia_npc.npc_color = Color(0.5, 0.7, 0.9, 1.0)
	xiaxia_npc.dialogue_lines = [
		"那个镜子... 别照太久...",
		"会看到不该看的东西...",
		"林晚姐姐她... 其实一直在...",
	]
	xiaxia_npc.collision_layer = 2
	xiaxia_npc.collision_mask = 0
	xiaxia_npc.monitorable = true
	add_child(xiaxia_npc)
	print("[Level2Controller] 小夏 NPC 已生成")

# ============================================================
# 信号连接
# ============================================================

func _connect_signals() -> void:
	ItemSystem.inventory_changed.connect(_on_inventory_changed)

func _on_inventory_changed() -> void:
	_has_earplugs_equipped = ItemSystem.has_item("earplug")

# ============================================================
# 走廊
# ============================================================

func _on_corridor_entered(body: Node) -> void:
	if body != _player:
		return
	_current_safe_room = ""
	print("[Level2Controller] 玩家进入走廊")

func _on_corridor_exited(body: Node) -> void:
	if body != _player:
		return
	_current_safe_room = ""
	print("[Level2Controller] 玩家离开走廊")

# ============================================================
# 镜子区域（小夏剧情）
# ============================================================

func _on_mirror_zone_entered(body: Node) -> void:
	if body != _player:
		return
	if _xiaxia_triggered:
		return
	_xiaxia_triggered = true
	xiaxia_mirror_triggered.emit()
	print("[Level2Controller] 触发小夏镜子过场")
	_player.set_process_input(false)
	restore_player_input_after_cutscene()

func restore_player_input_after_cutscene() -> void:
	await get_tree().create_timer(0.5).timeout
	if _player != null:
		_player.set_process_input(true)
	print("[Level2Controller] 过场结束")

# ============================================================
# 隐藏房间
# ============================================================

func _on_hidden_room_entered(body: Node) -> void:
	if body != _player:
		return
	_current_safe_room = "HiddenRoom"
	_player.is_in_safe_room = true
	entered_safe_room.emit("HiddenRoom")
	print("[Level2Controller] 玩家进入隐藏房间（安全区）")

# ============================================================
# 电梯
# ============================================================

func on_elevator_card_collected() -> void:
	_elevator_cards_collected += 1
	print("[Level2Controller] 电梯权限卡: %d/%d" % [_elevator_cards_collected, ELEVATOR_CARDS_REQUIRED])

# ============================================================
# 对外接口
# ============================================================

func get_player() -> Node:
	return _player
