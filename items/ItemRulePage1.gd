class_name ItemRulePage1
extends Item

func _init() -> void:
	item_id = "rule_page_1"
	display_name = "规则残页（一）"
	item_type = ItemType.RULE_PAGE
	description = "禁对视时段基础规则：23:00至07:00，任何人与他人对视会触发灵魂互换。"
	is_key_item = true

func use(_target: Node) -> void:
	RuleSystem.unlock_rule("rule_basic_eye_contact")
	print("[RulePage1] 规则解锁：禁对视时段基础规则——23:00至07:00，任何人与他人对视会触发灵魂互换。")
