extends Interactable
class_name HidingSpot

signal hiding_started
signal hiding_ended

@export var stamina_drain_rate: float = 8.0
@export var max_hide_duration: float = 15.0

var _is_hiding: bool = false
var _hide_timer: float = 0.0
var _player: Node = null

func _ready() -> void:
	super._ready()
	interaction_hint = "躲入"
	add_to_group("hiding_spot")

func _process(delta: float) -> void:
	if not _is_hiding:
		return

	_hide_timer += delta
	_drain_player_stamina(delta)

	if _hide_timer >= max_hide_duration:
		_force_exit_hiding()
		print("[HidingSpot] 躲藏超时，被强制踢出")

func interact(interactor: Node) -> void:
	if _is_hiding:
		exit_hiding()
	else:
		enter_hiding(interactor)

func _on_interact(_interactor: Node) -> void:
	pass

func enter_hiding(interactor: Node) -> void:
	if _is_hiding:
		return
	_is_hiding = true
	_player = interactor
	_hide_timer = 0.0
	interaction_hint = "离开"
	hiding_started.emit()
	print("[HidingSpot] 玩家开始躲藏，体力快速流失...")

func exit_hiding() -> void:
	if not _is_hiding:
		return
	_is_hiding = false
	interaction_hint = "躲入"
	_player = null
	_hide_timer = 0.0
	hiding_ended.emit()
	print("[HidingSpot] 玩家离开躲藏点")

func _force_exit_hiding() -> void:
	exit_hiding()

func _drain_player_stamina(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.has_method("_consume_stamina"):
		_player._consume_stamina(delta * stamina_drain_rate)

func is_hiding() -> bool:
	return _is_hiding
