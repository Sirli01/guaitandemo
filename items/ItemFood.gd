class_name ItemFood
extends Item

func _init() -> void:
	item_id = "food_ration"
	display_name = "压缩饼干"
	item_type = ItemType.SURVIVAL
	description = "恢复40%饱腹饱食度。房间柜子和冰箱里能找到。"
	is_key_item = false

func use(target: Node) -> void:
	target.restore_food(40)
	print("[ItemFood] %s 使用了压缩饼干，饱腹度恢复 40" % target.name)
	ItemSystem.remove_item(item_id)
