class_name ItemRulePage3
extends Item

func _init() -> void:
	item_id = "rule_page_3"
	display_name = "规则残页（三）"
	item_type = ItemType.RULE_PAGE
	description = "互换期间一方死亡，灵魂将永久锁定于对方身体，无法换回。"
	is_key_item = true

func use(_target: Node) -> void:
	RuleSystem.unlock_rule("rule_permanent_lock")
	print("[RulePage3] 规则解锁：互换期间一方死亡，灵魂将永久锁定于对方身体，无法换回。")
