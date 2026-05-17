extends MeshInstance3D

const LIFETIME: float = 0.08
var _t: float = 0.0
var _mat: StandardMaterial3D

func setup(from: Vector3, to: Vector3) -> void:
	var mid := (from + to) * 0.5
	global_position = mid
	var diff := to - from
	var dist := diff.length()
	if dist < 0.01:
		queue_free()
		return
	look_at(to, Vector3.UP)
	# Stretch along local -Z (look_at convention) — scale the box on Z to span the segment.
	var box := mesh as BoxMesh
	if box != null:
		box.size = Vector3(0.025, 0.025, dist)

func _ready() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.5, 1.0)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.7, 0.3)
	m.emission_energy_multiplier = 4.0
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material_override = m
	_mat = m

func _process(delta: float) -> void:
	_t += delta
	var k := 1.0 - clamp(_t / LIFETIME, 0.0, 1.0)
	if _mat:
		_mat.emission_energy_multiplier = 4.0 * k
		_mat.albedo_color.a = k
	if _t >= LIFETIME:
		queue_free()
