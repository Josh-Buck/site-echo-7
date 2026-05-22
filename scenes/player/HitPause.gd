class_name HitPause extends Node

# Brief slow-mo on kills for impact. Boss-class kills pause longer than regular
# headshots, which pause longer than body kills. Tweens / UI run on CanvasLayers
# with their own process_mode so they keep pace.

@export var headshot_scale: float = 0.35
@export var headshot_dur: float = 0.045
@export var body_kill_scale: float = 0.6
@export var body_kill_dur: float = 0.02
@export var boss_kill_scale: float = 0.2
@export var boss_kill_dur: float = 0.18

var _restore_at: float = -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _process(_delta: float) -> void:
	if _restore_at < 0.0:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now >= _restore_at:
		Engine.time_scale = 1.0
		_restore_at = -1.0

func _on_enemy_killed(enemy: Node, _src: Node, headshot: bool, _pos: Vector3) -> void:
	if enemy != null and "data" in enemy and enemy.data != null:
		var eid: StringName = enemy.data.id
		if eid == &"subject" or eid == &"director":
			_trigger(boss_kill_scale, boss_kill_dur)
			return
	if headshot:
		_trigger(headshot_scale, headshot_dur)
	else:
		_trigger(body_kill_scale, body_kill_dur)

func _trigger(s: float, d: float) -> void:
	Engine.time_scale = s
	_restore_at = Time.get_ticks_msec() / 1000.0 + d
