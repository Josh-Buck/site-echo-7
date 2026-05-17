extends Node3D

@export var mouse_sensitivity: float = 0.002
@export var pitch_min_deg: float = -85.0
@export var pitch_max_deg: float = 85.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var _yaw: float = 0.0
var _pitch: float = 0.0
var _recoil_pitch: float = 0.0
var _recoil_yaw: float = 0.0
var _recoil_recovery: float = 0.3

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	AudioMan.register_first_gesture()
	EventBus.weapon_fired.connect(_on_weapon_fired)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	elif event.is_action_pressed("pause"):
		# Toggle pointer lock — useful for debugging in browser
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("dev_reset"):
		SaveSystem.wipe_meta()

func _process(delta: float) -> void:
	# Exponential recoil decay with time constant = recoil_recovery seconds.
	var decay := exp(-delta / max(0.05, _recoil_recovery))
	_recoil_pitch *= decay
	_recoil_yaw *= decay
	rotation.y = _yaw + _recoil_yaw
	camera_pivot.rotation.x = _pitch + _recoil_pitch

func _on_weapon_fired(weapon: Node, _payload: Dictionary) -> void:
	if not (weapon is Weapon):
		return
	var w: Weapon = weapon
	if w.data == null:
		return
	_recoil_pitch += deg_to_rad(w.data.recoil_vertical)
	_recoil_yaw += deg_to_rad(w.data.recoil_horizontal) * randf_range(-1.0, 1.0)
	_recoil_recovery = w.data.recoil_recovery
