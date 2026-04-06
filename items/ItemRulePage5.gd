class_name ItemRulePage5
extends Item

func _init() -> void:
	item_id = "rule_page_5"
	display_name = "规则残页（五）"
	item_type = ItemType.RULE_PAGE
	description = "与怪物对视同样触发灵魂互换，规则对怪物完全生效。"
	is_key_item = true

func use(_target: Node) -> void:
	RuleSystem.unlock_rule("rule_monster_swap")
	print("[RulePage5] 规则解锁：与怪物对视同样触发灵魂互换，规则对怪物完全生效。")
