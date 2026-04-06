class_name ItemRulePage6
extends Item

func _init() -> void:
	item_id = "rule_page_6"
	display_name = "规则残页（六）"
	item_type = ItemType.RULE_PAGE
	description = "07:00灵魂强制换回时，无论双方身处何处，效果都会生效。"
	is_key_item = true

func use(_target: Node) -> void:
	RuleSystem.unlock_rule("rule_force_return")
	print("[RulePage6] 规则解锁：07:00灵魂强制换回时，无论双方身处何处，效果都会生效。")
