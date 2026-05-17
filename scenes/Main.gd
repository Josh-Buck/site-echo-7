extends Node3D

# M0 smoke test:
#   - 3D scene rendering (proves Compatibility renderer works in browser)
#   - Input (SPACE / left-click to score)
#   - Animation (cube bounce + camera orbit)
#   - Persistence (score saves to user://meta.save, restored on reload)

@onready var cube: MeshInstance3D = $Cube
@onready var camera_pivot: Node3D = $CameraPivot
@onready var score_label: Label = $UI/ScoreLabel
@onready var hint_label: Label = $UI/HintLabel

var _bounce_t: float = 0.0
var _bouncing: bool = false

func _ready() -> void:
	_update_ui()
	# Slight delay between autoloads and gameplay so save load completes first.
	print("[Main] ready, lifetime_score=%d" % MetaProgress.lifetime_score)

func _process(delta: float) -> void:
	# Slow camera orbit so the scene reads as alive on first load.
	camera_pivot.rotate_y(delta * 0.3)

	if _bouncing:
		_bounce_t += delta * 6.0
		var y := sin(_bounce_t) * 0.6
		cube.position.y = max(0.0, y)
		if _bounce_t >= PI:
			_bouncing = false
			_bounce_t = 0.0
			cube.position.y = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		AudioMan.register_first_gesture()
		_score()
	elif event.is_action_pressed("reset_save"):
		SaveSystem.wipe_meta()
		_update_ui()

func _score() -> void:
	MetaProgress.add_score(1)
	_bouncing = true
	_bounce_t = 0.0
	_update_ui()

func _update_ui() -> void:
	score_label.text = "Lifetime score: %d" % MetaProgress.lifetime_score
	hint_label.text = "SPACE / click to score    R to reset save"
