class_name ItemSisterPhone
extends Item

signal key_clue_found(clue_id: String)

func _init() -> void:
	item_id = "sister_phone"
	display_name = "妹妹的手机备忘录"
	item_type = ItemType.LORE
	description = "记录了她和阿柚互换的准确时间，以及不敢告诉姐姐的心里话。"
	is_key_item = true

func use(_target: Node) -> void:
	key_clue_found.emit("swap_time_record")
	GameManager.on_lore_read(item_id, description)
	print("[ItemSisterPhone] 发现关键线索：swap_time_record，已通知 GameManager")
