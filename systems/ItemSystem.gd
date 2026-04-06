extends Node

const MAX_INVENTORY: int = 20
const ItemClass = preload("res://items/Item.gd")

signal key_item_acquired(item_id: String)
signal inventory_changed()

var _inventory: Array = []

# ============================================================
# 核心函数
# ============================================================

func pickup(item: ItemClass) -> bool:
	if _inventory.size() >= MAX_INVENTORY:
		return false
	_inventory.append(item)
	inventory_changed.emit()
	if item.is_key_item:
		key_item_acquired.emit(item.item_id)
	return true

func remove_item(p_item_id: String) -> void:
	for i: int in _inventory.size():
		var it: ItemClass = _inventory[i]
		if it.item_id == p_item_id:
			if it.is_key_item:
				print("[ItemSystem] 关键道具 %s 不可丢弃" % p_item_id)
				return
			_inventory.remove_at(i)
			inventory_changed.emit()
			return

func use_item(p_item_id: String, target: Node) -> void:
	for it: ItemClass in _inventory:
		if it.item_id == p_item_id:
			it.use(target)
			return
	print("[ItemSystem] 背包中不存在道具: %s" % p_item_id)

func get_inventory() -> Array:
	return _inventory.duplicate()

func has_item(p_item_id: String) -> bool:
	for it: ItemClass in _inventory:
		if it.item_id == p_item_id:
			return true
	return false

# ============================================================
# 验收测试
# ============================================================

func _ready() -> void:
	print("===== ItemSystem 测试开始 =====")
	_test_pickup_and_has()
	_test_full_inventory()
	_test_remove_key_item()
	_test_remove_normal_item()
	_test_use_item()
	_test_inventory_signal()
	print("===== 全部测试完成 =====")

func _test_pickup_and_has() -> void:
	var item1 := ItemClass.new()
	item1.item_id = "rope"
	item1.display_name = "麻绳"
	item1.item_type = ItemClass.ItemType.SURVIVAL
	item1.is_key_item = true

	var item2 := ItemClass.new()
	item2.item_id = "bandage"
	item2.display_name = "绷带"
	item2.item_type = ItemClass.ItemType.COMBAT

	var ok1: bool = pickup(item1)
	var ok2: bool = pickup(item2)
	print("[TEST] pickup(麻绳)=%s, pickup(绷带)=%s (应为 true, true)" % [ok1, ok2])
	print("[TEST] has_item(rope)=%s, has_item(bandage)=%s (应为 true, true)" % [has_item("rope"), has_item("bandage")])

func _test_full_inventory() -> void:
	for i: int in 20:
		var dummy := ItemClass.new()
		dummy.item_id = "dummy_%d" % i
		dummy.display_name = "测试道具%d" % i
		dummy.item_type = ItemClass.ItemType.LORE
		pickup(dummy)
	var overflow := ItemClass.new()
	overflow.item_id = "overflow"
	overflow.display_name = "溢出道具"
	var ok: bool = pickup(overflow)
	print("[TEST] 背包已满再 pickup=%s (应为 false)" % ok)

func _test_remove_key_item() -> void:
	remove_item("rope")
	print("[TEST] 尝试丢弃关键道具 rope，has_item(rope)=%s (应为 true)" % has_item("rope"))

func _test_remove_normal_item() -> void:
	remove_item("bandage")
	print("[TEST] 丢弃绷带后 has_item(bandage)=%s (应为 false)" % has_item("bandage"))

func _test_use_item() -> void:
	var test_target := Node.new()
	test_target.name = "TestTarget"
	var item := ItemClass.new()
	item.item_id = "test"
	item.display_name = "测试道具"
	item.use(test_target)
	test_target.queue_free()

func _test_inventory_signal() -> void:
	print("[TEST] 当前背包道具数: %d" % get_inventory().size())
