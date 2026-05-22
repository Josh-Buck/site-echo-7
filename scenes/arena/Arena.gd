extends Node3D

const LAB_HUM := preload("res://audio/ambient/lab_hum_loop.ogg")
const CONCRETE_MAT_PATH := "res://art/materials/concrete/material.tres"
const LAB_TILE_MAT_PATH := "res://art/materials/lab_tile/material.tres"

@onready var nav_region: NavigationRegion3D = $NavRegion
@onready var fluor_east: OmniLight3D = get_node_or_null("FluorescentEast")
@onready var fluor_west: OmniLight3D = get_node_or_null("FluorescentWest")

var _flicker_east_t: float = 0.0
var _flicker_west_t: float = 0.0
var _east_base_energy: float = 1.5
var _west_base_energy: float = 1.5
var _hum: AudioStreamPlayer = null

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
	_apply_pbr_materials()
	_build_perimeter_walls()
	_build_dust_motes()
	_build_random_debris()
	_start_ambient_hum()
	# Boss-wave lighting variant — fluorescents dim to red while a boss is alive.
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_ended.connect(_on_wave_ended)

const BOSS_ROUNDS := [10, 20]

func _on_wave_started(round_number: int, _composition: Array) -> void:
	if round_number in BOSS_ROUNDS:
		_set_boss_lighting(true)

func _on_wave_ended(round_number: int) -> void:
	if round_number in BOSS_ROUNDS:
		_set_boss_lighting(false)

func _set_boss_lighting(on: bool) -> void:
	# Boss waves dim the lights and shift them toward red — sells the threat.
	var target_color: Color = Color(1.0, 0.25, 0.25, 1) if on else Color(0.7, 0.78, 0.92, 1)
	var target_energy: float = 0.45 if on else 0.8
	for light in [fluor_east, fluor_west]:
		if light == null:
			continue
		var tw := create_tween()
		tw.tween_property(light, "light_color", target_color, 1.2)
		tw.parallel().tween_property(light, "light_energy", target_energy, 1.2)
	if on:
		_east_base_energy = target_energy
		_west_base_energy = target_energy
	else:
		_east_base_energy = 0.8
		_west_base_energy = 0.8

func _process(delta: float) -> void:
	if _hum and not _hum.playing and AudioMan.can_play():
		_hum.play()
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

func _apply_pbr_materials() -> void:
	if ResourceLoader.exists(CONCRETE_MAT_PATH):
		var concrete: StandardMaterial3D = load(CONCRETE_MAT_PATH)
		# Tile across the 36m floor diameter so the texture doesn't stretch.
		var tiled := concrete.duplicate() as StandardMaterial3D
		tiled.uv1_scale = Vector3(8.0, 8.0, 1.0)
		var floor_mesh := get_node_or_null("FloorBody/Mesh") as MeshInstance3D
		if floor_mesh:
			floor_mesh.set_surface_override_material(0, tiled)

func _start_ambient_hum() -> void:
	_hum = AudioStreamPlayer.new()
	_hum.stream = LAB_HUM
	_hum.bus = &"SFX" if AudioServer.get_bus_index("SFX") >= 0 else &"Master"
	_hum.volume_db = -40.0
	_hum.process_mode = Node.PROCESS_MODE_ALWAYS
	if LAB_HUM is AudioStreamOggVorbis:
		var hum: AudioStreamOggVorbis = LAB_HUM
		hum.loop = true
	add_child(_hum)
	if AudioMan.can_play():
		_hum.play()
	# else: _process polls AudioMan.can_play() and starts the hum once the user gestures.

func _build_perimeter_walls() -> void:
	var mat: Material
	if ResourceLoader.exists(LAB_TILE_MAT_PATH):
		var base: StandardMaterial3D = load(LAB_TILE_MAT_PATH)
		var tiled := base.duplicate() as StandardMaterial3D
		tiled.uv1_scale = Vector3(2.0, 2.0, 1.0)
		mat = tiled
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.22, 0.22, 0.24)
		fallback.metallic = 0.0
		fallback.roughness = 0.95
		mat = fallback
	var mesh := BoxMesh.new()
	mesh.size = Vector3(4.2, 4.5, 0.4)
	var ring_radius := 22.0
	var segments := 22
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
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.add_child(seg)
		seg.look_at(Vector3(0, 2.0, 0), Vector3.UP)

func _build_random_debris() -> void:
	# 6 small destroyed-equipment crates scattered between the barrier and the
	# perimeter wall. Different placement each run for visual variety. They
	# sit between the safe zone and the spawn ring so they read as
	# "abandoned in the rush."
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var group := Node3D.new()
	group.name = "Debris"
	add_child(group)
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(1.2, 0.85, 1.2)
	var mat := StandardMaterial3D.new()
	if ResourceLoader.exists(LAB_TILE_MAT_PATH):
		var base: StandardMaterial3D = load(LAB_TILE_MAT_PATH)
		mat = base.duplicate() as StandardMaterial3D
		mat.albedo_color = Color(0.32, 0.28, 0.24, 1)
	else:
		mat.albedo_color = Color(0.32, 0.28, 0.24, 1)
		mat.roughness = 0.85
	# Skip a 90-degree wedge so debris doesn't block the player's barrier sightline.
	var safe_angle := PI * 0.55  # ~99 degrees forward-facing kept clear
	for i in 6:
		var ang := rng.randf_range(safe_angle, TAU - safe_angle * 0.2)
		var radius := rng.randf_range(7.0, 13.0)
		var crate := MeshInstance3D.new()
		crate.mesh = box_mesh
		crate.set_surface_override_material(0, mat)
		crate.position = Vector3(cos(ang) * radius, 0.42, sin(ang) * radius)
		crate.rotation.y = rng.randf_range(0.0, TAU)
		crate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		group.add_child(crate)

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
