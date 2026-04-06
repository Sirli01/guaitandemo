extends Interactable

const Item = preload("res://items/Item.gd")

@export var item_id: String = ""
@export var item_scene: String = ""  # 例如 "res://items/ItemWater.gd"

func _ready() -> void:
	super._ready()
	interaction_hint = "拾取"
	# ★ 给一个默认视觉大小（场景里可调）
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	print("[PhysicalItem] item_id=%s 就绪" % item_id)

func _on_interact(interactor: Node) -> void:
	if item_id == "":
		print("[PhysicalItem] 错误：item_id 为空，无法拾取")
		return

	# ★ 根据 item_id 找到对应的 Item 脚本类并实例化
	var item_instance: Item = _spawn_item_by_id(item_id)
	if item_instance == null:
		push_error("[PhysicalItem] 找不到道具: %s" % item_id)
		return

	# ★ 通过 ItemSystem 拾取
	var ok: bool = ItemSystem.pickup(item_instance)
	if ok:
		print("[PhysicalItem] 拾取成功: %s" % item_instance.display_name)
		interacted.emit(interactor)
		queue_free()
	else:
		print("[PhysicalItem] 背包已满，无法拾取: %s" % item_id)

func _spawn_item_by_id(id: String) -> Item:
	var class_path: String = "res://items/"
	match id:
		"water_bottle":   class_path += "ItemWater.gd"
		"food_ration":    class_path += "ItemFood.gd"
		"energy_drink":   class_path += "ItemEnergyDrink.gd"
		"flashlight":     class_path += "ItemFlashlight.gd"
		"battery":        class_path += "ItemBattery.gd"
		"door_lock":      class_path += "ItemDoorLock.gd"
		"rope":           class_path += "ItemRope.gd"
		"peephole_mirror":class_path += "ItemPeephole.gd"
		"recorder":       class_path += "ItemRecorder.gd"
		"fire_axe":       class_path += "ItemFireAxe.gd"
		"earplug":        class_path += "ItemEarplug.gd"
		"rule_page_1":    class_path += "ItemRulePage1.gd"
		"rule_page_2":    class_path += "ItemRulePage2.gd"
		"rule_page_3":    class_path += "ItemRulePage3.gd"
		"rule_page_4":    class_path += "ItemRulePage4.gd"
		"rule_page_5":    class_path += "ItemRulePage5.gd"
		"rule_page_6":    class_path += "ItemRulePage6.gd"
		"diary_page":     class_path += "ItemDiaryPage.gd"
		"ayou_id_card":   class_path += "ItemAyouID.gd"
		"childhood_photo":class_path += "ItemChildhoodPhoto.gd"
		"resident_note":   class_path += "ItemResidentNote.gd"
		"sister_phone":   class_path += "ItemSisterPhone.gd"
		_:                return null

	var item_class = load(class_path)
	if item_class == null:
		push_error("[PhysicalItem] 无法加载道具脚本: %s" % class_path)
		return null

	var instance: Item = item_class.new()
	return instance
