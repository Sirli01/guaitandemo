extends Node2D

const PlayerClass = preload("res://characters/Player.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")
const InteractableClass = preload("res://items/Interactable.gd")
const HUDClass = preload("res://ui/HUD.gd")
const InventoryUIClass = preload("res://ui/InventoryUI.gd")

var _player: Node = null
var _hud: Node = null
var _inventory_ui: Node = null
var _apartment_door: Node = null
var _transitioning: bool = false

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_hud()
	_spawn_inventory_ui()
	_spawn_hiding_items()
	_spawn_apartment_door()
	GameManager.update_objective("穿过街道，寻找妹妹的公寓")
	print("[StreetScene] 街道场景就绪")

# ============================================================
# 几何地形（1500px 长街道）
# ============================================================

func _build_geometry() -> void:
	var wall_color: Color = Color(0.2, 0.18, 0.15, 1.0)
	var floor_color: Color = Color(0.12, 0.10, 0.09, 1.0)

	# 街道地面（横向长条，y: 400-500）
	_spawn_floor(Vector2(850, 450), Vector2(1700, 100), floor_color)

	# 顶部边界墙（y: 100）
	_spawn_wall(Vector2(850, 100), Vector2(1700, 20), wall_color)

	# 底部边界墙（y: 500）
	_spawn_wall(Vector2(850, 500), Vector2(1700, 20), wall_color)

	# 左侧入口隔断（x: 0-50，顶部和底部留出行人通道）
	_spawn_wall(Vector2(25, 75), Vector2(50, 150), wall_color)   # 左上隔断
	_spawn_wall(Vector2(25, 425), Vector2(50, 150), wall_color) # 左下隔断

	# 右侧封闭边界（x: 1700）
	_spawn_wall(Vector2(1700, 300), Vector2(20, 400), wall_color)

	# 中间隔断墙（制造狭长压迫感）
	_spawn_wall(Vector2(400, 100), Vector2(10, 80), wall_color)
	_spawn_wall(Vector2(400, 420), Vector2(10, 80), wall_color)
	_spawn_wall(Vector2(700, 100), Vector2(10, 80), wall_color)
	_spawn_wall(Vector2(700, 420), Vector2(10, 80), wall_color)
	_spawn_wall(Vector2(1000, 100), Vector2(10, 80), wall_color)
	_spawn_wall(Vector2(1000, 420), Vector2(10, 80), wall_color)
	_spawn_wall(Vector2(1300, 100), Vector2(10, 80), wall_color)
	_spawn_wall(Vector2(1300, 420), Vector2(10, 80), wall_color)

	print("[StreetScene] 几何地形已生成（1500px 长街道）")

func _spawn_wall(pos: Vector2, size: Vector2, color: Color) -> void:
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

func _spawn_floor(pos: Vector2, size: Vector2, color: Color) -> void:
	var floor_rect := StaticBody2D.new()
	floor_rect.name = "Floor_%s" % pos
	floor_rect.global_position = pos
	floor_rect.collision_layer = 0
	floor_rect.collision_mask = 0
	add_child(floor_rect)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	floor_rect.add_child(collision)

	var rect := ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = Vector2(-size.x / 2, -size.y / 2)
	floor_rect.add_child(rect)

# ============================================================
# 玩家生成（带 Camera2D）
# ============================================================

func _spawn_player() -> void:
	_player = PlayerClass.new()
	_player.name = "Player"
	_player.global_position = Vector2(100, 300)
	_player.is_in_safe_room = false
	add_child(_player)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	_player.add_child(camera)
	camera.make_current()

	print("[StreetScene] 玩家 + Camera2D 已生成")

# ============================================================
# HUD 和背包
# ============================================================

func _spawn_hud() -> void:
	_hud = HUDClass.new()
	_hud.name = "StreetHUD"
	add_child(_hud)
	print("[StreetScene] HUD 已生成")

func _spawn_inventory_ui() -> void:
	_inventory_ui = InventoryUIClass.new()
	_inventory_ui.name = "StreetInventoryUI"
	add_child(_inventory_ui)
	print("[StreetScene] 背包 UI 已生成")

# ============================================================
# 隐藏道具
# ============================================================

func _spawn_hiding_items() -> void:
	var items: Array = [
		["energy_drink", Vector2(600, 380), Color(0.6, 0.3, 1.0)],
		["water_bottle", Vector2(1000, 360), Color(0.3, 0.6, 1.0)],
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
	shape.size = Vector2(28, 28)
	collision.shape = shape
	entity.add_child(collision)

	var visual := ColorRect.new()
	visual.color = color
	visual.size = Vector2(24, 24)
	visual.position = Vector2(-12, -12)
	entity.add_child(visual)

	print("[StreetScene] 隐藏道具已生成: %s @ %v" % [item_id, spawn_pos])

# ============================================================
# 公寓大门
# ============================================================

func _spawn_apartment_door() -> void:
	_apartment_door = InteractableClass.new()
	_apartment_door.name = "ApartmentDoor"
	_apartment_door.global_position = Vector2(1670, 300)
	_apartment_door.interaction_hint = "进入妹妹的公寓"
	_apartment_door.collision_layer = 2
	_apartment_door.collision_mask = 0
	_apartment_door.monitorable = true
	add_child(_apartment_door)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(15, 80)
	collision.shape = shape
	_apartment_door.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color(0.4, 0.3, 0.2, 1.0)
	visual.size = Vector2(12, 76)
	visual.position = Vector2(-6, -38)
	_apartment_door.add_child(visual)

	_apartment_door.interacted.connect(_on_door_interacted)
	print("[StreetScene] 公寓大门已生成")

# ============================================================
# 交互回调
# ============================================================

func _on_door_interacted(_interactor: Node) -> void:
	if _transitioning:
		return
	_transitioning = true

	_fade_to_level1()

func _fade_to_level1() -> void:
	var fade := ColorRect.new()
	fade.name = "FadeRect"
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.5)

	await tween.finished

	get_tree().paused = false
	# 切断背景音乐（如有 AudioManager）
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager and audio_manager.has_method("stop_ambient"):
		audio_manager.stop_ambient()

	print("[StreetScene] 进入 Level1...")
	get_tree().change_scene_to_file("res://levels/Main.tscn")
