extends Node2D

# ============================================================
# 序章 · 街道场景
# GDD：温馨的大街→推门瞬间一切声音被切断，进入死寂空间
# 街道上有隐藏道具（绳子、耳塞、手电筒）
# ============================================================

const PlayerClass = preload("res://characters/Player.gd")
const InteractableClass = preload("res://items/Interactable.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")
const HUDClass = preload("res://ui/HUD.gd")
const InventoryUIClass = preload("res://ui/InventoryUI.gd")

var _player: Node = null
var _door: Node = null
var _hud: Node = null
var _inventory_ui: Node = null
var _transitioning: bool = false

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_hud()
	_spawn_inventory_ui()
	_spawn_hidden_items()
	_spawn_door()
	GameManager.update_objective("找到妹妹公寓的入口")
	print("[StreetScene] 街道场景就绪")

# ============================================================
# 几何地形（加长街道 1500px，隐藏道具散落其中）
# ============================================================

func _build_geometry() -> void:
	var road_color := Color(0.15, 0.15, 0.15, 1.0)
	var wall_color := Color(0.05, 0.05, 0.05, 1.0)
	var sidewalk_color := Color(0.1, 0.1, 0.12, 1.0)

	# 加长马路地板
	_spawn_floor(Vector2(200, 750), Vector2(250, 1500), road_color)

	# 左侧围墙（全长）
	_spawn_wall(Vector2(25, 750), Vector2(50, 1500), wall_color)
	# 右侧围墙（全长）
	_spawn_wall(Vector2(375, 750), Vector2(50, 1500), wall_color)
	# 底部封闭墙（出生点后方）
	_spawn_wall(Vector2(200, 1500), Vector2(300, 20), wall_color)

	# 街道装饰：路灯（小色块代替）
	_spawn_decoration(Vector2(80, 300), Vector2(8, 8), Color(1.0, 0.9, 0.5, 0.6))
	_spawn_decoration(Vector2(320, 600), Vector2(8, 8), Color(1.0, 0.9, 0.5, 0.6))
	_spawn_decoration(Vector2(80, 900), Vector2(8, 8), Color(1.0, 0.9, 0.5, 0.6))

	# 人行道边缘
	_spawn_floor(Vector2(70, 750), Vector2(40, 1500), sidewalk_color)
	_spawn_floor(Vector2(330, 750), Vector2(40, 1500), sidewalk_color)

func _spawn_wall(pos: Vector2, size: Vector2, color: Color) -> void:
	var wall := StaticBody2D.new()
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
	floor_rect.global_position = pos
	add_child(floor_rect)
	var rect := ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = Vector2(-size.x / 2, -size.y / 2)
	floor_rect.add_child(rect)

func _spawn_decoration(pos: Vector2, size: Vector2, color: Color) -> void:
	var deco := ColorRect.new()
	deco.color = color
	deco.size = size
	deco.position = pos - size / 2
	add_child(deco)

# ============================================================
# 玩家、HUD、背包
# ============================================================

func _spawn_player() -> void:
	_player = PlayerClass.new()
	_player.name = "Player"
	_player.global_position = Vector2(200, 1400)
	add_child(_player)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	_player.add_child(camera)
	camera.make_current()

func _spawn_hud() -> void:
	_hud = HUDClass.new()
	_hud.name = "StreetHUD"
	add_child(_hud)

func _spawn_inventory_ui() -> void:
	_inventory_ui = InventoryUIClass.new()
	_inventory_ui.name = "StreetInventoryUI"
	add_child(_inventory_ui)

# ============================================================
# 隐藏道具（街道边角散落，GDD 要求玩家可拾取）
# ============================================================

func _spawn_hidden_items() -> void:
	# 绳子（藏在左侧人行道角落）
	_spawn_physical_item("rope", Vector2(75, 500), Color(0.6, 0.4, 0.2, 0.8))
	# 耳塞（藏在右侧路灯底下）
	_spawn_physical_item("earplug", Vector2(310, 900), Color(0.9, 0.9, 0.3, 0.8))
	# 手电筒（藏在中段暗处）
	_spawn_physical_item("flashlight", Vector2(150, 1100), Color(0.8, 0.8, 0.8, 0.8))
	print("[StreetScene] 隐藏道具已生成（绳子、耳塞、手电筒）")

func _spawn_physical_item(item_id: String, spawn_pos: Vector2, color: Color) -> void:
	var entity: Node = PhysicalItemClass.new()
	entity.name = "StreetItem_%s" % item_id
	entity.global_position = spawn_pos
	entity.item_id = item_id
	entity.collision_layer = 2
	entity.collision_mask = 0
	entity.monitorable = true
	add_child(entity)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 24)
	collision.shape = shape
	entity.add_child(collision)
	var visual := ColorRect.new()
	visual.color = color
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	entity.add_child(visual)

# ============================================================
# 公寓大门（街道尽头）
# ============================================================

func _spawn_door() -> void:
	_door = InteractableClass.new()
	_door.name = "ApartmentDoor"
	_door.global_position = Vector2(200, 50)
	_door.interaction_hint = "进入公寓"
	_door.collision_layer = 2
	_door.collision_mask = 0
	_door.monitorable = true
	add_child(_door)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 40)
	collision.shape = shape
	_door.add_child(collision)
	var visual := ColorRect.new()
	visual.color = Color(0.4, 0.4, 0.5, 1.0)
	visual.size = Vector2(60, 40)
	visual.position = Vector2(-30, -20)
	_door.add_child(visual)
	_door.interacted.connect(_on_apartment_door_interacted)

func _on_apartment_door_interacted(_interactor: Node) -> void:
	if _transitioning:
		return
	_transitioning = true
	print("[StreetScene] 推开公寓大门…所有声音被切断…")
	_fade_to_level1()

# ============================================================
# GDD 转折：推门瞬间一切声音被切断，进入死寂
# ============================================================

func _fade_to_level1() -> void:
	var canvas := CanvasLayer.new()
	var fade := ColorRect.new()
	fade.name = "FadeRect"
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade)
	add_child(canvas)

	# 先快速暗下来（GDD：声音瞬间切断）
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.8)
	await tween.finished

	# 停顿一下制造恐惧感
	await get_tree().create_timer(1.0).timeout

	print("[StreetScene] 切换至 Level1Controller.tscn ...")
	get_tree().change_scene_to_file("res://levels/Level1Controller.tscn")
