class_name ItemWater
extends Item

func _init() -> void:
	item_id = "water_bottle"
	display_name = "瓶装矿泉水"
	item_type = ItemType.SURVIVAL
	description = "恢复25%水分饱食度。走廊和房间随处可见。"
	is_key_item = false

func use(target: Node) -> void:
	target.restore_water(25)
	print("[ItemWater] %s 使用了瓶装矿泉水，水分恢复 25" % target.name)
	ItemSystem.remove_item(item_id)
