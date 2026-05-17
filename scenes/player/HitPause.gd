class_name HitPause extends Node

# Brief slow-mo on headshot kills for impact. UI tweens are on CanvasLayers with
# their own process_mode and run unscaled, so they keep pace.

@export var slow_scale: float = 0.05
@export var duration_sec: float = 0.07

var _restore_at: float = -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _process(_delta: float) -> void:
	if _restore_at < 0.0:
		return
	# Use unscaled wall clock so a 0.05 time_scale doesn't stretch the pause.
	var now := Time.get_ticks_msec() / 1000.0
	if now >= _restore_at:
		Engine.time_scale = 1.0
		_restore_at = -1.0

func _on_enemy_killed(_enemy: Node, _src: Node, headshot: bool, _pos: Vector3) -> void:
	if not headshot:
		return
	_trigger()

func _trigger() -> void:
	Engine.time_scale = slow_scale
	_restore_at = Time.get_ticks_msec() / 1000.0 + duration_sec
