extends Node2D

const PlayerClass = preload("res://characters/Player.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")
const InteractableClass = preload("res://items/Interactable.gd")

var _player: Node = null
var _phone: Node = null
var _apartment_door: Node = null
var _phone_read: bool = false
var _transitioning: bool = false

func _ready() -> void:
	_build_room_geometry()
	_spawn_player()
	_spawn_phone()
	_spawn_apartment_door()
	_setup_hud()
	print("[IntroScene] 序章就绪")

func _build_room_geometry() -> void:
	var wall_color: Color = Color(0.2, 0.18, 0.15, 1.0)

	# 房间墙壁（四周）
	_spawn_wall(Vector2(400, 40), Vector2(800, 20), wall_color)   # 上
	_spawn_wall(Vector2(400, 560), Vector2(800, 20), wall_color) # 下
	_spawn_wall(Vector2(20, 300), Vector2(20, 540), wall_color)  # 左
	_spawn_wall(Vector2(780, 300), Vector2(20, 540), wall_color) # 右

	# 床（左侧）
	_spawn_furniture(Vector2(120, 400), Vector2(120, 80), Color(0.3, 0.25, 0.2, 1.0))

	# 桌子（右侧，靠墙）
	_spawn_furniture(Vector2(600, 450), Vector2(160, 60), Color(0.35, 0.28, 0.22, 1.0))

	# 窗户（上方墙壁）
	_spawn_window(Vector2(400, 60), Vector2(120, 15))

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

func _spawn_window(pos: Vector2, size: Vector2) -> void:
	var window := StaticBody2D.new()
	window.name = "Window"
	window.global_position = pos
	window.collision_layer = 1
	window.collision_mask = 0
	add_child(window)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	window.add_child(collision)

	var rect := ColorRect.new()
	rect.color = Color(0.15, 0.2, 0.3, 0.8)
	rect.size = size
	rect.position = Vector2(-size.x / 2, -size.y / 2)
	window.add_child(rect)

func _spawn_player() -> void:
	_player = PlayerClass.new()
	_player.name = "Player"
	_player.global_position = Vector2(120, 350)
	add_child(_player)

func _spawn_phone() -> void:
	_phone = InteractableClass.new()
	_phone.name = "Phone"
	_phone.global_position = Vector2(600, 430)
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
	print("[IntroScene] 手机已生成")

func _spawn_apartment_door() -> void:
	_apartment_door = InteractableClass.new()
	_apartment_door.name = "ApartmentDoor"
	_apartment_door.global_position = Vector2(760, 300)
	_apartment_door.interaction_hint = "前往妹妹的公寓"
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
	print("[IntroScene] 公寓大门已生成")

func _setup_hud() -> void:
	var hud_scene := load("res://ui/HUD.gd")
	if hud_scene:
		var hud := CanvasLayer.new()
		hud.name = "IntroHUD"
		add_child(hud)
		var script_obj = load("res://ui/HUD.gd")
		if script_obj:
			hud.set_script(script_obj)
		print("[IntroScene] HUD 已挂载")

func _on_phone_interacted(interactor: Node) -> void:
	if _phone_read:
		return
	_phone_read = true

	var hud := get_node_or_null("IntroHUD")
	if hud and hud.has_method("show_reading_panel"):
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
		hud.show_reading_panel("手机微信", wechat_text)

	# 阅读完毕后更新目标
	await get_tree().create_timer(0.5).timeout
	GameManager.update_objective("前往妹妹的公寓")

func _on_door_interacted(interactor: Node) -> void:
	if _transitioning:
		return
	_transitioning = true

	_fade_to_level1()

func _fade_to_level1() -> void:
	get_tree().paused = true

	# 创建黑屏过渡
	var fade := ColorRect.new()
	fade.name = "FadeRect"
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fade)

	# 淡出
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.5)

	await tween.finished

	# 切换场景
	print("[IntroScene] 进入第一层：妹妹的公寓...")
	get_tree().change_scene_to_file("res://levels/Main.tscn")

	get_tree().paused = false
