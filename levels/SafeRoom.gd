extends Area2D

@export var zone_name: String = "SafeRoom"
@export var is_locked: bool = true  # 门锁上时才是安全区

var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# 设置门的碰撞
	if has_node("Door/DoorCollision"):
		var dc = get_node("Door/DoorCollision")
		var shape = RectangleShape2D.new()
		shape.size = Vector2(10, 80)
		dc.shape = shape

	# 门的视觉
	if has_node("Door/DoorSprite"):
		var ds = get_node("Door/DoorSprite")
		var pts = PackedVector2Array([
			Vector2(-5, -40), Vector2(5, -40),
			Vector2(5, 40), Vector2(-5, 40)
		])
		ds.polygon = pts
		ds.color = Color(0.4, 0.25, 0.1, 1.0)

	print("[SafeRoom] %s 就绪，锁定状态: %s" % [zone_name, is_locked])

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and is_locked:
		_player_inside = true
		SafeZoneSystem.enter_safe_zone(zone_name)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and _player_inside:
		_player_inside = false
		SafeZoneSystem.exit_safe_zone(zone_name)

func lock_door() -> void:
	is_locked = true
	print("[SafeRoom] %s 门已上锁" % zone_name)

func unlock_door() -> void:
	is_locked = false
	if _player_inside:
		_player_inside = false
		SafeZoneSystem.exit_safe_zone(zone_name)
	print("[SafeRoom] %s 门已解锁" % zone_name)
