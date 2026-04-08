extends Node2D

const PlayerClass = preload("res://characters/Player.gd")
const InteractableClass = preload("res://items/Interactable.gd")

var _player: Node = null
var _diary: Node = null
var _exit_door: Node = null
var _apartment_key: Node = null
var _is_door_unlocked: bool = false
var _transitioning: bool = false

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_diary()
	_spawn_exit_door()
	GameManager.update_objective("寻找妹妹的下落")
	print("[Level1Controller] 第一层（妹妹公寓）就绪")

func _build_geometry() -> void:
	# 绘制浅灰色客厅地板
	_spawn_floor(Vector2(400, 300), Vector2(600, 400), Color(0.2, 0.2, 0.2, 1.0))
	# 房间四面墙壁
	_spawn_wall(Vector2(100, 300), Vector2(20, 400), Color(0.1, 0.1, 0.1, 1.0)) # 左墙
	_spawn_wall(Vector2(700, 300), Vector2(20, 400), Color(0.1, 0.1, 0.1, 1.0)) # 右墙
	_spawn_wall(Vector2(400, 100), Vector2(600, 20), Color(0.1, 0.1, 0.1, 1.0)) # 上墙
	_spawn_wall(Vector2(400, 500), Vector2(600, 20), Color(0.1, 0.1, 0.1, 1.0)) # 下墙
	# 客厅中央的桌子
	_spawn_furniture(Vector2(400, 300), Vector2(120, 80), Color(0.3, 0.2, 0.1, 1.0))

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

func _spawn_furniture(pos: Vector2, size: Vector2, color: Color) -> void:
	_spawn_wall(pos, size, color)

func _spawn_player() -> void:
	_player = PlayerClass.new()
	_player.name = "Player"
	_player.global_position = Vector2(200, 400) # 玩家在左下角出生
	add_child(_player)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	_player.add_child(camera)
	camera.make_current()

func _spawn_diary() -> void:
	_diary = InteractableClass.new()
	_diary.name = "Diary"
	_diary.global_position = Vector2(400, 300) # 放在桌子上
	_diary.interaction_hint = "阅读日记"
	_diary.collision_layer = 2
	_diary.collision_mask = 0
	_diary.monitorable = true
	add_child(_diary)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30, 30)
	collision.shape = shape
	_diary.add_child(collision)
	var visual := ColorRect.new()
	visual.color = Color(0.8, 0.8, 0.8, 1.0)
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	_diary.add_child(visual)
	_diary.interacted.connect(_on_diary_interacted)

func _spawn_exit_door() -> void:
	_exit_door = InteractableClass.new()
	_exit_door.name = "ExitDoor"
	_exit_door.global_position = Vector2(690, 300) # 右侧出口门
	_exit_door.interaction_hint = "门被反锁了"
	_exit_door.collision_layer = 2
	_exit_door.collision_mask = 0
	_exit_door.monitorable = true
	add_child(_exit_door)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 80)
	collision.shape = shape
	_exit_door.add_child(collision)
	var visual := ColorRect.new()
	visual.color = Color(0.4, 0.2, 0.1, 1.0)
	visual.size = Vector2(20, 80)
	visual.position = Vector2(-10, -40)
	_exit_door.add_child(visual)
	_exit_door.interacted.connect(_on_exit_door_interacted)

func _on_diary_interacted(_interactor: Node) -> void:
	print("【日记】：日记最后一页写着：千万不要回头看……")
	GameManager.update_objective("找到钥匙离开公寓")
	
	# 日记读完消失
	_diary.queue_free()
	
	# 在房间右上角生成钥匙
	_spawn_apartment_key()

func _spawn_apartment_key() -> void:
	_apartment_key = InteractableClass.new()
	_apartment_key.name = "ApartmentKey"
	_apartment_key.global_position = Vector2(600, 150) # 右上角
	_apartment_key.interaction_hint = "捡起钥匙"
	_apartment_key.collision_layer = 2
	_apartment_key.collision_mask = 0
	_apartment_key.monitorable = true
	add_child(_apartment_key)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20, 20)
	collision.shape = shape
	_apartment_key.add_child(collision)
	var visual := ColorRect.new()
	visual.color = Color(1.0, 0.8, 0.0, 1.0) # 金色的钥匙
	visual.size = Vector2(14, 14)
	visual.position = Vector2(-7, -7)
	_apartment_key.add_child(visual)
	_apartment_key.interacted.connect(_on_key_interacted)

func _on_key_interacted(_interactor: Node) -> void:
	print("[Level1Controller] 获得了公寓钥匙！")
	_apartment_key.queue_free()
	_is_door_unlocked = true
	_exit_door.interaction_hint = "打开房门"

func _on_exit_door_interacted(_interactor: Node) -> void:
	if not _is_door_unlocked:
		print("门打不开，似乎需要钥匙。")
		return
		
	if _transitioning:
		return
	_transitioning = true
	
	print("离开公寓，前往第二层...")
	_fade_to_level2()

func _fade_to_level2() -> void:
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
	print("[Level1Controller] 切换至 Level2Controller.tscn ...")
	get_tree().change_scene_to_file("res://levels/Level2Controller.tscn")
