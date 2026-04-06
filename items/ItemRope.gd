class_name ItemRope
extends Item

signal rope_used(target: Node)

func _init() -> void:
	item_id = "rope"
	display_name = "麻绳"
	item_type = ItemType.COMBAT
	description = "核心道具。用于绑定怪物身体，配合对视触发灵魂互换反杀。全局仅1个，不可丢弃。"
	is_key_item = true

func use(target: Node) -> void:
	if not RuleSystem.is_forbidden_period():
		print("[ItemRope] 只有在禁对视时段才能使用麻绳")
		return
	target.bind_with_rope()
	rope_used.emit(target)
	print("[ItemRope] 麻绳绑定成功，现在可以安全对视触发互换")
