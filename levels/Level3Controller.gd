extends Node2D
class_name Level3Controller

enum CounterState {
	IDLE,
	MONSTER_BOUND,
	SWAPPED,
	CONTROLLING_MONSTER,
	WINDOW_BROKEN,
	DROP_TRIGGERED,
	TRAPPED,
}

signal counter_state_changed(new_state: CounterState)
signal entered_safe_room(room_name: String)
signal game_over_triggered(reason: String)

const ItemClass = preload("res://items/Item.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")
const DoorClass = preload("res://items/Door.gd")
const HidingSpotClass = preload("res://items/HidingSpot.gd")
const ElevatorClass = preload("res://items/Elevator.gd")
const NPCBaseClass = preload("res://characters/NPCBase.gd")

@export var monsters_patrol: Array[NodePath] = []

var _counter_state: CounterState = CounterState.IDLE
var _player: Node = null
var _controlled_monster: Node = null
var _bound_monster: Node = null
var _current_window: Node = null
var _elevator_cards_collected: int = 0
const ELEVATOR_CARDS_REQUIRED: int = 3

var _smart_route_available: bool = false

# ============================================================
# 初始化
# ============================================================

func _ready() -> void:
	_build_level_geometry()
	_player = get_tree().get_first_node_in_group("player")
	_setup_zones()
	_spawn_all_level_items()
	_spawn_environment_entities()
	_check_smart_route()
	print("[Level3Controller] Level3 就绪，智斗路线可用: %s" % _smart_route_available)

func _check_smart_route() -> void:
	var has_rope: bool = ItemSystem.has_item("rope")
	var has_axe: bool = ItemSystem.has_item("fire_axe")
	_smart_route_available = has_rope and has_axe
	if _smart_route_available:
		GameManager.on_route_unlocked("smart_route")
	else:
		GameManager.on_route_unlocked("stealth_route")

# ============================================================
# 程序化几何生成
# ============================================================

func _build_level_geometry() -> void:
	var wall_color: Color = Color(0.22, 0.18, 0.25, 1.0)

	# === 主场景（顶层走廊）===
	_spawn_wall_rect(Vector2(400, 80), Vector2(600, 20), wall_color)   # 上墙
	_spawn_wall_rect(Vector2(400, 520), Vector2(600, 20), wall_color) # 下墙
	_spawn_wall_rect(Vector2(100, 80), Vector2(20, 460), wall_color)  # 左墙
	_spawn_wall_rect(Vector2(700, 80), Vector2(20, 460), wall_color)  # 右墙

	# === 绑定区域（中央）===
	_spawn_bind_zone(Vector2(400, 300))

	# === 窗户区域（右侧）===
	_spawn_window_zone(Vector2(620, 300))

	# === 窗户 ===
	_spawn_window(Vector2(620, 300), "window_main")

	# === 电梯（左侧入口）===
	_spawn_elevator(Vector2(150, 300), 3, 1, "ayou_id_card")

	# === 躲藏点 ===
	_spawn_hiding_spot(Vector2(250, 200), "hiding_l3_1")
	_spawn_hiding_spot(Vector2(550, 400), "hiding_l3_2")

	# === 门 ===
	_spawn_door(Vector2(100, 450), "door_l3_entrance")

	print("[Level3Controller] 几何布局已生成")

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

func _spawn_bind_zone(pos: Vector2) -> void:
	var zone: Area2D = Area2D.new()
	zone.name = "BindZone"
	zone.global_position = pos
	zone.collision_layer = 4
	zone.collision_mask = 0
	add_child(zone)

	var shape := CircleShape2D.new()
	shape.radius = 50.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	zone.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color(0.6, 0.2, 0.2, 0.3)
	visual.size = Vector2(100, 100)
	visual.position = Vector2(-50, -50)
	zone.add_child(visual)

	zone.body_entered.connect(_on_bind_zone_entered)

func _spawn_window_zone(pos: Vector2) -> void:
	var zone: Area2D = Area2D.new()
	zone.name = "BreakWindowZone"
	zone.global_position = pos
	zone.collision_layer = 4
	zone.collision_mask = 0
	add_child(zone)

	var shape := CircleShape2D.new()
	shape.radius = 60.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	zone.add_child(collision)

	zone.body_entered.connect(_on_break_window_zone_entered)

func _spawn_window(pos: Vector2, window_id: String) -> void:
	var window := StaticBody2D.new()
	window.name = "Window_%s" % window_id
	window.global_position = pos
	window.collision_layer = 1
	window.collision_mask = 0
	add_child(window)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 80)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	window.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color(0.5, 0.7, 0.9, 0.6)
	visual.size = Vector2(6, 76)
	visual.position = Vector2(-3, -38)
	window.add_child(visual)

	# 添加 smash 方法
	window.set("window_id", window_id)
	print("[Level3Controller] 窗户已生成: %s @ %v" % [window_id, pos])

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
	pass

# ============================================================
# 道具生成
# ============================================================

func _spawn_all_level_items() -> void:
	var items: Array = [
		["rule_page_4",  Vector2(300, 200), Color(0.6, 0.5, 0.3)],
		["rule_page_5",  Vector2(500, 180), Color(0.6, 0.5, 0.3)],
		["ayou_id_card", Vector2(200, 400), Color(0.3, 0.6, 0.8)],
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
	# === 林晚 NPC ===
	var linwan_npc: Node = NPCBaseClass.new()
	linwan_npc.name = "NPC_LinWan"
	linwan_npc.global_position = Vector2(250, 150)
	linwan_npc.npc_name = "林晚"
	linwan_npc.display_name = "林晚"
	linwan_npc.npc_color = Color(0.9, 0.7, 0.5, 1.0)
	linwan_npc.dialogue_lines = [
		"你终于来了... 一切都要结束了...",
		"规则第三条... 是打破一切的关键...",
		"拿起斧头... 去窗户那边...",
	]
	linwan_npc.collision_layer = 2
	linwan_npc.collision_mask = 0
	linwan_npc.monitorable = true
	add_child(linwan_npc)
	print("[Level3Controller] 林晚 NPC 已生成")

# ============================================================
# 区域事件
# ============================================================

func _on_bind_zone_entered(body: Node) -> void:
	if body != _player:
		return
	if not _smart_route_available:
		return
	print("[Level3Controller] 进入绑定区域，可对怪物使用麻绳")

func _on_break_window_zone_entered(body: Node) -> void:
	if body != _player:
		return
	if _counter_state == CounterState.CONTROLLING_MONSTER:
		print("[Level3Controller] 已操控怪物到达窗户，可使用消防斧砸窗")
		GameManager.on_reached_window()

# ============================================================
# 状态机
# ============================================================

func _set_counter_state(new_state: CounterState) -> void:
	var old_state: CounterState = _counter_state
	_counter_state = new_state
	counter_state_changed.emit(new_state)
	print("[Level3Controller] 反杀状态: %s → %s" % [CounterState.keys()[old_state], CounterState.keys()[new_state]])

func attempt_bind_monster(monster: Node) -> bool:
	if not _smart_route_available:
		return false
	if _counter_state != CounterState.IDLE:
		return false
	if monster.get("is_bound"):
		return false
	monster.bind_with_rope()
	_bound_monster = monster
	_set_counter_state(CounterState.MONSTER_BOUND)
	return true

func _trigger_swap(monster: Node, player: Node) -> void:
	if not RuleSystem.can_swap(monster, player):
		_trigger_trapped()
		return
	RuleSystem.do_swap(monster, player)
	_controlled_monster = monster
	_set_counter_state(CounterState.SWAPPED)
	_switch_control_to_monster(monster)
	_set_counter_state(CounterState.CONTROLLING_MONSTER)

func _switch_control_to_monster(monster: Node) -> void:
	if _player != null:
		_player.set_process_input(false)
		_player.set_physics_process(false)
	monster.set_process_input(true)
	_controlled_monster = monster
	var fc: Node = get_parent().get_node_or_null("FloorController")
	if fc and fc.has_method("switch_control_to"):
		fc.switch_control_to(monster)

func attempt_break_window(window: Node) -> bool:
	if _counter_state != CounterState.CONTROLLING_MONSTER:
		return false
	if not ItemSystem.has_item("fire_axe"):
		return false
	_current_window = window
	_set_counter_state(CounterState.WINDOW_BROKEN)
	return true

func _trigger_drop() -> void:
	_set_counter_state(CounterState.DROP_TRIGGERED)
	if _controlled_monster != null:
		_controlled_monster.set_physics_process(false)

func _trigger_trapped() -> void:
	_set_counter_state(CounterState.TRAPPED)
	GameManager.trigger_game_over("smart_route_failed")

# ============================================================
# 对外接口
# ============================================================

func get_counter_state() -> CounterState:
	return _counter_state

func is_smart_route() -> bool:
	return _smart_route_available

func get_current_hint() -> String:
	match _counter_state:
		CounterState.IDLE:
			return "持有麻绳时对怪物使用，可绑定怪物" if _smart_route_available else "寻找麻绳和斧头"
		CounterState.MONSTER_BOUND:
			return "怪物已绑定！请在对视触发灵魂互换"
		CounterState.SWAPPED:
			return "互换成功！操控怪物移动到窗户"
		CounterState.CONTROLLING_MONSTER:
			return "操控怪物到达窗户后，使用消防斧砸窗"
		CounterState.WINDOW_BROKEN:
			return "窗户已破！引导怪物跳窗"
		CounterState.DROP_TRIGGERED:
			return "等待 07:00 强制换回..."
		CounterState.TRAPPED:
			return "智斗失败，游戏结束"
	return ""
