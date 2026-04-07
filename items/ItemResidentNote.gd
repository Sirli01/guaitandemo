class_name ItemResidentNote
extends Item

signal lore_item_read(item_id: String, content: String)

@export var note_content: String = ""

func _init() -> void:
	item_id = "resident_note"
	display_name = "公寓住户遗书（第X封）"
	item_type = ItemType.LORE
	description = "已故住户留下的遗书，记载着公寓深处的秘密。"
	is_key_item = true

func use(_target: Node) -> void:
	lore_item_read.emit(item_id, note_content)
	GameManager.on_lore_read(item_id, note_content)
	print("[ItemResidentNote] 阅读住户遗书：%s" % note_content)
