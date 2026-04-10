extends Node2D

# ============================================================
# 第一层：诡异初现与致命伏笔 (Floor 1)
# GDD：
# - 玩家与路人们聚集，寻找电梯卡
# - 23:00 异变触发：女伴被镜子吸引→对视→灵魂互换伏笔
#   男伴察觉 "你不是左撇子吗？为什么在用右手？"
# - 规则纸条揭示："23:00-07:00，禁止对视"
# - 拿到电梯卡后，电梯"只会向上"→进入第二层
# ============================================================

const PlayerClass = preload("res://characters/Player.gd")
const InteractableClass = preload("res://items/Interactable.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")
const HUDClass = preload("res://ui/HUD.gd")
const InventoryUIClass = preload("res://ui/InventoryUI.gd")
const NPCGirlClass = preload("res://characters/NPCGirl.gd")
const NPCBoyClass = preload("res://characters/NPCBoy.gd")
const NPCStrayClass = preload("res://characters/NPCStray.gd")
const NPCCheerClass = preload("res://characters/NPCCheer.gd")
const NPCCoolClass = preload("res://characters/NPCCool.gd")

var _player: Node = null
var _hud: Node = null
var _inventory_ui: Node = null
var _elevator_door: Node = null
var _mirror: Node = null

# NPC 引用
var _npc_girl: Node = null
var _npc_boy: Node = null
var _npc_stray: Node = null
var _npc_cheer: Node = null
var _npc_cool: Node = null

# 剧情状态
var _has_elevator_card: bool = false
var _mirror_event_triggered: bool = false
var _mirror_cutscene_done: bool = false
var _transitioning: bool = false

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_hud()
	_spawn_inventory_ui()
	_spawn_npcs()
	_spawn_mirror()
	_spawn_elevator_card()
	_spawn_elevator_door()
	_spawn_rule_page()
	GameManager.update_objective("探索公寓一层，寻找电梯卡")
	print("[Level1] 第一层就绪 — 所有路人已聚集")

# ============================================================
# 几何地形（宽敞的公寓大厅 + 走廊）
# ============================================================

func _build_geometry() -> void:
	var floor_color := Color(0.14, 0.12, 0.10, 1.0)
	var wall_color := Color(0.08, 0.08, 0.08, 1.0)

	# 大厅地板
	_spawn_floor(Vector2(500, 300), Vector2(800, 400), floor_color)

	# 四面墙壁
	_spawn_wall(Vector2(100, 300), Vector2(20, 400), wall_color)  # 左墙
	_spawn_wall(Vector2(900, 300), Vector2(20, 400), wall_color)  # 右墙
	_spawn_wall(Vector2(500, 100), Vector2(800, 20), wall_color)  # 上墙
	_spawn_wall(Vector2(500, 500), Vector2(800, 20), wall_color)  # 下墙

	# 大厅家具
	_spawn_furniture(Vector2(300, 280), Vector2(80, 50), Color(0.25, 0.2, 0.15))  # 沙发
	_spawn_furniture(Vector2(700, 200), Vector2(60, 40), Color(0.3, 0.25, 0.2))   # 柜子

	# 走廊通道（通向电梯，在右侧）
	_spawn_floor(Vector2(870, 300), Vector2(60, 120), Color(0.12, 0.10, 0.08, 1.0))

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

func _spawn_furniture(pos: Vector2, size: Vector2, color: Color) -> void:
	_spawn_wall(pos, size, color)

# ============================================================
# 玩家、HUD、背包
# ============================================================

func _spawn_player() -> void:
	_player = PlayerClass.new()
	_player.name = "Player"
	_player.global_position = Vector2(200, 400)
	add_child(_player)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	_player.add_child(camera)
	camera.make_current()

func _spawn_hud() -> void:
	_hud = HUDClass.new()
	_hud.name = "Level1HUD"
	add_child(_hud)

func _spawn_inventory_ui() -> void:
	_inventory_ui = InventoryUIClass.new()
	_inventory_ui.name = "Level1InventoryUI"
	add_child(_inventory_ui)

# ============================================================
# NPC 路人们（GDD：女伴、男伴、胆小男路人、开朗NPC、高冷NPC）
# ============================================================

func _spawn_npcs() -> void:
	_npc_girl = NPCGirlClass.new()
	_npc_girl.name = "NPCGirl"
	_npc_girl.global_position = Vector2(350, 350)
	add_child(_npc_girl)

	_npc_boy = NPCBoyClass.new()
	_npc_boy.name = "NPCBoy"
	_npc_boy.global_position = Vector2(380, 370)
	add_child(_npc_boy)

	_npc_stray = NPCStrayClass.new()
	_npc_stray.name = "NPCStray"
	_npc_stray.global_position = Vector2(250, 320)
	add_child(_npc_stray)

	_npc_cheer = NPCCheerClass.new()
	_npc_cheer.name = "NPCCheer"
	_npc_cheer.global_position = Vector2(400, 300)
	add_child(_npc_cheer)

	_npc_cool = NPCCoolClass.new()
	_npc_cool.name = "NPCCool"
	_npc_cool.global_position = Vector2(320, 280)
	add_child(_npc_cool)

	print("[Level1] 五名路人已生成")

# ============================================================
# 镜子（GDD 核心伏笔）
# ============================================================

func _spawn_mirror() -> void:
	_mirror = InteractableClass.new()
	_mirror.name = "Mirror"
	_mirror.global_position = Vector2(500, 115)
	_mirror.interaction_hint = "查看镜子"
	_mirror.collision_layer = 2
	_mirror.collision_mask = 0
	_mirror.monitorable = true
	add_child(_mirror)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 20)
	collision.shape = shape
	_mirror.add_child(collision)
	# 银色镜面
	var visual := ColorRect.new()
	visual.color = Color(0.6, 0.7, 0.8, 0.9)
	visual.size = Vector2(50, 15)
	visual.position = Vector2(-25, -7)
	_mirror.add_child(visual)
	_mirror.interacted.connect(_on_mirror_interacted)

func _on_mirror_interacted(_interactor: Node) -> void:
	if _mirror_event_triggered:
		return
	_mirror_event_triggered = true
	# 展示镜子对话
	var hud_node := get_node_or_null("Level1HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("镜子", """[color=#aaaaaa]你凑近镜子，看到了自己的倒影。

一切似乎正常...

但你注意到倒影中，
身后的女伴也在注视镜子。[/color]

[color=#ff6b6b]她的视线……对上了镜中的某个东西。[/color]""")

# ============================================================
# 电梯卡道具
# ============================================================

func _spawn_elevator_card() -> void:
	_spawn_physical_item("elevator_card_f1", Vector2(700, 200), Color(1.0, 0.85, 0.3, 1.0))

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
# 规则残页（第一页）
# ============================================================

func _spawn_rule_page() -> void:
	_spawn_physical_item("rule_page_1", Vector2(550, 400), Color(0.7, 0.6, 0.4, 0.9))

# ============================================================
# 电梯门（GDD：电梯只向上）
# ============================================================

func _spawn_elevator_door() -> void:
	_elevator_door = InteractableClass.new()
	_elevator_door.name = "ElevatorDoor"
	_elevator_door.global_position = Vector2(880, 300)
	_elevator_door.interaction_hint = "呼叫电梯（需要电梯卡）"
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

func _on_elevator_interacted(_interactor: Node) -> void:
	if _transitioning:
		return

	# 检查是否有电梯卡
	if not ItemSystem.has_item("elevator_card_f1"):
		var hud_node := get_node_or_null("Level1HUD")
		if hud_node and hud_node.has_method("update_counter_state_hint"):
			hud_node.update_counter_state_hint("需要电梯卡才能使用电梯")
		return

	_transitioning = true
	_trigger_elevator_cutscene()

# ============================================================
# 23:00 异变事件自动检测
# ============================================================

func _process(_delta: float) -> void:
	if not _mirror_cutscene_done and _mirror_event_triggered:
		_check_23_event()

func _check_23_event() -> void:
	if _mirror_cutscene_done:
		return
	# 当游戏时间到 23:00 时自动触发
	var hour: int = GameManager.get_game_hour()
	if hour >= 23 or hour < 7:
		_mirror_cutscene_done = true
		_trigger_mirror_anomaly()

func _trigger_mirror_anomaly() -> void:
	# GDD：女伴被镜子吸引对视，男伴察觉异常
	print("[Level1] 23:00 — 异变触发！")

	# 揭示规则
	RuleSystem.reveal_rule("rule_禁对视")

	# 延迟展示对话
	await get_tree().create_timer(1.0).timeout

	var hud_node := get_node_or_null("Level1HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("23:00 异变", """[color=#ff4444]时钟敲响 23:00。[/color]

[color=#e8d8b0]女伴[/color] 突然被走廊尽头的镜子吸引，
缓缓走过去，目光锁定…

[color=#e8d8b0]男伴[/color]（急促）：等等… 她怎么了？
[color=#e8d8b0]男伴[/color]：不对——你不是左撇子吗？
[color=#e8d8b0]男伴[/color]：[color=#ff6b6b]为什么在用右手？！[/color]

[color=#888888]（规则纸条缓缓浮现一行字：
"23:00 - 07:00，禁止对视"）[/color]""")

	GameManager.update_objective("找到电梯卡，离开一层")

# ============================================================
# 电梯过场（GDD：电梯只向上）
# ============================================================

func _trigger_elevator_cutscene() -> void:
	var hud_node := get_node_or_null("Level1HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("电梯", """[color=#aaaaaa]众人挤进老旧的电梯。

你按下了"1F"的按钮——没有反应。
按下"B1"——也没有反应。

只有向上的按钮亮着。[/color]

[color=#ff6b6b]这部电梯……只会向上。[/color]

[color=#888888]电梯开始缓缓上升…[/color]""")

	# 等玩家关闭阅读面板后切换场景
	await get_tree().create_timer(2.0).timeout
	_fade_to_level2()

func _fade_to_level2() -> void:
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
	print("[Level1] 切换至 Level2Controller.tscn ...")
	get_tree().change_scene_to_file("res://levels/Level2Controller.tscn")
