class_name ItemEnergyDrink
extends Item

func _init() -> void:
	item_id = "energy_drink"
	display_name = "功能饮料"
	item_type = ItemType.SURVIVAL
	description = "恢复20%水分 + 临时提升行动体力上限30%，持续5分钟，跑步速度+20%。全楼仅2瓶。"
	is_key_item = false

func use(target: Node) -> void:
	target.restore_water(20)
	target.apply_stamina_drink()
	print("[ItemEnergyDrink] %s 使用了功能饮料，水分恢复 20，体力上限提升 30%% 持续 300 秒" % target.name)
	ItemSystem.remove_item(item_id)
