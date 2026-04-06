class_name ItemDoorLock
extends Item

signal room_secured

func _init() -> void:
	item_id = "door_lock"
	display_name = "坚固门锁"
	item_type = ItemType.SURVIVAL
	description = "可给任意空房间的门上锁。锁死后怪物无法撞开，成为永久安全区。每层仅3个。"
	is_key_item = false

func use(target: Node) -> void:
	if not target.has_method("lock_permanently"):
		print("[ItemDoorLock] 只能用在门上")
		return
	target.lock_permanently()
	room_secured.emit()
	print("[ItemDoorLock] %s 的门已上锁，该房间成为永久安全区" % target.name)
	ItemSystem.remove_item(item_id)
