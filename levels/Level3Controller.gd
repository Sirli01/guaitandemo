extends Node2D
class_name Level3Controller

# ============================================================
# 第三层：绝境逆转，借刀杀鬼 (Floor 3)
# GDD：
# - 规则："禁止跑步 — 第三层"
# - 人形怪物：只能慢速走路追杀玩家
# - 深渊巨口：有人跑步就冲出吞噬
# - 男伴惊慌失措跑步→被巨口吞噬（自动触发）
# - 玩家察觉"禁止对视"没标注只在第一层！
# - 有绳子→让队友绑住自己肉身→与怪物对视→灵魂夺舍→
#   操控怪物跑步→巨口吞噬→07:00灵魂弹回→反杀成功
# - 无绳子→潜行逃生路线
# ============================================================

enum CutscenePhase {
	NONE,
	BOY_PANICS,          # 男伴惊慌
	BOY_RUNS,            # 男伴跑步
	BOY_DEVOURED,        # 男伴被吞噬
	DESPAIR,             # 绝望
	ROPE_CHECK,          # 检查道具
	BIND_SELF,           # 绑住自己
	SOUL_SWAP,           # 灵魂互换
	CONTROLLING_MONSTER,  # 操控怪物跑步
	BIGMOUTH_ATTACK,     # 巨口吞噬怪物
	SOUL_RETURN,         # 07:00 灵魂弹回
	VICTORY,             # 反杀成功
	STEALTH_ESCAPE,      # 无绳子：潜行逃生
	TO_ENDING,           # 进入结局
}

const PlayerClass = preload("res://characters/Player.gd")
const InteractableClass = preload("res://items/Interactable.gd")
const PhysicalItemClass = preload("res://items/PhysicalItem.gd")
const HUDClass = preload("res://ui/HUD.gd")
const InventoryUIClass = preload("res://ui/InventoryUI.gd")
const HumanMonsterClass = preload("res://characters/HumanMonster.gd")
const BigMouthClass = preload("res://characters/BigMouth.gd")
const NPCBoyClass = preload("res://characters/NPCBoy.gd")
const NPCCheerClass = preload("res://characters/NPCCheer.gd")
const NPCCoolClass = preload("res://characters/NPCCool.gd")

var _player: Node = null
var _hud: Node = null
var _inventory_ui: Node = null
var _human_monster: Node = null
var _big_mouth: Node = null
var _elevator_door: Node = null

# NPC（从第二层活下来的）
var _npc_boy: Node = null
var _npc_cheer: Node = null
var _npc_cool: Node = null

# 剧情状态
var _cutscene: CutscenePhase = CutscenePhase.NONE
var _cutscene_timer: float = 0.0
var _player_input_locked: bool = false
var _transitioning: bool = false
var _smart_route: bool = false

func _ready() -> void:
	_build_geometry()
	_spawn_player()
	_spawn_hud()
	_spawn_inventory_ui()
	_spawn_npcs()
	_spawn_human_monster()
	_spawn_big_mouth()
	_spawn_elevator_door()
	_spawn_items()

	# 揭示本层规则
	RuleSystem.reveal_rule("rule_禁跑步3F")

	GameManager.update_objective("在不跑步的情况下，找到出路")
	print("[Level3] 第三层就绪 — 终极考验开始")

	# 3秒后自动触发男伴惊慌剧情
	await get_tree().create_timer(3.0).timeout
	_start_cutscene(CutscenePhase.BOY_PANICS)

# ============================================================
# 几何地形
# ============================================================

func _build_geometry() -> void:
	var wall_color := Color(0.15, 0.12, 0.18, 1.0)
	var floor_color := Color(0.10, 0.08, 0.10, 1.0)

	# 宽敞的走廊
	_spawn_floor(Vector2(500, 300), Vector2(800, 350), floor_color)

	# 四面墙壁
	_spawn_wall(Vector2(100, 300), Vector2(20, 350), wall_color)   # 左
	_spawn_wall(Vector2(900, 300), Vector2(20, 350), wall_color)   # 右
	_spawn_wall(Vector2(500, 120), Vector2(800, 20), wall_color)   # 上
	_spawn_wall(Vector2(500, 480), Vector2(800, 20), wall_color)   # 下

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
	_player.global_position = Vector2(200, 300)
	add_child(_player)
	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	_player.add_child(camera)
	camera.make_current()

func _spawn_hud() -> void:
	_hud = HUDClass.new()
	_hud.name = "Level3HUD"
	add_child(_hud)

func _spawn_inventory_ui() -> void:
	_inventory_ui = InventoryUIClass.new()
	_inventory_ui.name = "Level3InventoryUI"
	add_child(_inventory_ui)

# ============================================================
# NPC（男伴、开朗NPC、高冷NPC）
# ============================================================

func _spawn_npcs() -> void:
	_npc_boy = NPCBoyClass.new()
	_npc_boy.name = "NPCBoy"
	_npc_boy.global_position = Vector2(250, 350)
	add_child(_npc_boy)

	_npc_cheer = NPCCheerClass.new()
	_npc_cheer.name = "NPCCheer"
	_npc_cheer.global_position = Vector2(180, 280)
	add_child(_npc_cheer)

	_npc_cool = NPCCoolClass.new()
	_npc_cool.name = "NPCCool"
	_npc_cool.global_position = Vector2(220, 260)
	add_child(_npc_cool)

# ============================================================
# 人形怪物 + 深渊巨口
# ============================================================

func _spawn_human_monster() -> void:
	_human_monster = HumanMonsterClass.new()
	_human_monster.name = "HumanMonster"
	_human_monster.global_position = Vector2(750, 300)
	add_child(_human_monster)
	print("[Level3] 人形怪物已生成")

func _spawn_big_mouth() -> void:
	_big_mouth = BigMouthClass.new()
	_big_mouth.name = "BigMouth"
	_big_mouth.global_position = Vector2(500, 450)
	_big_mouth.set_active_floor("Level3")
	add_child(_big_mouth)
	_big_mouth.player_devoured.connect(_on_player_devoured)
	print("[Level3] 深渊巨口已生成（隐藏状态）")

# ============================================================
# 电梯门（通关后可用）
# ============================================================

func _spawn_elevator_door() -> void:
	_elevator_door = InteractableClass.new()
	_elevator_door.name = "ElevatorDoor"
	_elevator_door.global_position = Vector2(150, 300)
	_elevator_door.interaction_hint = "电梯被封锁了"
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
	visual.color = Color(0.4, 0.4, 0.45, 1.0)
	visual.size = Vector2(36, 76)
	visual.position = Vector2(-18, -38)
	_elevator_door.add_child(visual)
	_elevator_door.interacted.connect(_on_elevator_interacted)

# ============================================================
# 道具
# ============================================================

func _spawn_items() -> void:
	_spawn_physical_item("rule_page_4", Vector2(400, 200), Color(0.7, 0.6, 0.4, 0.9))
	_spawn_physical_item("rule_page_5", Vector2(600, 400), Color(0.7, 0.6, 0.4, 0.9))

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
# 巨口吞噬回调
# ============================================================

func _on_player_devoured() -> void:
	# 如果是在操控怪物阶段，巨口吞的是怪物而不是玩家
	if _cutscene == CutscenePhase.CONTROLLING_MONSTER:
		_start_cutscene(CutscenePhase.BIGMOUTH_ATTACK)
	# 否则是真正的游戏结束（但 BigMouth 内部已处理）

# ============================================================
# 过场动画状态机
# ============================================================

func _process(delta: float) -> void:
	if _cutscene == CutscenePhase.NONE:
		return
	_cutscene_timer += delta
	match _cutscene:
		CutscenePhase.BOY_PANICS:
			_update_boy_panics()
		CutscenePhase.BOY_RUNS:
			_update_boy_runs(delta)
		CutscenePhase.BOY_DEVOURED:
			_update_boy_devoured()
		CutscenePhase.DESPAIR:
			_update_despair()
		CutscenePhase.ROPE_CHECK:
			_update_rope_check()
		CutscenePhase.BIND_SELF:
			_update_bind_self()
		CutscenePhase.SOUL_SWAP:
			_update_soul_swap()
		CutscenePhase.CONTROLLING_MONSTER:
			_update_controlling_monster(delta)
		CutscenePhase.BIGMOUTH_ATTACK:
			_update_bigmouth_attack()
		CutscenePhase.SOUL_RETURN:
			_update_soul_return()
		CutscenePhase.VICTORY:
			_update_victory()
		CutscenePhase.STEALTH_ESCAPE:
			_update_stealth_escape()
		CutscenePhase.TO_ENDING:
			pass

func _start_cutscene(phase: CutscenePhase) -> void:
	_cutscene = phase
	_cutscene_timer = 0.0
	print("[Level3] 过场: %s" % CutscenePhase.keys()[phase])

# ============================================================
# 过场：男伴惊慌
# ============================================================

func _update_boy_panics() -> void:
	if _cutscene_timer < 0.5:
		return
	_lock_player_input()

	var hud_node := get_node_or_null("Level3HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("恐慌", """[color=#aaaaaa]人形怪物从走廊深处缓步走来……

规则写着"禁止跑步"。
但恐惧笼罩了所有人。[/color]

[color=#e8d8b0]男伴[/color]（声音颤抖）：不…不行了…我要跑…

[color=#ff6b6b]男伴拔腿就跑！[/color]""")

	_start_cutscene(CutscenePhase.BOY_RUNS)

# ============================================================
# 过场：男伴跑步 → 巨口吞噬
# ============================================================

func _update_boy_runs(delta: float) -> void:
	if _npc_boy == null or not is_instance_valid(_npc_boy):
		return
	if _cutscene_timer < 2.0:
		# 男伴向右跑
		_npc_boy.global_position.x += 150.0 * delta
		return

	# 2秒后巨口吞噬
	_start_cutscene(CutscenePhase.BOY_DEVOURED)
	if _npc_boy != null and is_instance_valid(_npc_boy):
		_npc_boy.die()
		_npc_boy = null

func _update_boy_devoured() -> void:
	if _cutscene_timer < 0.5:
		return

	var hud_node := get_node_or_null("Level3HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("吞噬", """[color=#ff4444]地板裂开——[/color]

[color=#aaaaaa]一张巨大的嘴从地面冲出，
瞬间将奔跑中的男伴吞入黑暗深渊。[/color]

[color=#e8d8b0]开朗NPC[/color]：不！！！

[color=#888888]"禁止跑步"……不是开玩笑的。

前方，人形怪物依然在缓步逼近。
不能跑，不能退。
怎么办？[/color]""")

	_start_cutscene(CutscenePhase.DESPAIR)

# ============================================================
# 过场：绝望 → 道具检查
# ============================================================

func _update_despair() -> void:
	if _cutscene_timer < 3.0:
		return
	_start_cutscene(CutscenePhase.ROPE_CHECK)

func _update_rope_check() -> void:
	if _cutscene_timer < 0.5:
		return

	_smart_route = ItemSystem.has_item("rope")

	if _smart_route:
		# GDD 高光路线：有绳子
		var hud_node := get_node_or_null("Level3HUD")
		if hud_node and hud_node.has_method("show_reading_panel"):
			hud_node.show_reading_panel("逆转的希望", """[color=#aaaaaa]你低头看着手中的规则纸条，
一行字引起了你的注意——[/color]

[color=#ffdd00]"23:00-07:00，禁止对视"[/color]

[color=#aaaaaa]等等……
这条规则……[color=#ff6b6b]没有标注只在第一层生效！[/color]

对视 = 灵魂互换。
跑步 = 巨口吞噬。

如果……[/color]

[color=#88ff88]如果我和怪物互换灵魂，
操控它的身体去跑步——
巨口吞掉的就是怪物的身体！

而到了 07:00，灵魂会强制弹回原主！

但我需要让同伴把我的肉身绑住，
确保互换期间我的身体安全……[/color]

[color=#ffdd00]你掏出了绳子。[/color]""")

		_start_cutscene(CutscenePhase.BIND_SELF)
	else:
		# 无绳子：潜行逃生
		var hud_node := get_node_or_null("Level3HUD")
		if hud_node and hud_node.has_method("show_reading_panel"):
			hud_node.show_reading_panel("潜行", """[color=#aaaaaa]没有绳子……
没有办法安全地进行灵魂互换。

只能慢慢绕过人形怪物，
找到另一条出路。[/color]

[color=#888888]你小心翼翼地贴着墙壁移动……[/color]""")

		_start_cutscene(CutscenePhase.STEALTH_ESCAPE)

# ============================================================
# 过场：绑住自己（智斗路线）
# ============================================================

func _update_bind_self() -> void:
	if _cutscene_timer < 3.0:
		return

	var hud_node := get_node_or_null("Level3HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("赌上一切", """[color=#e8d8b0]你：[/color] 听我说，把我绑在这根柱子上。
[color=#e8d8b0]高冷NPC：[/color] 你疯了吗？
[color=#e8d8b0]你：[/color] 相信我。不管发生什么，
[color=#ff6b6b]不要解开绳子。[/color]

[color=#aaaaaa]开朗NPC颤抖着接过绳子，
把你的身体牢牢绑在了走廊的立柱上。[/color]

[color=#888888]现在……面对那个怪物。
直视它的眼睛。[/color]""")

	# 消耗绳子
	ItemSystem.remove_item("rope")
	_start_cutscene(CutscenePhase.SOUL_SWAP)

# ============================================================
# 过场：灵魂互换
# ============================================================

func _update_soul_swap() -> void:
	if _cutscene_timer < 3.0:
		return

	# 执行灵魂互换
	if _human_monster != null and _player != null:
		RuleSystem.do_swap(_human_monster, _player)

	var hud_node := get_node_or_null("Level3HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("灵魂夺舍", """[color=#ff6b6b]你注视着人形怪物的眼睛——[/color]

[color=#aaaaaa]世界在扭曲。
视野模糊，天旋地转。

当你再次睁开眼睛时……
你看到的是——自己的身体。
被绑在柱子上的、自己的身体。[/color]

[color=#ffdd00]灵魂互换成功。
你现在在怪物的躯体里。[/color]

[color=#88ff88]现在——跑！[/color]""")

	_start_cutscene(CutscenePhase.CONTROLLING_MONSTER)

# ============================================================
# 过场：操控怪物跑步（触发巨口）
# ============================================================

func _update_controlling_monster(delta: float) -> void:
	if _cutscene_timer < 3.0:
		return

	if _cutscene_timer < 5.0:
		# 操控怪物向右跑
		if _human_monster != null and is_instance_valid(_human_monster):
			_human_monster.global_position.x += 200.0 * delta

		if _cutscene_timer >= 4.0:
			# 巨口出现！
			_start_cutscene(CutscenePhase.BIGMOUTH_ATTACK)
		return

func _update_bigmouth_attack() -> void:
	if _cutscene_timer < 0.5:
		return

	var hud_node := get_node_or_null("Level3HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("反杀", """[color=#ff4444]地板再次裂开——[/color]

[color=#aaaaaa]巨口从地底冲出，
张开大嘴扑向正在狂奔的——
[color=#ffdd00]怪物的躯体[/color]。

就在巨口合上的瞬间——[/color]

[color=#88ff88]时钟指向 07:00。[/color]

[color=#ffdd00]灵魂强制弹回。[/color]

[color=#aaaaaa]你的意识被猛地拽回，
回到了被绳子绑在柱子上的自己的身体里。[/color]

[color=#88ff88]利用规则，兵不血刃。
人形怪物——被永远吞入深渊。[/color]""")

	# 销毁怪物
	if _human_monster != null and is_instance_valid(_human_monster):
		_human_monster.queue_free()
		_human_monster = null

	_start_cutscene(CutscenePhase.SOUL_RETURN)

# ============================================================
# 过场：灵魂弹回 → 胜利
# ============================================================

func _update_soul_return() -> void:
	if _cutscene_timer < 3.0:
		return
	_start_cutscene(CutscenePhase.VICTORY)

func _update_victory() -> void:
	if _cutscene_timer < 0.5:
		return

	# 解锁电梯
	_elevator_door.interaction_hint = "进入电梯（出口已解封）"
	_unlock_player_input()

	var hud_node := get_node_or_null("Level3HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("解放", """[color=#88ff88]人形怪物被巨口彻底吞噬。
电梯口的封锁解除了。[/color]

[color=#aaaaaa]幸存的你、高冷NPC、开朗NPC
喘着粗气，互相搀扶着站起来。[/color]

[color=#888888]前方就是通往出口的电梯。
离开这里吧。[/color]""")

	GameManager.update_objective("走进电梯，离开这栋公寓")
	_start_cutscene(CutscenePhase.TO_ENDING)

# ============================================================
# 潜行逃生路线（无绳子）
# ============================================================

func _update_stealth_escape() -> void:
	if _cutscene_timer < 3.0:
		return

	_elevator_door.interaction_hint = "进入电梯"
	_unlock_player_input()

	var hud_node := get_node_or_null("Level3HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("勉强逃脱", """[color=#aaaaaa]你们贴着墙壁，
一步一步缓缓移动，
从人形怪物的视线死角绕了过去。

电梯就在前方。[/color]

[color=#888888]但你总觉得…
这不是最好的结局。[/color]""")

	GameManager.update_objective("走进电梯")
	_start_cutscene(CutscenePhase.TO_ENDING)

# ============================================================
# 电梯交互 → 进入结局
# ============================================================

func _on_elevator_interacted(_interactor: Node) -> void:
	if _transitioning:
		return
	if _cutscene != CutscenePhase.TO_ENDING:
		var hud_node := get_node_or_null("Level3HUD")
		if hud_node and hud_node.has_method("update_counter_state_hint"):
			hud_node.update_counter_state_hint("电梯被封锁了，必须先解决威胁")
		return

	_transitioning = true
	_trigger_ending_elevator()

func _trigger_ending_elevator() -> void:
	var hud_node := get_node_or_null("Level3HUD")
	if hud_node and hud_node.has_method("show_reading_panel"):
		hud_node.show_reading_panel("电梯", """[color=#aaaaaa]众人走进了通往出口的电梯。
电梯门缓缓关上。

你终于松了一口气……[/color]

[color=#888888]电梯开始运行。[/color]""")

	await get_tree().create_timer(3.0).timeout
	_fade_to_ending()

func _fade_to_ending() -> void:
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
	print("[Level3] 切换至 SuspenseEnding.tscn ...")
	get_tree().change_scene_to_file("res://levels/SuspenseEnding.tscn")

# ============================================================
# 输入锁定（过场动画期间）
# ============================================================

func _lock_player_input() -> void:
	if _player_input_locked:
		return
	_player_input_locked = true
	if _player != null:
		_player.set_process_input(false)
		_player.set_physics_process(false)

func _unlock_player_input() -> void:
	if not _player_input_locked:
		return
	_player_input_locked = false
	if _player != null:
		_player.set_process_input(true)
		_player.set_physics_process(true)
