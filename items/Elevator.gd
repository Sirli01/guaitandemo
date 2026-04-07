extends Interactable
class_name Elevator

signal elevator_used(floor: int)

@export var floor_number: int = 1
@export var required_item_id: String = "ayou_id_card"
@export var target_floor: int = 2

var _is_activated: bool = false
var _player: Node = null

func _ready() -> void:
	super._ready()
	interaction_hint = "使用电梯 (需钥匙卡)"
	add_to_group("elevator")

func interact(interactor: Node) -> void:
	_player = interactor
	if not _is_activated:
		_try_activate()
	else:
		_use_elevator()

func _on_interact(_interactor: Node) -> void:
	pass

func activate() -> void:
	_is_activated = true
	interaction_hint = "乘电梯前往 %d 楼" % target_floor
	print("[Elevator] 电梯已激活，楼层 %d" % floor_number)

func _try_activate() -> void:
	if ItemSystem.has_item(required_item_id):
		activate()
		_use_elevator()
	else:
		print("[Elevator] 电梯需要钥匙卡 (ItemSystem 持有: %s)" % ItemSystem.has_item(required_item_id))

func _use_elevator() -> void:
	if not _is_activated:
		_try_activate()
		return
	elevator_used.emit(floor_number)
	GameManager.on_floor_transition(floor_number, target_floor)
	print("[Elevator] 玩家使用电梯: %d -> %d 楼" % [floor_number, target_floor])

func is_activated() -> bool:
	return _is_activated
