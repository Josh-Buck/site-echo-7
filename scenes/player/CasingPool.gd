class_name CasingPool extends Node3D

# Pooled brass casings: small cylinders that tumble for ~3s then despawn.
# Pool keeps a hard cap so a long burst doesn't pile up the physics scene.

const POOL_MAX: int = 24
const CASING_LIFETIME: float = 3.0

var _metal_material: Material = preload("res://art/materials/weapon_metal/material.tres")
var _casing_mesh: CylinderMesh

class Casing:
	var body: RigidBody3D
	var spawn_time: float = -1.0

var _pool: Array[Casing] = []
var _next: int = 0

func _ready() -> void:
	add_to_group("casing_pool")
	# Top-level so casings stay in world space regardless of player rig motion.
	top_level = true
	_casing_mesh = CylinderMesh.new()
	_casing_mesh.top_radius = 0.006
	_casing_mesh.bottom_radius = 0.006
	_casing_mesh.height = 0.022
	_casing_mesh.radial_segments = 8
	_casing_mesh.rings = 1
	for i in POOL_MAX:
		var c := Casing.new()
		c.body = _build_body()
		add_child(c.body)
		_pool.append(c)

func _build_body() -> RigidBody3D:
	var b := RigidBody3D.new()
	b.gravity_scale = 1.6
	b.mass = 0.02
	b.continuous_cd = false
	b.can_sleep = true
	b.collision_layer = 0  # casings don't get hit by raycasts
	b.collision_mask = 2   # collide with environment (floor + barrier — layer 2)
	b.contact_monitor = false
	b.visible = false
	b.freeze = true
	b.physics_material_override = _physics_mat()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.008
	cyl.height = 0.022
	shape.shape = cyl
	b.add_child(shape)
	var mi := MeshInstance3D.new()
	mi.mesh = _casing_mesh
	mi.material_override = _metal_material
	b.add_child(mi)
	return b

func _physics_mat() -> PhysicsMaterial:
	var pm := PhysicsMaterial.new()
	pm.bounce = 0.3
	pm.friction = 0.6
	return pm

func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for c in _pool:
		if c.spawn_time < 0.0:
			continue
		if now - c.spawn_time >= CASING_LIFETIME:
			_retire(c)

func _retire(c: Casing) -> void:
	c.spawn_time = -1.0
	c.body.freeze = true
	c.body.visible = false
	c.body.linear_velocity = Vector3.ZERO
	c.body.angular_velocity = Vector3.ZERO

# direction: "right" for normal eject (pistol/AR), "down" for shotgun reload-eject.
func eject(world_origin: Vector3, weapon_basis: Basis, mode: String = "right") -> void:
	var c := _acquire()
	if c == null:
		return
	var right := weapon_basis.x.normalized()
	var up := weapon_basis.y.normalized()
	var back := weapon_basis.z.normalized()  # +Z is "back" (toward player) in Godot's view-space convention
	var pos := world_origin + right * 0.04 + up * 0.02 + back * 0.05
	c.body.global_position = pos
	# Random tumble.
	var rot := Basis()
	rot = rot.rotated(Vector3.UP, randf_range(0.0, TAU))
	rot = rot.rotated(Vector3.RIGHT, randf_range(0.0, TAU))
	c.body.global_transform = Transform3D(rot, pos)
	c.body.freeze = false
	c.body.visible = true
	c.body.sleeping = false
	var vel: Vector3
	if mode == "down":
		vel = (-up * 1.2) + back * 0.4 + right * randf_range(-0.3, 0.3)
	else:
		vel = right * randf_range(1.6, 2.4) + up * randf_range(0.6, 1.1) + back * randf_range(0.1, 0.4)
	c.body.linear_velocity = vel
	c.body.angular_velocity = Vector3(
		randf_range(-12.0, 12.0),
		randf_range(-12.0, 12.0),
		randf_range(-12.0, 12.0),
	)
	c.spawn_time = Time.get_ticks_msec() / 1000.0

func _acquire() -> Casing:
	# Round-robin reuse — oldest casing gets recycled when we wrap.
	for i in POOL_MAX:
		var idx := (_next + i) % POOL_MAX
		var c := _pool[idx]
		if c.spawn_time < 0.0:
			_next = (idx + 1) % POOL_MAX
			return c
	# All in use — recycle oldest.
	var oldest_idx := 0
	var oldest_t := INF
	for i in POOL_MAX:
		if _pool[i].spawn_time < oldest_t:
			oldest_t = _pool[i].spawn_time
			oldest_idx = i
	var c2 := _pool[oldest_idx]
	_retire(c2)
	_next = (oldest_idx + 1) % POOL_MAX
	return c2
