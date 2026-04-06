class_name ItemRecorder
extends Item

signal recorder_placed(position: Vector2)
signal play_audio(audio_name: String)

func _init() -> void:
	item_id = "recorder"
	display_name = "录音笔"
	item_type = ItemType.COMBAT
	description = "内置妹妹的日常录音。主动播放可吸引大范围怪物注意力，把怪物引到指定位置。"
	is_key_item = true

func use(target: Node) -> void:
	var pos: Vector2 = target.global_position
	recorder_placed.emit(pos)
	play_audio.emit("recorder_audio")
	print("[ItemRecorder] 录音笔已放置，怪物将被吸引过去")
