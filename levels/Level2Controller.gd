extends Node2D

# ============================================================
# 第二层：听觉压迫与生死抉择 (Floor 2)
# GDD：
# - 规则："禁止离群 — 第二层"
# - 威胁：悬在天花板的【巨大高跟鞋】锁定离群者
# - 胆小男路人留守电梯口→离群→被击杀（立威）
# - 女伴与男伴吵架→女伴负气出走→规则才显示→女伴惨死
# - 开朗NPC落单→玩家抉择：有耳塞→给她 / 无耳塞→123木头人
# - 主角团极限逃入电梯
# ============================================================

const PlayerClass = preload("res://characters/Player.gd")
const InteractableClass = preload("res://items/Interactable.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")
const HUDClass = preload("res://ui/HUD.gd")
const InventoryUIClass = preload("res://ui/InventoryUI.gd")
const HeelMonsterClass = preload("res://characters/HeelMonster.gd")
const NPCGirlClass = preload("res://characters/NPCGirl.gd")
const NPCBoyClass = preload("res://characters/NPCBoy.gd")
const NPCStrayClass = preload("res://characters/NPCStray.gd")
const NPCCheerClass = preload("res://characters/NPCCheer.gd")
const NPCCoolClass = preload("res://characters/NPCCool.gd")

var _player: Node = null
var _hud: Node = null
var _inventory_ui: Node = null
var _heel_monster: Node = null
var _elevator_door: Node = null

# NPC 引用
var _npc_girl: Node = null
var _npc_boy: Node = null
var _npc_stray: Node = null
var _npc_cheer: Node = null
var _npc_cool: Node = null

# 剧情阶段枚举
enum Phase {
	EXPLORATION,        # 初始探索
	STRAY_DYING,        # 胆小男被锁定中
	STRAY_DEAD,         # 胆小男已死
	ARGUMENT,           # 男女伴吵架
	GIRL_RUNNING,       # 女伴负气出走
	GIRL_DEAD,          # 女伴已死，规则揭示
	CHEER_IN_DANGER,    # 开朗NPC落单
	CHEER_SAVED,        # 开朗NPC得救
	ELEVATOR_ESCAPE,    # 电梯逃生
}

var _phase: Phase = Phase.EXPLORATION
var _phase_timer: float = 0.0
var _transitioning: bool = false
var _stray_death_shown: bool = false

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_hud()
	_spawn_inventory_ui()
	_spawn_npcs()
	_spawn_heel_monster()
	_spawn_elevator_door()
	_spawn_items()
	GameManager.update_objective("穿过走廊，找到电梯")
	print("[Level2] 第二层就绪 — 高跟鞋恐怖开始")

# ============================================================
# 几何地形（长走廊 + 分支死胡同）
# ============================================================

func _build_geometry() -> void:
	var floor_color := Color(0.12, 0.10, 0.13, 1.0)
	var wall_color := Color(0.05, 0.05, 0.05, 1.0)

	# 主走廊地板（x:50~1050, y:200~400）
	_spawn_floor(Vector2(550, 300), Vector2(1000, 200), floor_color)

	# 主走廊墙壁
	_spawn_wall(Vector2(550, 190), Vector2(1000, 20), wall_color)   # 上墙
	_spawn_wall(Vector2(550, 410), Vector2(1000, 20), wall_color)   # 下墙
	_spawn_wall(Vector2(40, 300), Vector2(20, 200), wall_color)     # 左封闭
	_spawn_wall(Vector2(1060, 300), Vector2(20, 200), wall_color)   # 右封闭

	# 分支死胡同（胆小男路人所在区域，y:50~200）
	_spawn_floor(Vector2(200, 125), Vector2(100, 150), floor_color)
	_spawn_wall(Vector2(140, 125), Vector2(20, 150), wall_color)
	_spawn_wall(Vector2(260, 125), Vector2(20, 150), wall_color)
	_spawn_wall(Vector2(200, 40), Vector2(100, 20), wall_color)

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
	var floor_node := StaticBody2D.new()
	floor_node.global_position = pos
	add_child(floor_node)
	var rect := ColorRect.new()
	rect.color = color
	rect.size = size
	rect.position = Vector2(-size.x / 2, -size.y / 2)
	floor_node.add_child(rect)

# ============================================================
# 玩家、HUD
# ============================================================

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

func _spawn_hud() -> void:
	_hud = HUDClass.new()
	_hud.name = "Level2HUD"
	add_child(_hud)

func _spawn_inventory_ui() -> void:
	_inventory_ui = InventoryUIClass.new()
	_inventory_ui.name = "Level2InventoryUI"
	add_child(_inventory_ui)

# ============================================================
# NPC 路人们
# ============================================================

func _spawn_npcs() -> void:
	# 胆小男路人：独自留在电梯口旁的死胡同（GDD：首先触发离群规则→被杀）
	_npc_stray = NPCStrayClass.new()
	_npc_stray.name = "NPCStray"
	_npc_stray.global_position = Vector2(200, 80)
	add_child(_npc_stray)

	# 女伴：跟随玩家
	_npc_girl = NPCGirlClass.new()
	_npc_girl.name = "NPCGirl"
	_npc_girl.global_position = Vector2(150, 300)
	add_child(_npc_girl)

	# 男伴：跟随玩家
	_npc_boy = NPCBoyClass.new()
	_npc_boy.name = "NPCBoy"
	_npc_boy.global_position = Vector2(130, 320)
	add_child(_npc_boy)

	# 开朗NPC
	_npc_cheer = NPCCheerClass.new()
	_npc_cheer.name = "NPCCheer"
	_npc_cheer.global_position = Vector2(160, 280)
	add_child(_npc_cheer)

	# 高冷NPC
	_npc_cool = NPCCoolClass.new()
	_npc_cool.name = "NPCCool"
	_npc_cool.global_position = Vector2(170, 340)
	add_child(_npc_cool)

	print("[Level2] 五名路人已生成")

# ============================================================
# 高跟鞋怪物
# ============================================================

func _spawn_heel_monster() -> void:
	_heel_monster = HeelMonsterClass.new()
	_heel_monster.name = "HeelMonster"
	_heel_monster.global_position = Vector2(500, 50)
	add_child(_heel_monster)
	_heel_monster.target_killed.connect(_on_heel_target_killed)
	print("[Level2] 高跟鞋怪物已生成")

# ============================================================
# 电梯门
# ============================================================

func _spawn_elevator_door() -> void:
	_elevator_door = InteractableClass.new()
	_elevator_door.name = "ElevatorDoor"
	_elevator_door.global_position = Vector2(1000, 300)
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
	visual.color = Color(0.5, 0.5, 0.55, 1.0)
	visual.size = Vector2(36, 76)
	visual.position = Vector2(-18, -38)
	_elevator_door.add_child(visual)
	_elevator_door.interacted.connect(_on_elevator_interacted)

# ============================================================
# 道具
# ============================================================

func _spawn_items() -> void:
	_spawn_physical_item("rule_page_2", Vector2(600, 350), Color(0.7, 0.6, 0.4, 0.9))
	_spawn_physical_item("rule_page_3", Vector2(800, 250), Color(0.7, 0.6, 0.4, 0.9))

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

# ============================================================
# 剧情状态机（每帧推进）
# ============================================================

func _process(delta: float) -> void:
	_phase_timer += delta
	match _phase:
		Phase.EXPLORATION:
			_update_exploration()
		Phase.STRAY_DYING:
			pass  # HeelMonster 自动处理
		Phase.STRAY_DEAD:
			_update_stray_dead()
		Phase.ARGUMENT:
			_update_argument()
		Phase.GIRL_RUNNING:
			_update_girl_running(delta)
		Phase.GIRL_DEAD:
			_update_girl_dead()
		Phase.CHEER_IN_DANGER:
			_update_cheer_in_danger()
		Phase.CHEER_SAVED:
			pass  # 等待电梯
		Phase.ELEVATOR_ESCAPE:
			pass

# ============================================================
# 阶段：初始探索
# 胆小男路人在死胡同→自动被 HeelMonster 锁定（因为离群）
# ============================================================

func _update_exploration() -> void:
	# 当玩家走到 x=300 且胆小男已被锁定，推进剧情
	if _player.global_position.x >= 250.0:
		_set_phase(Phase.STRAY_DYING)

func _set_phase(new_phase: Phase) -> void:
	_phase = new_phase
	_phase_timer = 0.0
	print("[Level2] 剧情阶段: %s" % Phase.keys()[new_phase])

# ============================================================
# 高跟鞋杀死目标回调
# ============================================================

func _on_heel_target_killed(target: Node) -> void:
	if target == _npc_stray:
		_on_stray_killed()
	elif target == _npc_girl:
		_on_girl_killed()
	elif target == _npc_cheer:
		_on_cheer_killed()

func _on_stray_killed() -> void:
	if _phase == Phase.STRAY_DYING or _phase == Phase.EXPLORATION:
		_set_phase(Phase.STRAY_DEAD)

func _on_girl_killed() -> void:
	if _phase == Phase.GIRL_RUNNING:
		_set_phase(Phase.GIRL_DEAD)

func _on_cheer_killed() -> void:
	# 开朗NPC死亡→游戏结束
	GameManager.trigger_game_over("开朗NPC被高跟鞋击杀")

# ============================================================
# 阶段：胆小男已死 → 发现 + 争吵
# ============================================================

func _update_stray_dead() -> void:
	if _stray_death_shown:
		return
	_stray_death_shown = true

	# 显示死亡叙事
	var hud_node := get_node_or_null("Level2HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("惨剧", """[color=#ff4444]走廊深处传来一阵凄厉的惨叫声…[/color]

[color=#aaaaaa]你们赶到时，胆小的男路人已经倒在地上。
胸口有一个高跟鞋形状的贯穿伤。

他留在电梯口没有跟上队伍…
离群了。[/color]

[color=#888888]（但此时，规则纸条上还没有显示对应规则……）[/color]""")

	# 延迟后推进到争吵阶段
	await get_tree().create_timer(3.0).timeout
	if _phase == Phase.STRAY_DEAD:
		_set_phase(Phase.ARGUMENT)

# ============================================================
# 阶段：男女伴争吵
# ============================================================

func _update_argument() -> void:
	if _phase_timer < 0.5:
		return
	_set_phase(Phase.GIRL_RUNNING)

	# 对话
	var hud_node := get_node_or_null("Level2HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("争吵", """[color=#e8d8b0]男伴：[/color] 别乱跑，跟着阿柚！
[color=#e8d8b0]女伴：[/color] 我受够了，这里有鬼，我要自己找出口！

[color=#aaaaaa]女伴推开男伴，头也不回地向走廊深处跑去……[/color]

[color=#888888]（就在这时，规则纸条上缓缓渗出一行新字……）[/color]

[color=#ff6b6b]"禁止离群 — 第二层"[/color]

[color=#ff4444]但为时已晚。[/color]""")

	# 揭示规则
	RuleSystem.reveal_rule("rule_禁离群")

# ============================================================
# 阶段：女伴逃跑（自动向走廊深处移动，被 HeelMonster 锁定）
# ============================================================

func _update_girl_running(delta: float) -> void:
	if _npc_girl == null or not is_instance_valid(_npc_girl):
		return
	# 女伴向右上方死胡同逃跑
	_npc_girl.global_position.x += 80.0 * delta
	_npc_girl.global_position.y -= 30.0 * delta

# ============================================================
# 阶段：女伴已死 → 开朗NPC落单
# ============================================================

func _update_girl_dead() -> void:
	if _phase_timer < 1.0:
		return

	var hud_node := get_node_or_null("Level2HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("又一个…", """[color=#ff4444]高跟鞋声越来越近…[/color]

[color=#e8d8b0]女伴：[/color] 救……救命……啊……

[color=#aaaaaa]（寂静）[/color]

[color=#888888]队伍陷入绝望。
就在这时，你注意到开朗NPC不知何时也落了单……[/color]""")

	# 让开朗NPC落单（移至远离队伍的位置，触发离群判定）
	if _npc_cheer != null and is_instance_valid(_npc_cheer):
		_npc_cheer.global_position = Vector2(700, 350)

	_set_phase(Phase.CHEER_IN_DANGER)
	GameManager.update_objective("救出开朗NPC！")

# ============================================================
# 阶段：开朗NPC危险 → 玩家抉择
# GDD：有耳塞→交给她屏蔽 / 无耳塞→123木头人
# ============================================================

func _update_cheer_in_danger() -> void:
	if _phase_timer < 2.0:
		return

	var has_earplug: bool = ItemSystem.has_item("earplug")

	var hud_node := get_node_or_null("Level2HUD")
	if has_earplug:
		# 有耳塞路线
		if hud_node and hud_node.has_method("show_reading_panel"):
			hud_node.show_reading_panel("抉择", """[color=#aaaaaa]高跟鞋声越来越近……
开朗NPC颤抖着蹲在墙角。[/color]

[color=#e8d8b0]你掏出了之前在街上捡到的[color=#ffdd00]耳塞[/color]，
塞进了她的耳朵里。[/color]

[color=#aaaaaa]高跟鞋的脚步声……
在她的世界里消失了。

锁定判定被屏蔽。[/color]

[color=#88ff88]开朗NPC得救了。[/color]""")
		# 消耗耳塞
		ItemSystem.remove_item("earplug")
	else:
		# 无耳塞路线：123木头人
		if hud_node and hud_node.has_method("show_reading_panel"):
			hud_node.show_reading_panel("抉择", """[color=#aaaaaa]高跟鞋声越来越近……
开朗NPC颤抖着，不知所措。[/color]

[color=#e8d8b0]你：[/color] 听我说！高跟鞋是根据步伐锁定的！
[color=#e8d8b0]你：[/color] 只要你不动——它就不会落下！

[color=#aaaaaa]开朗NPC咬紧牙关，
像玩"123木头人"一样僵在原地。

高跟鞋声…停了。

它在等。
她也在等。[/color]

[color=#88ff88]只要坚持不动，她就安全！[/color]""")

	_set_phase(Phase.CHEER_SAVED)
	GameManager.update_objective("快！带所有人冲进电梯！")

	# 2秒后自动冲向电梯
	await get_tree().create_timer(2.0).timeout
	_set_phase(Phase.ELEVATOR_ESCAPE)

# ============================================================
# 电梯交互
# ============================================================

func _on_elevator_interacted(_interactor: Node) -> void:
	if _transitioning:
		return
	if _phase < Phase.CHEER_SAVED:
		var hud_node := get_node_or_null("Level2HUD")
		if hud_node and hud_node.has_method("update_counter_state_hint"):
			hud_node.update_counter_state_hint("现在还不能走——同伴还在危险中！")
		return

	_transitioning = true

	var hud_node := get_node_or_null("Level2HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("极限逃生", """[color=#aaaaaa]你一把抓住开朗NPC的手，
众人拼命冲向电梯——

高跟鞋声在身后疯狂加速！

电梯门在最后一刻关上。[/color]

[color=#88ff88]安全了……暂时。[/color]

[color=#888888]电梯继续向上……[/color]""")

	await get_tree().create_timer(3.0).timeout
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
	print("[Level2] 切换至 Level3Controller.tscn ...")
	get_tree().change_scene_to_file("res://levels/Level3Controller.tscn")
