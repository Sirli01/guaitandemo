extends Resource

class_name Item

enum ItemType { SURVIVAL, COMBAT, RULE_PAGE, LORE }

var item_id: String
var display_name: String
var item_type: ItemType
var description: String
var is_key_item: bool = false

func use(_target: Node) -> void:
	print("[Item] %s.use() 未被子类重写，请检查道具逻辑" % display_name)
