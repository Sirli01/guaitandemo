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

