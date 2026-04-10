class_name ItemElevatorCard
extends Item

func _init() -> void:
	item_id = "elevator_card_f1"
	display_name = "电梯卡"
	item_type = ItemType.LORE
	description = "公寓一层的电梯卡。可以启动那部只会向上的老旧电梯。"
	is_key_item = true

func use(_target: Node) -> void:
	print("[ItemElevatorCard] 电梯卡不能直接使用，请在电梯前交互")
