extends Node

# Audio manager. Buses, 3D positional playback, first-gesture gate for web.

var _gesture_received: bool = false

func _ready() -> void:
	print("[AudioMan] ready")

func register_first_gesture() -> void:
	# Browsers block AudioContext until a user interaction. The title screen
	# must call this once after the first click/keypress before audio plays.
	if _gesture_received:
		return
	_gesture_received = true
	print("[AudioMan] first user gesture registered, audio enabled")

func can_play() -> bool:
	return _gesture_received
