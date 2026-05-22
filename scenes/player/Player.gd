extends Node3D

@export var mouse_sensitivity: float = 0.002
@export var pitch_min_deg: float = -85.0
@export var pitch_max_deg: float = 85.0

func _get_sensitivity() -> float:
	return float(MetaProgress.get_setting("mouse_sensitivity", mouse_sensitivity))

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var weapon_holder: Node3D = $CameraPivot/Camera3D/WeaponHolder if has_node("CameraPivot/Camera3D/WeaponHolder") else null
var _weapon_holder_rest: Vector3 = Vector3.ZERO

var _yaw: float = 0.0
var _pitch: float = 0.0
var _recoil_pitch: float = 0.0
var _recoil_yaw: float = 0.0
var _recoil_recovery: float = 0.3
var _shake_amount: float = 0.0
var _shake_seed: float = 0.0
var _sway_phase: float = 0.0
var _fov_punch_amount: float = 0.0  # transient FOV bump on fire, decays each frame
var _mouse_target_yaw: float = 0.0
var _mouse_target_pitch: float = 0.0
var _viewmodel_bob_phase: float = 0.0
const VIEWMODEL_BOB_AMP_Y: float = 0.004
const VIEWMODEL_BOB_AMP_X: float = 0.003
const VIEWMODEL_BOB_FREQ: float = 1.3
# Inspect-mode pose offset, lerped between resting and "tilted up at camera".
var _inspect_t: float = 0.0
const INSPECT_LERP_SPEED: float = 6.0

const SHAKE_DECAY: float = 14.0
const SHAKE_MAX: float = 0.8
# Idle weapon/camera sway — sells "alive" instead of "snap-still."
const SWAY_AMP_PITCH: float = 0.0028  # ~0.16°
const SWAY_AMP_YAW: float = 0.0022
const SWAY_FREQ_PITCH: float = 1.15
const SWAY_FREQ_YAW: float = 0.78

func _ready() -> void:
	# Browsers block pointer lock without a user gesture — we wait for the first click.
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.barrier_damaged.connect(_on_barrier_damaged_shake)
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed_shake)
	camera.fov = MetaProgress.get_fov()
	EventBus.settings_changed.connect(_on_settings_changed)
	if weapon_holder:
		_weapon_holder_rest = weapon_holder.position

func _on_settings_changed(key: String, _value) -> void:
	if key == "fov":
		camera.fov = MetaProgress.get_fov()

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
		var dx: float = event.relative.x * sens
		var dy: float = event.relative.y * sens
		if bool(MetaProgress.get_setting("mouse_smoothing", false)):
			# Accumulate into a target; _process lerps the live yaw/pitch toward it.
			_mouse_target_yaw -= dx
			_mouse_target_pitch -= dy
			_mouse_target_pitch = clamp(_mouse_target_pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
		else:
			_yaw -= dx
			_pitch -= dy
			_pitch = clamp(_pitch, deg_to_rad(pitch_min_deg), deg_to_rad(pitch_max_deg))
			_mouse_target_yaw = _yaw
			_mouse_target_pitch = _pitch
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
	# Idle breathing sway. Suppressed while the player is firing (shake spike) or
	# while the cursor is loose (menu open) so menus don't have a drifting weapon.
	_sway_phase += delta
	var sway_pitch := 0.0
	var sway_yaw := 0.0
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and _shake_amount < 0.05:
		sway_pitch = sin(_sway_phase * SWAY_FREQ_PITCH) * SWAY_AMP_PITCH
		sway_yaw = sin(_sway_phase * SWAY_FREQ_YAW + 1.3) * SWAY_AMP_YAW
	# Apply smoothing toward target if enabled. Without smoothing the targets
	# stay synced to the live values so this is a no-op.
	if bool(MetaProgress.get_setting("mouse_smoothing", false)):
		var smoothing_speed: float = 18.0
		var s: float = clamp(delta * smoothing_speed, 0.0, 1.0)
		_yaw = lerp(_yaw, _mouse_target_yaw, s)
		_pitch = lerp(_pitch, _mouse_target_pitch, s)
	rotation.y = _yaw + _recoil_yaw + shake_x + sway_yaw
	camera_pivot.rotation.x = _pitch + _recoil_pitch + shake_y + sway_pitch
	# Viewmodel idle bob + inspect lerp. Hold I to inspect the weapon — pulls
	# it closer to camera and rotates ~20deg toward the lens.
	if weapon_holder != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var want_inspect: float = 1.0 if Input.is_action_pressed("inspect") else 0.0
		_inspect_t = lerp(_inspect_t, want_inspect, clamp(delta * INSPECT_LERP_SPEED, 0.0, 1.0))
		var bob_x: float = 0.0
		var bob_y: float = 0.0
		if _shake_amount < 0.05 and _inspect_t < 0.1:
			_viewmodel_bob_phase += delta * VIEWMODEL_BOB_FREQ
			bob_x = sin(_viewmodel_bob_phase) * VIEWMODEL_BOB_AMP_X
			bob_y = sin(_viewmodel_bob_phase * 2.0) * VIEWMODEL_BOB_AMP_Y
		# Inspect offset: pull gun left + up + forward a touch.
		var inspect_offset := Vector3(-0.18, 0.06, 0.12) * _inspect_t
		weapon_holder.position = _weapon_holder_rest + Vector3(bob_x, bob_y, 0) + inspect_offset
		weapon_holder.rotation = Vector3(-_inspect_t * 0.18, _inspect_t * 0.35, _inspect_t * 0.12)
	# FOV punch decays exponentially toward 0; apply to live camera fov as a transient offset.
	if _fov_punch_amount > 0.001:
		_fov_punch_amount = max(0.0, _fov_punch_amount - delta * 14.0)
		camera.fov = MetaProgress.get_fov() + _fov_punch_amount
	elif not is_equal_approx(camera.fov, MetaProgress.get_fov()):
		camera.fov = MetaProgress.get_fov()

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
	# Tiny FOV punch on fire — reads as kinetic feedback and clarifies "the shot happened
	# this frame." Recovers via the existing FOV setting since we only nudge transiently.
	# Lower coefficient + lower cap than the first pass — user wanted subtler.
	_fov_punch_amount = clamp(_fov_punch_amount + w.data.recoil_vertical * recoil_mult * 0.08, 0.0, 2.0)
	# Gamepad rumble — best-effort. Browsers expose this via Gamepad API; Godot
	# wraps it. weak/strong magnitudes scale with the weapon's recoil so a
	# bolt-action feels heavier than the pistol.
	var strong: float = clamp(w.data.recoil_vertical * recoil_mult * 0.12, 0.0, 0.6)
	var weak: float = clamp(w.data.recoil_vertical * recoil_mult * 0.06, 0.0, 0.4)
	if strong > 0.01:
		Input.start_joy_vibration(0, weak, strong, 0.08)

func _on_barrier_damaged_shake(amount: float, _attacker: Node) -> void:
	add_shake(0.2 + amount * 0.05)

func _on_barrier_destroyed_shake() -> void:
	add_shake(2.5)
