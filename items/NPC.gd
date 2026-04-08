extends Interactable
class_name NPC

@export var npc_name: String = "NPC"
@export var dialogue_lines: Array = []
@export var npc_color: Color = Color(0.7, 0.5, 0.3, 1.0)

var _dialogue_index: int = 0
var is_alive: bool = true

# ============================================================
# 死亡逻辑（供 HeelMonster 等系统调用）
# ============================================================

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	print("[NPC] %s 死亡！" % npc_name)

	# 变红视觉占位
	if has_node("NPCVisual"):
		var visual: Node = get_node("NPCVisual")
		visual.modulate = Color(1.0, 0.0, 0.0, 1.0)

	await get_tree().create_timer(0.5).timeout
	queue_free()

func _ready() -> void:
	super._ready()
	interaction_hint = "对话: %s" % npc_name
	add_to_group("npc")

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape
	add_child(collision)

	var visual := ColorRect.new()
	visual.name = "NPCVisual"
	visual.color = npc_color
	visual.size = Vector2(36, 36)
	visual.position = Vector2(-18, -18)
	add_child(visual)

	print("[NPC] %s 已生成，对话: %s" % [npc_name, dialogue_lines])

func interact(_interactor: Node) -> void:
	_show_dialogue()

func _on_interact(_interactor: Node) -> void:
	pass

func _show_dialogue() -> void:
	if _dialogue_index >= dialogue_lines.size():
		_dialogue_index = 0

	var line: String = dialogue_lines[_dialogue_index]
	print("[%s]: %s" % [npc_name, line])
	_interaction_feedback(line)

	_dialogue_index += 1

func _interaction_feedback(text: String) -> void:
	if has_node("InteractionArea"):
		return
	var label := Label.new()
	label.name = "InteractionArea"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1, 1, 1, 0)
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.position = Vector2(-100, -70)
	label.custom_minimum_size = Vector2(200, 40)
	add_child(label)

	_fade_label(label)

func _fade_label(label: Label) -> void:
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	await tween.finished
	if label.is_inside_tree():
		label.queue_free()
