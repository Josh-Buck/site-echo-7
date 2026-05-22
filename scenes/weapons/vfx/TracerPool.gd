class_name TracerPool extends Node

# Pre-allocated bullet tracers. Each shot used to allocate a BulletTracer scene +
# a fresh StandardMaterial3D, which stuttered the web build on every trigger pull
# (especially shotgun's 12 pellets per shot). Now: 32 tracers built once at run
# start, reused round-robin.

const POOL_SIZE: int = 32
const LIFETIME: float = 0.08

class Slot:
	var mesh: MeshInstance3D
	var box: BoxMesh
	var spawn_time: float = -1.0

var _pool: Array[Slot] = []
var _next: int = 0
var _shared_mat: StandardMaterial3D

func _ready() -> void:
	add_to_group("tracer_pool")
	_shared_mat = StandardMaterial3D.new()
	_shared_mat.albedo_color = Color(1.0, 0.85, 0.5, 1.0)
	_shared_mat.emission_enabled = true
	_shared_mat.emission = Color(1.0, 0.7, 0.3)
	_shared_mat.emission_energy_multiplier = 4.0
	_shared_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_shared_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shared_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	for i in POOL_SIZE:
		var s := Slot.new()
		s.mesh = MeshInstance3D.new()
		s.box = BoxMesh.new()
		s.box.size = Vector3(0.025, 0.025, 1.0)
		s.mesh.mesh = s.box
		s.mesh.material_override = _shared_mat
		s.mesh.visible = false
		s.mesh.top_level = true  # so global_position is meaningful regardless of parent
		add_child(s.mesh)
		_pool.append(s)

func _process(_delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	for s in _pool:
		if s.spawn_time < 0.0:
			continue
		if now - s.spawn_time >= LIFETIME:
			s.mesh.visible = false
			s.spawn_time = -1.0

func fire(from: Vector3, to: Vector3) -> void:
	var diff := to - from
	var dist := diff.length()
	if dist < 0.05:
		return
	var s := _acquire()
	if s == null:
		return
	# Each slot has its own BoxMesh so we can per-tracer scale Z without
	# mutating a shared resource (would have stretched every other live tracer).
	s.box.size = Vector3(0.025, 0.025, dist)
	var mid := (from + to) * 0.5
	s.mesh.global_position = mid
	s.mesh.look_at(to, Vector3.UP)
	s.mesh.visible = true
	s.spawn_time = Time.get_ticks_msec() / 1000.0

func _acquire() -> Slot:
	for i in POOL_SIZE:
		var idx := (_next + i) % POOL_SIZE
		var s := _pool[idx]
		if s.spawn_time < 0.0:
			_next = (idx + 1) % POOL_SIZE
			return s
	# All in use — recycle oldest.
	var oldest_idx := 0
	var oldest_t := INF
	for i in POOL_SIZE:
		if _pool[i].spawn_time < oldest_t:
			oldest_t = _pool[i].spawn_time
			oldest_idx = i
	_next = (oldest_idx + 1) % POOL_SIZE
	return _pool[oldest_idx]
