extends Area2D
class_name Interactable

signal interacted(interactor: Node)

@export var interaction_hint: String = "按 E 交互"

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("interactable_base")
	# ★ 设为可被 Area2D 的 area_entered 信号检测到
	collision_layer = 2
	collision_mask = 0
	monitorable = true

func interact(interactor: Node) -> void:
	interacted.emit(interactor)
	_on_interact(interactor)

# ============================================================
# 虚方法：子类重写实现具体交互逻辑
# ============================================================
func _on_interact(interactor: Node) -> void:
	print("[Interactable] %s 的 _on_interact 未被重写，请子类实现" % name)
