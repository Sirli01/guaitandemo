class_name ItemChildhoodPhoto
extends Item

signal key_clue_found(clue_id: String)
signal lore_item_read(item_id: String, content: String)

func _init() -> void:
	item_id = "childhood_photo"
	display_name = "姐妹童年合照"
	item_type = ItemType.LORE
	description = "两人都露出同款浅金色瞳孔。"
	is_key_item = true

func use(_target: Node) -> void:
	key_clue_found.emit("sisters_gold_pupils")
	GameManager.on_lore_read(item_id, description)
	print("[ItemChildhoodPhoto] 发现关键线索：sisters_gold_pupils")
