extends Node2D

const PlayerClass = preload("res://characters/Player.gd")
const InteractableClass = preload("res://items/Interactable.gd")

var _player: Node = null
var _door: Node = null
var _transitioning: bool = false

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_door()
	GameManager.update_objective("找到妹妹公寓的入口")
	print("[StreetScene] 街道场景就绪")

func _build_geometry() -> void:
	# 绘制深灰色马路
	_spawn_floor(Vector2(200, 300), Vector2(200, 600), Color(0.15, 0.15, 0.15, 1.0))
	# 左侧围墙
	_spawn_wall(Vector2(50, 300), Vector2(100, 600), Color(0.05, 0.05, 0.05, 1.0))
	# 右侧围墙
	_spawn_wall(Vector2(350, 300), Vector2(100, 600), Color(0.05, 0.05, 0.05, 1.0))
	# 底部出发点墙壁
	_spawn_wall(Vector2(200, 550), Vector2(200, 100), Color(0.05, 0.05, 0.05, 1.0))

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

func _spawn_player() -> void:
	_player = PlayerClass.new()
	_player.name = "Player"
	_player.global_position = Vector2(200, 450) # 玩家在街道下方出生
	add_child(_player)

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	_player.add_child(camera)
	camera.make_current()

func _spawn_door() -> void:
	_door = InteractableClass.new()
	_door.name = "ApartmentDoor"
	_door.global_position = Vector2(200, 50) # 公寓门在街道正上方尽头
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
	visual.color = Color(0.4, 0.4, 0.5, 1.0) # 蓝灰色的门
	visual.size = Vector2(60, 40)
	visual.position = Vector2(-30, -20)
	_door.add_child(visual)

	# 修复点：正确连接交互信号
	_door.interacted.connect(_on_apartment_door_interacted)

func _on_apartment_door_interacted(_interactor: Node) -> void:
	if _transitioning:
		return
	_transitioning = true
	print("[StreetScene] 玩家交互了公寓大门，准备切换到 Level 1...")
	_fade_to_level1()

func _fade_to_level1() -> void:
	# 使用 CanvasLayer 保证黑屏覆盖全视野
	var canvas = CanvasLayer.new()
	var fade := ColorRect.new()
	fade.name = "FadeRect"
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade)
	add_child(canvas)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.5)

	await tween.finished
	print("[StreetScene] 切换至 Level1Controller.tscn ...")
	get_tree().change_scene_to_file("res://levels/Level1Controller.tscn")
