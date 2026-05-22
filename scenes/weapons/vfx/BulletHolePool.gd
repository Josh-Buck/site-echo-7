extends Node

# Pooled bullet-hole decals. Each impact on the barrier/floor leaves a small dark
# spot that lingers for a few seconds. Capped pool size so we don't allocate per shot.

const POOL_SIZE: int = 48
const LIFETIME: float = 6.0

class Slot:
	var mesh: MeshInstance3D
	var spawn_time: float = -1.0
	var mat: StandardMaterial3D

var _pool: Array[Slot] = []
var _next: int = 0
var _quad_mesh: QuadMesh

func _ready() -> void:
	add_to_group("bullethole_pool")
	_quad_mesh = QuadMesh.new()
	_quad_mesh.size = Vector2(0.18, 0.18)
	for i in POOL_SIZE:
		var s := Slot.new()
		s.mat = _new_decal_mat()
		s.mesh = MeshInstance3D.new()
		s.mesh.mesh = _quad_mesh
		s.mesh.material_override = s.mat
		s.mesh.visible = false
		s.mesh.top_level = true
		s.mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(s.mesh)
		_pool.append(s)

func _new_decal_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.04, 0.04, 0.05, 0.88)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = false
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func _process(_delta: float) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	for s in _pool:
		if s.spawn_time < 0.0:
			continue
		var age: float = now - s.spawn_time
		if age >= LIFETIME:
			s.mesh.visible = false
			s.spawn_time = -1.0
		else:
			# Linear fade-out in the last 30% of lifetime.
			var fade_start: float = LIFETIME * 0.7
			if age >= fade_start:
				var t: float = (age - fade_start) / (LIFETIME - fade_start)
				s.mat.albedo_color.a = lerp(0.88, 0.0, t)

func stamp(at: Vector3, normal: Vector3) -> void:
	var s := _acquire()
	if s == null:
		return
	# Offset slightly toward the normal so we don't z-fight with the surface.
	s.mesh.global_position = at + normal.normalized() * 0.005
	# Orient quad facing the normal direction.
	var up := normal.normalized()
	var ref := Vector3.UP if absf(up.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var right := ref.cross(up).normalized()
	var fwd := up.cross(right).normalized()
	s.mesh.global_transform.basis = Basis(right, up, fwd)
	# Random rotation about the normal so they don't all align.
	s.mesh.rotate(up, randf_range(0.0, TAU))
	s.mat.albedo_color.a = 0.88
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
