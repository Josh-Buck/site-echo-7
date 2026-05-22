extends Node3D

const LAB_HUM := preload("res://audio/ambient/lab_hum_loop.ogg")
const METAL_PANEL_MAT_PATH := "res://art/materials/metal_panel/material.tres"
const RUSTY_STEEL_MAT_PATH := "res://art/materials/rusty_steel/material.tres"
const CONCRETE_MAT_PATH := "res://art/materials/concrete/material.tres"

@onready var nav_region: NavigationRegion3D = $NavRegion
@onready var vent_light: OmniLight3D = get_node_or_null("VentLight")
@onready var fan: Node3D = get_node_or_null("VentFan")

var _fan_spin: float = 0.0
var _flicker_t: float = 0.0
var _vent_base_energy: float = 1.6
var _hum: AudioStreamPlayer = null

func _ready() -> void:
	var nm: NavigationMesh = nav_region.navigation_mesh
	if nm != null and nm.get_polygon_count() == 0:
		nav_region.bake_navigation_mesh(false)
		print("[CoolingTower] navmesh baked at runtime")
	var sp_count := get_tree().get_nodes_in_group("spawn_points").size()
	print("[CoolingTower] ready, spawn_points=%d" % sp_count)
	if vent_light:
		_vent_base_energy = vent_light.light_energy
	_flicker_t = randf_range(3.0, 7.0)
	_apply_pbr_materials()
	_build_perimeter_pipes()
	_build_girders()
	_build_dust_motes()
	_start_ambient_hum()
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_ended.connect(_on_wave_ended)

func _on_wave_started(round_number: int, _composition: Array) -> void:
	if round_number == 20 and vent_light:
		# Director boss wave: vent light shifts red, energy drops.
		var tw := create_tween()
		tw.tween_property(vent_light, "light_color", Color(1.0, 0.25, 0.25, 1), 1.2)
		tw.parallel().tween_property(vent_light, "light_energy", 0.5, 1.2)
		_vent_base_energy = 0.5

func _on_wave_ended(round_number: int) -> void:
	if round_number == 20 and vent_light:
		var tw := create_tween()
		tw.tween_property(vent_light, "light_color", Color(0.55, 0.7, 0.92, 1), 1.5)
		tw.parallel().tween_property(vent_light, "light_energy", 1.0, 1.5)
		_vent_base_energy = 1.0

func _process(delta: float) -> void:
	if _hum and not _hum.playing and AudioMan.can_play():
		_hum.play()
	if fan:
		_fan_spin += delta * 1.6
		fan.rotation.y = _fan_spin
	if vent_light:
		# Periodic vent-fan shadow sweep: the fan blades occult the lamp.
		var sweep := 0.55 + 0.45 * (0.5 + 0.5 * sin(_fan_spin * 4.0))
		vent_light.light_energy = _vent_base_energy * sweep
		_flicker_t -= delta
		if _flicker_t <= 0.0:
			_pulse_flicker(vent_light, _vent_base_energy)
			_flicker_t = randf_range(6.0, 14.0)

func _pulse_flicker(light: OmniLight3D, base: float) -> void:
	var tw := create_tween()
	tw.tween_property(light, "light_energy", base * 0.2, 0.04)
	tw.tween_property(light, "light_energy", base * 0.85, 0.05)
	tw.tween_property(light, "light_energy", base * 0.3, 0.05)
	tw.tween_property(light, "light_energy", base, 0.2)

func _apply_pbr_materials() -> void:
	# Floor: concrete, tiled.
	if ResourceLoader.exists(CONCRETE_MAT_PATH):
		var concrete: StandardMaterial3D = load(CONCRETE_MAT_PATH)
		var floor_mat := concrete.duplicate() as StandardMaterial3D
		floor_mat.uv1_scale = Vector3(8.0, 8.0, 1.0)
		var floor_mesh := get_node_or_null("FloorBody/Mesh") as MeshInstance3D
		if floor_mesh:
			floor_mesh.set_surface_override_material(0, floor_mat)
	# Shell: metal panel, large tiling because the cylinder is huge.
	if ResourceLoader.exists(METAL_PANEL_MAT_PATH):
		var panel: StandardMaterial3D = load(METAL_PANEL_MAT_PATH)
		var shell_mat := panel.duplicate() as StandardMaterial3D
		shell_mat.uv1_scale = Vector3(6.0, 3.0, 1.0)
		shell_mat.cull_mode = BaseMaterial3D.CULL_FRONT
		var shell := get_node_or_null("Shell") as MeshInstance3D
		if shell:
			shell.set_surface_override_material(0, shell_mat)

func _start_ambient_hum() -> void:
	_hum = AudioStreamPlayer.new()
	_hum.stream = LAB_HUM
	_hum.bus = &"SFX" if AudioServer.get_bus_index("SFX") >= 0 else &"Master"
	# Industrial feel: slightly louder + pitched down for a deeper drone.
	_hum.volume_db = -40.0
	_hum.pitch_scale = 0.89
	_hum.process_mode = Node.PROCESS_MODE_ALWAYS
	if LAB_HUM is AudioStreamOggVorbis:
		var hum: AudioStreamOggVorbis = LAB_HUM
		hum.loop = true
	add_child(_hum)
	if AudioMan.can_play():
		_hum.play()

func _build_perimeter_pipes() -> void:
	# Vertical industrial pipes ringing the chamber.
	var pipe_mat: Material
	if ResourceLoader.exists(RUSTY_STEEL_MAT_PATH):
		var base: StandardMaterial3D = load(RUSTY_STEEL_MAT_PATH)
		var dup := base.duplicate() as StandardMaterial3D
		dup.uv1_scale = Vector3(1.0, 6.0, 1.0)
		pipe_mat = dup
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.32, 0.36, 0.4)
		fallback.metallic = 0.85
		fallback.roughness = 0.35
		pipe_mat = fallback
	var pipe_mesh := CylinderMesh.new()
	pipe_mesh.top_radius = 0.35
	pipe_mesh.bottom_radius = 0.35
	pipe_mesh.height = 9.0
	var ring_radius := 22.5
	var segments := 14
	var ring := Node3D.new()
	ring.name = "PerimeterPipes"
	add_child(ring)
	for i in segments:
		if i == 4 or i == 10:
			continue
		var ang := TAU * float(i) / float(segments)
		var seg := MeshInstance3D.new()
		seg.mesh = pipe_mesh
		seg.set_surface_override_material(0, pipe_mat)
		seg.position = Vector3(cos(ang) * ring_radius, 4.5, sin(ang) * ring_radius)
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.add_child(seg)

func _build_girders() -> void:
	# Cross girders at the upper ring + an outer perimeter low wall.
	var girder_mat: Material
	if ResourceLoader.exists(RUSTY_STEEL_MAT_PATH):
		var base: StandardMaterial3D = load(RUSTY_STEEL_MAT_PATH)
		var dup := base.duplicate() as StandardMaterial3D
		dup.uv1_scale = Vector3(8.0, 1.0, 1.0)
		girder_mat = dup
	else:
		var fallback := StandardMaterial3D.new()
		fallback.albedo_color = Color(0.18, 0.2, 0.23)
		fallback.metallic = 0.7
		fallback.roughness = 0.5
		girder_mat = fallback
	var box := BoxMesh.new()
	box.size = Vector3(34.0, 0.35, 0.35)
	var girders := Node3D.new()
	girders.name = "Girders"
	add_child(girders)
	for i in 3:
		var g := MeshInstance3D.new()
		g.mesh = box
		g.set_surface_override_material(0, girder_mat)
		g.position = Vector3(0, 8.7, 0)
		g.rotation = Vector3(0, deg_to_rad(60.0 * float(i)), 0)
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		girders.add_child(g)
	# Low outer wall — short slab ring to ground the silhouette.
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(4.6, 1.6, 0.5)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.16, 0.18, 0.21)
	wall_mat.metallic = 0.2
	wall_mat.roughness = 0.85
	var walls := Node3D.new()
	walls.name = "LowWalls"
	add_child(walls)
	var wall_segments := 18
	for i in wall_segments:
		if i == 4 or i == 9 or i == 14:
			continue
		var ang := TAU * float(i) / float(wall_segments)
		var s := MeshInstance3D.new()
		s.mesh = wall_mesh
		s.set_surface_override_material(0, wall_mat)
		s.position = Vector3(cos(ang) * 23.0, 0.8, sin(ang) * 23.0)
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		walls.add_child(s)
		s.look_at(Vector3(0, 0.8, 0), Vector3.UP)

func _build_dust_motes() -> void:
	var p := GPUParticles3D.new()
	p.name = "DustMotes"
	add_child(p)
	p.amount = 90
	p.lifetime = 9.0
	p.preprocess = 4.0
	p.fixed_fps = 20
	p.position = Vector3(0, 4, 0)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(15, 5, 15)
	pm.direction = Vector3(0, -1, 0)
	pm.spread = 25.0
	pm.gravity = Vector3(0.0, -0.08, 0.0)
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.25
	pm.scale_min = 0.6
	pm.scale_max = 1.5
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(0.75, 0.85, 1.0, 0.0), Color(0.78, 0.88, 1.0, 0.22), Color(0.75, 0.85, 1.0, 0.0)])
	var gtex := GradientTexture1D.new()
	gtex.gradient = grad
	pm.color_ramp = gtex
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.06, 0.06)
	var dust_mat := StandardMaterial3D.new()
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.albedo_color = Color(0.82, 0.9, 1.0, 0.2)
	dust_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	qm.material = dust_mat
	p.draw_pass_1 = qm
	p.emitting = true
