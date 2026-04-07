class_name ItemAyouID
extends Item

signal key_clue_found(clue_id: String)

func _init() -> void:
	item_id = "ayou_id_card"
	display_name = "阿柚的身份证"
	item_type = ItemType.LORE
	description = "照片上的眼睛是深棕色瞳孔。"
	is_key_item = true

func use(_target: Node) -> void:
	key_clue_found.emit("ayou_brown_pupils")
a	lore_item_read.emit(item_id, description)
	print("[ItemAyouID] 发现关键线索：ayou_brown_pupils")
