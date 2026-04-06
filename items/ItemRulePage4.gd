class_name ItemRulePage4
extends Item

func _init() -> void:
	item_id = "rule_page_4"
	display_name = "规则残页（四）"
	item_type = ItemType.RULE_PAGE
	description = "灵魂互换后，瞳孔颜色跟随灵魂走，身体的肌肉记忆不改变。"
	is_key_item = true

func use(_target: Node) -> void:
	RuleSystem.unlock_rule("rule_pupil_follows_soul")
	print("[RulePage4] 规则解锁：灵魂互换后，瞳孔颜色跟随灵魂走，身体的肌肉记忆不改变。")
