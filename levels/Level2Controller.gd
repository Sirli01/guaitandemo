extends Node2D

const PlayerClass = preload("res://characters/Player.gd")
const InteractableClass = preload("res://items/Interactable.gd")
const HeelMonsterClass = preload("res://characters/HeelMonster.gd")
const NPCBaseClass = preload("res://characters/NPCBase.gd")
const NPCGirlClass = preload("res://characters/NPCGirl.gd")
const NPCBoyClass = preload("res://characters/NPCBoy.gd")
const NPCStrayClass = preload("res://characters/NPCStray.gd")

var _player: Node = null
var _heel_monster: Node = null
var _npc_girl: Node = null
var _npc_boy: Node = null
var _npc_stray: Node = null
var _elevator_door: Node = null
var _transitioning: bool = false

# 剧情状态标志
var _event_a_triggered: bool = false
var _event_b_triggered: bool = false
var _event_b_dialogue_done: bool = false
var _girl_runs_away: bool = false
var _npc_stray_was_alive: bool = true
var _girl_locked_and_dying: bool = false

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_heel_monster()
	_spawn_npcs()
	_spawn_elevator_door()
	GameManager.update_objective("穿过诡异走廊，找到电梯")
	print("[Level2Controller] 第二层（诡异走廊）就绪")

func _build_geometry() -> void:
	var floor_color = Color(0.12, 0.10, 0.13, 1.0)
	var wall_color = Color(0.05, 0.05, 0.05, 1.0)

	# 主走廊地板（横向 x:0~1000, y:200~400）
	_spawn_floor(Vector2(500, 300), Vector2(1000, 200), floor_color)

	# 主走廊四面墙壁
	_spawn_wall(Vector2(500, 190), Vector2(1000, 20), wall_color)   # 上墙
	_spawn_wall(Vector2(500, 410), Vector2(1000, 20), wall_color)   # 下墙
	_spawn_wall(Vector2(-10, 300), Vector2(20, 200), wall_color)    # 左墙（起点封闭）
	_spawn_wall(Vector2(1010, 300), Vector2(20, 200), wall_color)  # 右墙

	# 分支死胡同（从主走廊上方 x=400 处向上延伸 y:50~200）
	# 左边分支墙
	_spawn_wall(Vector2(380, 125), Vector2(20, 150), wall_color)   # 左边界
	# 上方封闭墙
	_spawn_wall(Vector2(400, 50), Vector2(80, 20), wall_color)    # 顶部
	# 右侧不封闭，留出走人的空间，但男路人在里面所以实际是死胡同

	# 分支地板
	_spawn_floor(Vector2(400, 175), Vector2(80, 150), floor_color)

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
	_player.global_position = Vector2(100, 300)
	add_child(_player)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	_player.add_child(camera)
	camera.make_current()

func _spawn_heel_monster() -> void:
	_heel_monster = HeelMonsterClass.new()
	_heel_monster.name = "HeelMonster"
	_heel_monster.global_position = Vector2(500, 50)
	add_child(_heel_monster)
	print("[Level2Controller] 高跟鞋怪物已生成（顶部游荡）")

func _spawn_npcs() -> void:
	# 男路人：出生在死胡同深处，离大部队很远，会首先被锁定
	_npc_stray = NPCStrayClass.new()
	_npc_stray.name = "NPCStray"
	_npc_stray.global_position = Vector2(400, 100)
	add_child(_npc_stray)
	print("[Level2Controller] 男路人已生成（死胡同深处）")

	# 女伴：玩家附近
	_npc_girl = NPCGirlClass.new()
	_npc_girl.name = "NPCGirl"
	_npc_girl.global_position = Vector2(150, 300)
	add_child(_npc_girl)
	print("[Level2Controller] 女伴已生成")

	# 男伴：玩家附近
	_npc_boy = NPCBoyClass.new()
	_npc_boy.name = "NPCBoy"
	_npc_boy.global_position = Vector2(130, 320)
	add_child(_npc_boy)
	print("[Level2Controller] 男伴已生成")

func _spawn_elevator_door() -> void:
	_elevator_door = InteractableClass.new()
	_elevator_door.name = "ElevatorDoor"
	_elevator_door.global_position = Vector2(950, 300)
	_elevator_door.interaction_hint = "呼叫电梯"
	_elevator_door.collision_layer = 2
	_elevator_door.collision_mask = 0
	_elevator_door.monitorable = true
	add_child(_elevator_door)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40, 80)
	collision.shape = shape
	_elevator_door.add_child(collision)
	var visual := ColorRect.new()
	visual.color = Color(0.5, 0.5, 0.5, 1.0)
	visual.size = Vector2(40, 80)
	visual.position = Vector2(-20, -40)
	_elevator_door.add_child(visual)
	_elevator_door.interacted.connect(_on_elevator_interacted)

func _process(delta: float) -> void:
	_check_event_a()
	_check_event_b(delta)
	_check_girl_running_away(delta)

# ============================================================
# 剧情事件A：男路人惨死
# ============================================================

func _check_event_a() -> void:
	if _event_a_triggered:
		return
	if _npc_stray == null:
		return

	# 检测男路人是否死亡（通过 is_alive 属性）
	var stray_alive: bool = true
	if "is_alive" in _npc_stray:
		stray_alive = _npc_stray.is_alive
	

	# 男路人从活着变成死亡
	if _npc_stray_was_alive and not stray_alive:
		_event_a_triggered = true
		print("【旁白】：走廊深处传来一阵凄厉的惨叫声……男路人死了。")

	_npc_stray_was_alive = stray_alive

# ============================================================
# 剧情事件B：女伴作死离队
# ============================================================

func _check_event_b(_delta: float) -> void:
	if _event_b_triggered:
		return
	if _player == null:
		return

	# 当玩家走到 x=300 时触发
	if _player.global_position.x >= 300.0:
		_event_b_triggered = true
		_trigger_girl_runs_away_dialogue()

func _trigger_girl_runs_away_dialogue() -> void:
	print("【男伴】：别乱跑，跟着阿柚！")
	await get_tree().create_timer(1.5).timeout
	print("【女伴】：我受够了，这里有鬼，我要自己找出口！")
	_girl_runs_away = true

# ============================================================
# 女伴逃跑逻辑：向上方移动直到 y=100
# ============================================================

func _check_girl_running_away(delta: float) -> void:
	if not _girl_runs_away:
		return
	if _npc_girl == null or not is_instance_valid(_npc_girl):
		return

	# 女伴向上逃跑
	var target_y: float = 100.0
	if _npc_girl.global_position.y > target_y:
		_npc_girl.global_position.y -= 60.0 * delta

		# 让高跟鞋怪物有机会锁定她
		if _heel_monster != null and _heel_monster.has_method("get_locked_target"):
			var locked: Node = _heel_monster.get_locked_target()
			if locked == _npc_girl and not _event_b_dialogue_done:
				_event_b_dialogue_done = true
				# 检测到女伴被锁定，开始监听死亡
				_npc_girl.npc_died.connect(_on_girl_died)

func _on_girl_died(npc: Node) -> void:
	if npc != _npc_girl:
		return
	print("【女伴】：我听到高跟鞋声越来越近了！救命啊！......（寂静）")

# ============================================================
# 电梯交互
# ============================================================

func _on_elevator_interacted(_interactor: Node) -> void:
	if _transitioning:
		return
	_transitioning = true
	print("乘坐电梯逃离了第二层")
	_fade_to_level3()

func _fade_to_level3() -> void:
	var canvas := CanvasLayer.new()
	var fade := ColorRect.new()
	fade.name = "FadeRect"
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade)
	add_child(canvas)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 1.5)
	await tween.finished
	print("[Level2Controller] 切换至 Level3Controller.tscn ...")
	get_tree().change_scene_to_file("res://levels/Level3Controller.tscn")
