extends Node3D

@export var mouse_sensitivity: float = 0.002
@export var pitch_min_deg: float = -85.0
@export var pitch_max_deg: float = 85.0

func _get_sensitivity() -> float:
	return float(MetaProgress.get_setting("mouse_sensitivity", mouse_sensitivity))

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

var _yaw: float = 0.0
var _pitch: float = 0.0
var _recoil_pitch: float = 0.0
var _recoil_yaw: float = 0.0
var _recoil_recovery: float = 0.3
var _shake_amount: float = 0.0
var _shake_seed: float = 0.0

const SHAKE_DECAY: float = 14.0
const SHAKE_MAX: float = 0.8

func _ready() -> void:
	# Browsers block pointer lock without a user gesture — we wait for the first click.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.barrier_damaged.connect(_on_barrier_damaged_shake)
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed_shake)

func _input(event: InputEvent) -> void:
	# First click anywhere captures the pointer and consumes the event so the
	# weapon doesn't fire on the activation click.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			AudioMan.register_first_gesture()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := _get_sensitivity()
		_yaw -= event.relative.x * sens
		_pitch -= event.relative.y * sens
		_pitch = clamp(_pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
	elif event.is_action_pressed("dev_reset"):
		SaveSystem.wipe_meta()

func _process(delta: float) -> void:
	var decay := exp(-delta / max(0.05, _recoil_recovery))
	_recoil_pitch *= decay
	_recoil_yaw *= decay
	_shake_amount = max(0.0, _shake_amount - SHAKE_DECAY * delta)
	var shake_x := 0.0
	var shake_y := 0.0
	if _shake_amount > 0.005:
		var t: float = float(Time.get_ticks_msec()) * 0.001
		shake_x = sin((t + _shake_seed) * 60.0) * _shake_amount * 0.03
		shake_y = cos((t + _shake_seed) * 73.0) * _shake_amount * 0.03
	rotation.y = _yaw + _recoil_yaw + shake_x
	camera_pivot.rotation.x = _pitch + _recoil_pitch + shake_y

func add_shake(magnitude: float) -> void:
	_shake_amount = min(SHAKE_MAX, _shake_amount + magnitude)
	_shake_seed = randf() * 1000.0

func _on_weapon_fired(weapon: Node, _payload: Dictionary) -> void:
	if not (weapon is Weapon):
		return
	var w: Weapon = weapon
	if w.data == null:
		return
	var recoil_mult := CardSystem.get_modifier(&"recoil")
	_recoil_pitch += deg_to_rad(w.data.recoil_vertical * recoil_mult)
	_recoil_yaw += deg_to_rad(w.data.recoil_horizontal * recoil_mult) * randf_range(-1.0, 1.0)
	_recoil_recovery = w.data.recoil_recovery
	add_shake(w.data.recoil_vertical * recoil_mult * 0.12)

func _on_barrier_damaged_shake(amount: float, _attacker: Node) -> void:
	add_shake(0.2 + amount * 0.05)

func _on_barrier_destroyed_shake() -> void:
	add_shake(2.5)
