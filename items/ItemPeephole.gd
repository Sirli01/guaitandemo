class_name ItemPeephole
extends Item

signal peephole_activated(target: Node)
signal peephole_deactivated

var _is_observing: bool = false

func _init() -> void:
	item_id = "peephole_mirror"
	display_name = "单面防窥镜"
	item_type = ItemType.COMBAT
	description = "手持时可安全观察对面的人/怪物，对方无法看到你，绝对不触发对视。可观察NPC瞳孔颜色。全局仅1个。"
	is_key_item = true

func use(target: Node) -> void:
	if _is_observing:
		_is_observing = false
		peephole_deactivated.emit()
		print("[ItemPeephole] 退出瞳孔观察模式")
	else:
		_is_observing = true
		peephole_activated.emit(target)
		print("[ItemPeephole] 进入瞳孔观察模式，可安全观察 %s" % target.name)
