extends Node3D

@onready var nav_region: NavigationRegion3D = $NavRegion
@onready var fluor_east: OmniLight3D = get_node_or_null("FluorescentEast")
@onready var fluor_west: OmniLight3D = get_node_or_null("FluorescentWest")

var _flicker_east_t: float = 0.0
var _flicker_west_t: float = 0.0
var _east_base_energy: float = 1.5
var _west_base_energy: float = 1.5

func _ready() -> void:
	var nm: NavigationMesh = nav_region.navigation_mesh
	if nm != null and nm.get_polygon_count() == 0:
		nav_region.bake_navigation_mesh(false)
		print("[Arena] navmesh baked at runtime")
	var sp_count := get_tree().get_nodes_in_group("spawn_points").size()
	print("[Arena] ready, spawn_points=%d" % sp_count)
	if fluor_east:
		_east_base_energy = fluor_east.light_energy
	if fluor_west:
		_west_base_energy = fluor_west.light_energy
	_flicker_east_t = randf_range(2.0, 6.0)
	_flicker_west_t = randf_range(4.0, 9.0)
	_build_perimeter_walls()
	_build_dust_motes()

func _process(delta: float) -> void:
	if fluor_east:
		_flicker_east_t -= delta
		if _flicker_east_t <= 0.0:
			_pulse_flicker(fluor_east, _east_base_energy)
			_flicker_east_t = randf_range(4.0, 12.0)
	if fluor_west:
		_flicker_west_t -= delta
		if _flicker_west_t <= 0.0:
			_pulse_flicker(fluor_west, _west_base_energy)
			_flicker_west_t = randf_range(4.0, 12.0)

func _pulse_flicker(light: OmniLight3D, base: float) -> void:
	# Brief stutter — sells the "struggling fluorescent" vibe.
	var tw := create_tween()
	tw.tween_property(light, "light_energy", base * 0.15, 0.05)
	tw.tween_property(light, "light_energy", base * 0.9, 0.04)
	tw.tween_property(light, "light_energy", base * 0.25, 0.06)
	tw.tween_property(light, "light_energy", base, 0.18)

func _build_perimeter_walls() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.22, 0.24)
	mat.metallic = 0.0
	mat.roughness = 0.95
	var mesh := BoxMesh.new()
	mesh.size = Vector3(4.2, 4.5, 0.4)
	var ring_radius := 16.0
	var segments := 18
	var ring := Node3D.new()
	ring.name = "PerimeterWalls"
	add_child(ring)
	for i in segments:
		# Skip a few segments to suggest dark corridors leading away.
		if i == 2 or i == 9 or i == 14:
			continue
		var ang := TAU * float(i) / float(segments)
		var seg := MeshInstance3D.new()
		seg.mesh = mesh
		seg.set_surface_override_material(0, mat)
		seg.position = Vector3(cos(ang) * ring_radius, 2.0, sin(ang) * ring_radius)
		seg.look_at(Vector3(0, 2.0, 0), Vector3.UP)
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.add_child(seg)

func _build_dust_motes() -> void:
	var p := GPUParticles3D.new()
	p.name = "DustMotes"
	add_child(p)
	p.amount = 80
	p.lifetime = 8.0
	p.preprocess = 4.0
	p.fixed_fps = 20
	p.position = Vector3(0, 3, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(15, 4, 15)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 30.0
	pm.gravity = Vector3(0.0, 0.05, 0.0)
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.2
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.18), Color(1, 1, 1, 0.0)])
	var gtex := GradientTexture1D.new()
	gtex.gradient = grad
	pm.color_ramp = gtex
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.06, 0.06)
	var dust_mat := StandardMaterial3D.new()
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.albedo_color = Color(1, 1, 1, 0.18)
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.material = dust_mat
	p.draw_pass_1 = qm
	p.emitting = true
