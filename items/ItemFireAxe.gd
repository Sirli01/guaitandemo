class_name ItemFireAxe
extends Item

signal window_smashed(target: Node)

func _init() -> void:
	item_id = "fire_axe"
	display_name = "消防斧"
	item_type = ItemType.COMBAT
	description = "可瞬间砸开上锁的门，也可砸破走廊窗户。智斗流反杀怪物的必备辅助道具。"
	is_key_item = false

func use(target: Node) -> void:
	if target.has_method("break_open"):
		target.break_open()
		print("[ItemFireAxe] 消防斧砸开了门")
	elif target.has_method("smash"):
		target.smash()
		window_smashed.emit(target)
		print("[ItemFireAxe] 窗户已砸破")
	else:
		print("[ItemFireAxe] 消防斧只能用在门或窗上")
