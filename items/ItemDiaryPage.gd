class_name ItemDiaryPage
extends Item

signal lore_item_read(item_id: String, content: String)

@export var page_content: String = ""

func _init() -> void:
	item_id = "diary_page"
	display_name = "妹妹的日记残页（第X页）"
	item_type = ItemType.LORE
	description = "妹妹的私人日记，请谨慎阅读。"
	is_key_item = true

func use(_target: Node) -> void:
	lore_item_read.emit(item_id, page_content)
	GameManager.on_lore_read(item_id, page_content)
	print("[ItemDiaryPage] 阅读日记残页：%s" % page_content)
