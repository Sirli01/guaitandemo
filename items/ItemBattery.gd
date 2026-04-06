class_name ItemBattery
extends Item

func _init() -> void:
	item_id = "battery"
	display_name = "电池"
	item_type = ItemType.SURVIVAL
	description = "为手电筒续电，每节供电10分钟。"
	is_key_item = false

func use(target: Node) -> void:
	var inv: Array = ItemSystem.get_inventory()
	var flashlight: ItemFlashlight = null
	for it: Item in inv:
		if it.item_id == "flashlight":
			flashlight = it as ItemFlashlight
			break
	if flashlight == null:
		print("[ItemBattery] 需要先拾取手电筒")
		return
	flashlight.add_battery(600.0)
	ItemSystem.remove_item(item_id)
