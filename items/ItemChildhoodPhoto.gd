class_name ItemChildhoodPhoto
extends Item

signal key_clue_found(clue_id: String)

func _init() -> void:
	item_id = "childhood_photo"
	display_name = "姐妹童年合照"
	item_type = ItemType.LORE
	description = "两人都露出同款浅金色瞳孔。"
	is_key_item = true

func use(_target: Node) -> void:
	key_clue_found.emit("sisters_gold_pupils")
	lore_item_read.emit(item_id, description)
	print("[ItemChildhoodPhoto] 发现关键线索：sisters_gold_pupils")
