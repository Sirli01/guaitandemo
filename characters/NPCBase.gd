extends CharacterBody2D
class_name NPCBase

# ============================================================
# 信号定义
# ============================================================
signal state_changed(new_state: String)
signal npc_died(npc: Node)

# ============================================================
# 基础属性
# ============================================================
var npc_id: String = ""
var display_name: String = "NPC"
var is_alive: bool = true
var npc_color: Color = Color(0.7, 0.5, 0.3, 1.0)

# ============================================================
# 状态机
# ============================================================
var current_state: String = "idle"

# ============================================================
# 视觉占位
# ============================================================
var _visual: ColorRect = null

# ============================================================
# 初始化
# ============================================================

func _init() -> void:
	add_to_group("npc")

func _ready() -> void:
	_setup_collision()
	_setup_visual()
	print("[NPCBase] %s 已生成，状态: %s" % [display_name, current_state])

func _setup_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 15.0
	collision.shape = shape
	add_child(collision)

func _setup_visual() -> void:
	_visual = ColorRect.new()
	_visual.name = "NPCVisual"
	_visual.color = npc_color
	_visual.custom_minimum_size = Vector2(30, 30)
	_visual.position = Vector2(-15, -15)
	add_child(_visual)

# ============================================================
# 状态机
# ============================================================

func set_state(new_state: String) -> void:
	if new_state == current_state:
		return
	current_state = new_state
	state_changed.emit(new_state)
	print("[NPCBase] %s 状态切换: %s" % [display_name, new_state])

# ============================================================
# 死亡逻辑
# ============================================================

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	print("[NPC] %s 死亡！" % display_name)
	npc_died.emit(self)

	if _visual != null:
		_visual.color = Color.RED
		_visual.modulate = Color(1.0, 0.0, 0.0, 1.0)

	await get_tree().create_timer(0.5).timeout
	queue_free()
