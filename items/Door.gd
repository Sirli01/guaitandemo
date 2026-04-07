extends Interactable

class_name Door

enum DoorState { OPEN, CLOSED, LOCKED, BROKEN }

@export var door_id: String = ""
@export var is_auto_close: bool = true
@export var auto_close_delay: float = 3.0

var _state: DoorState = DoorState.CLOSED
var _blocker: StaticBody2D
var _blocker_shape: CollisionShape2D
var _sprite: ColorRect
var _auto_close_timer: float = 0.0

func _ready() -> void:
	super._ready()
	interaction_hint = "开门"
	_setup_blocker()
	_update_visual()
	print("[Door] %s 就绪，初始状态=%s" % [door_id, _state])

func _setup_blocker() -> void:
	_blocker = StaticBody2D.new()
	_blocker.name = "DoorBlocker"
	_blocker.collision_layer = 1
	_blocker.collision_mask = 0
	add_child(_blocker)

	_blocker_shape = CollisionShape2D.new()
	_blocker_shape.name = "BlockerShape"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 60)
	_blocker_shape.shape = shape
	_blocker.add_child(_blocker_shape)

	_blocker.collision_layer = 1

func _process(delta: float) -> void:
	if is_auto_close and _state == DoorState.OPEN:
		_auto_close_timer += delta
		if _auto_close_timer >= auto_close_delay:
			close()

func interact(_interactor: Node) -> void:
	match _state:
		DoorState.OPEN:
			close()
		DoorState.CLOSED:
			open()
		DoorState.LOCKED:
			print("[Door] %s 已被永久锁死，无法打开" % door_id)
		DoorState.BROKEN:
			print("[Door] %s 已被砸破，无法开关" % door_id)

func _on_interact(_interactor: Node) -> void:
	pass

func open() -> void:
	if _state != DoorState.CLOSED:
		return
	_state = DoorState.OPEN
	interaction_hint = "关门"
	_blocker.collision_layer = 0
	_update_visual()
	_auto_close_timer = 0.0
	interacted.emit(self)
	print("[Door] %s 已打开" % door_id)

func close() -> void:
	if _state != DoorState.OPEN:
		return
	_state = DoorState.CLOSED
	interaction_hint = "开门"
	_blocker.collision_layer = 1
	_update_visual()
	interacted.emit(self)
	print("[Door] %s 已关闭" % door_id)

func lock_permanent() -> void:
	_state = DoorState.LOCKED
	interaction_hint = "已锁死"
	_blocker.collision_layer = 1
	_update_visual()
	print("[Door] %s 已被永久锁死" % door_id)

func break_door() -> void:
	if _state == DoorState.BROKEN:
		return
	_state = DoorState.BROKEN
	interaction_hint = "已破损"
	_blocker.collision_layer = 0
	_update_visual()
	interacted.emit(self)
	print("[Door] %s 已被砸破！" % door_id)

func is_blocking() -> bool:
	return _state == DoorState.CLOSED or _state == DoorState.LOCKED

func get_state() -> DoorState:
	return _state

func _update_visual() -> void:
	if has_node("DoorVisual"):
		var old_vis = get_node("DoorVisual")
		old_vis.queue_free()

	_sprite = ColorRect.new()
	_sprite.name = "DoorVisual"
	_sprite.custom_minimum_size = Vector2(10, 60)
	add_child(_sprite)

	match _state:
		DoorState.OPEN:
			_sprite.modulate = Color(0.3, 0.8, 0.3, 0.5)
		DoorState.CLOSED:
			_sprite.modulate = Color(0.6, 0.4, 0.2, 1.0)
		DoorState.LOCKED:
			_sprite.modulate = Color(0.3, 0.3, 0.3, 1.0)
		DoorState.BROKEN:
			_sprite.modulate = Color(0.5, 0.2, 0.1, 0.7)

func handle_item_use(item_id: String) -> bool:
	match item_id:
		"door_lock":
			lock_permanent()
			return true
		"fire_axe":
			if _state == DoorState.LOCKED:
				break_door()
				return true
			else:
				print("[Door] 斧头只能砸已锁的门")
				return false
	return false
