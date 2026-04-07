extends Node2D

const PlayerClass = preload("res://characters/Player.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")
const InteractableClass = preload("res://items/Interactable.gd")
const HUDClass = preload("res://ui/HUD.gd")
const InventoryUIClass = preload("res://ui/InventoryUI.gd")

var _player: Node = null
var _phone: Node = null
var _door: Node = null
var _hud: Node = null
var _inventory_ui: Node = null
var _has_read_phone: bool = false
var _transitioning: bool = false

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_hud()
	_spawn_inventory_ui()
	_spawn_phone()
	_spawn_door()
	_setup_safe_zone()
	GameManager.update_objective("查看手机上的微信记录")
	print("[RoomScene] 房间场景就绪")

# ============================================================
# 几何地形（封闭小房间）
# ============================================================

func _build_geometry() -> void:
	var wall_color: Color = Color(0.2, 0.18, 0.15, 1.0)
	var floor_color: Color = Color(0.12, 0.10, 0.09, 1.0)

	# 地板
	_spawn_floor(Vector2(140, 550), Vector2(280, 100), floor_color)

	# 左墙（全高）
	_spawn_wall(Vector2(0, 300), Vector2(20, 600), wall_color)

	# 右墙上半段（y: 0-250）
	_spawn_wall(Vector2(280, 125), Vector2(20, 250), wall_color)

	# 右墙下半段（y: 400-600）
	_spawn_wall(Vector2(280, 500), Vector2(20, 200), wall_color)

	# 天花板
	_spawn_wall(Vector2(140, 0), Vector2(280, 20), wall_color)

	# 地板表面
	_spawn_wall(Vector2(140, 600), Vector2(280, 20), wall_color)

	# 房间内家具
	_spawn_furniture(Vector2(80, 480), Vector2(100, 50), Color(0.3, 0.25, 0.2, 1.0))   # 床
	_spawn_furniture(Vector2(130, 160), Vector2(120, 40), Color(0.35, 0.28, 0.22, 1.0)) # 桌子

	# 门框（右侧，y: 250-400 是门洞）
	_spawn_wall(Vector2(280, 175), Vector2(20, 100), wall_color)   # 门洞上隔断
	_spawn_wall(Vector2(280, 450), Vector2(20, 100), wall_color)  # 门洞下隔断

	print("[RoomScene] 几何地形已生成")

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

func _spawn_furniture(pos: Vector2, size: Vector2, color: Color) -> void:
	var furniture := StaticBody2D.new()
	furniture.name = "Furniture_%s" % pos
	furniture.global_position = pos
	furniture.collision_layer = 1
	furniture.collision_mask = 0
	add_child(furniture)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	furniture.add_child(collision)

	var rect := ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = Vector2(-size.x / 2, -size.y / 2)
	furniture.add_child(rect)

# ============================================================
# 玩家生成（带 Camera2D）
# ============================================================

func _spawn_player() -> void:
	_player = PlayerClass.new()
	_player.name = "Player"
	_player.global_position = Vector2(100, 400)
	_player.is_in_safe_room = true
	add_child(_player)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	_player.add_child(camera)
	camera.make_current()

	print("[RoomScene] 玩家 + Camera2D 已生成")

# ============================================================
# HUD 和背包
# ============================================================

func _spawn_hud() -> void:
	_hud = HUDClass.new()
	_hud.name = "RoomHUD"
	add_child(_hud)
	print("[RoomScene] HUD 已生成")

func _spawn_inventory_ui() -> void:
	_inventory_ui = InventoryUIClass.new()
	_inventory_ui.name = "RoomInventoryUI"
	add_child(_inventory_ui)
	print("[RoomScene] 背包 UI 已生成")

# ============================================================
# 手机道具
# ============================================================

func _spawn_phone() -> void:
	_phone = InteractableClass.new()
	_phone.name = "Phone"
	_phone.global_position = Vector2(130, 160)
	_phone.interaction_hint = "查看手机"
	_phone.collision_layer = 2
	_phone.collision_mask = 0
	_phone.monitorable = true
	add_child(_phone)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	collision.shape = shape
	_phone.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color(0.2, 0.2, 0.25, 1.0)
	visual.size = Vector2(28, 28)
	visual.position = Vector2(-14, -14)
	_phone.add_child(visual)

	_phone.interacted.connect(_on_phone_interacted)
	print("[RoomScene] 手机已生成")

# ============================================================
# 房间出口门
# ============================================================

func _spawn_door() -> void:
	_door = InteractableClass.new()
	_door.name = "RoomDoor"
	_door.global_position = Vector2(265, 325)
	_door.interaction_hint = "打开房门"
	_door.collision_layer = 2
	_door.collision_mask = 0
	_door.monitorable = true
	add_child(_door)

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(15, 80)
	collision.shape = shape
	_door.add_child(collision)

	var visual := ColorRect.new()
	visual.color = Color(0.4, 0.3, 0.2, 1.0)
	visual.size = Vector2(12, 76)
	visual.position = Vector2(-6, -38)
	_door.add_child(visual)

	_door.interacted.connect(_on_door_interacted)
	print("[RoomScene] 房门已生成")

# ============================================================
# 安全区
# ============================================================

func _setup_safe_zone() -> void:
	var safe_zone := Area2D.new()
	safe_zone.name = "SafeZone"
	safe_zone.global_position = Vector2(140, 300)
	safe_zone.collision_layer = 4
	safe_zone.collision_mask = 0
	add_child(safe_zone)

	var shape := RectangleShape2D.new()
	shape.size = Vector2(280, 600)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	safe_zone.add_child(collision)

	safe_zone.body_entered.connect(_on_safe_zone_entered)
	safe_zone.body_exited.connect(_on_safe_zone_exited)
	print("[RoomScene] 安全区已设置")

func _on_safe_zone_entered(body: Node) -> void:
	if body == _player:
		_player.is_in_safe_room = true
		print("[RoomScene] 玩家进入安全区")

func _on_safe_zone_exited(body: Node) -> void:
	if body == _player:
		_player.is_in_safe_room = false
		print("[RoomScene] 玩家离开安全区")

# ============================================================
# 交互回调
# ============================================================

func _on_phone_interacted(_interactor: Node) -> void:
	if _has_read_phone:
		return
	_has_read_phone = true

	var hud_node := get_node_or_null("RoomHUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		var wechat_text: String = """[color=#888888]【微信聊天记录】[/color]

[color=#aaaaaa]前两天 — 日常聊天[/color]
[color=#e8d8b0]妹妹：[/color] 姐，周末一起吃饭吗？
[color=#e8d8b0]姐姐：[/color] 好啊，去那家日料？
[color=#e8d8b0]妹妹：[/color] 耶！

[color=#ff6b6b]昨天 22:31[/color]
[color=#e8d8b0]妹妹：[/color] 姐你怎么不回消息？
[color=#e8d8b0]妹妹：[/color] 你在吗？？
[color=#e8d8b0]妹妹：[/color] 我有点害怕...

[color=#ff4444]今天 23:17[/color]
[color=#e8d8b0]姐姐（你）：[/color] 我去你公寓找你。
[color=#e8d8b0]妹妹：[/color] [color=#ff6b6b]别来！！！[/color]"""
		hud_node.show_reading_panel("手机微信", wechat_text)

	# 更新门提示文字
	_door.interaction_hint = "走出房门"

	await get_tree().create_timer(0.5).timeout
	GameManager.update_objective("走出房门，去妹妹的公寓")

func _on_door_interacted(_interactor: Node) -> void:
	if not _has_read_phone:
		print("[RoomScene] 【提示】我得先看看手机上的消息...")
		# 显示屏幕警告提示
		var hud_node := get_node_or_null("RoomHUD")
		if hud_node and hud_node.has_method("update_counter_state_hint"):
			hud_node.update_counter_state_hint("【提示】我得先看看手机上的消息...")
		return
	if _transitioning:
		return
	_transitioning = true

	_fade_to_street()

func _fade_to_street() -> void:
	var fade := ColorRect.new()
	fade.name = "FadeRect"
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.5)

	await tween.finished

	get_tree().paused = false
	print("[RoomScene] 进入街道场景...")
	get_tree().change_scene_to_file("res://levels/StreetScene.tscn")
