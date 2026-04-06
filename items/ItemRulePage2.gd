class_name ItemRulePage2
extends Item

func _init() -> void:
	item_id = "rule_page_2"
	display_name = "规则残页（二）"
	item_type = ItemType.RULE_PAGE
	description = "单一个体在禁对视时段内仅可互换1次灵魂。"
	is_key_item = true

func use(_target: Node) -> void:
	RuleSystem.unlock_rule("rule_once_per_period")
	print("[RulePage2] 规则解锁：单一个体在禁对视时段内仅可互换1次灵魂。")
