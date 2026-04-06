class_name ItemEarplug
extends Item

signal earplug_equipped
signal earplug_unequipped

var is_wearing: bool = false

func _init() -> void:
	item_id = "earplug"
	display_name = "隔音耳塞"
	item_type = ItemType.COMBAT
	description = "戴上后完全屏蔽「高跟鞋声」规则触发，听到高跟鞋声不会被怪物锁定。每层仅1个。"
	is_key_item = false

func use(target: Node) -> void:
	is_wearing = not is_wearing
	if is_wearing:
		earplug_equipped.emit()
		print("[ItemEarplug] 戴上隔音耳塞，高跟鞋声检测已屏蔽")
	else:
		earplug_unequipped.emit()
		print("[ItemEarplug] 摘下隔音耳塞，高跟鞋声检测已恢复")
