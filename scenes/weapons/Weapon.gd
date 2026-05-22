class_name Weapon extends Node3D

@export var data: WeaponData

var current_ammo: int = 0
var reserve_ammo: int = 0
var _fire_cooldown: float = 0.0
var _reloading: bool = false
var _reload_timer: float = 0.0
var _suppress_until_release: bool = true  # block fire until cursor captured + trigger released

@onready var muzzle_light: Node = get_node_or_null("MuzzleLight")
@onready var _fire_sfx_player: AudioStreamPlayer3D = get_node_or_null("FireSfx")
@onready var _reload_sfx_player: AudioStreamPlayer3D = get_node_or_null("ReloadSfx")

const ENEMY_MASK: int = 4  # physics layer 3
const RAY_MASK: int = 4 | 2  # zombies + world (barrier/floor) for tracer/impact endpoint
const TRACER_SCENE := preload("res://scenes/weapons/vfx/BulletTracer.tscn")
const TRACER_POOL_SCENE := preload("res://scenes/weapons/vfx/TracerPool.tscn")
const BULLETHOLE_POOL_SCENE := preload("res://scenes/weapons/vfx/BulletHolePool.tscn")
const SPARKS_SCENE := preload("res://scenes/weapons/vfx/ImpactSparks.tscn")
const WEAPON_METAL_MAT := preload("res://art/materials/weapon_metal/material.tres")
const WEAPON_POLYMER_MAT := preload("res://art/materials/weapon_polymer/material.tres")

# Viewmodel kick spring state (local-space, lerped each frame).
var _kick_offset: Vector3 = Vector3.ZERO
var _kick_pitch: float = 0.0
var _rest_position: Vector3 = Vector3.ZERO
var _kick_recovery: float = 0.12
var _muzzle_flash_active: bool = false
const MUZZLE_DECAY_PER_SEC: float = 75.0  # energy 9 -> ~0 in ~0.12s
const KICK_BACK_M: float = 0.06
const KICK_PITCH_DEG: float = 3.0

# Polymer surface name hints — grip/stock/pump get polymer; everything else gets metal.
const POLYMER_NAME_HINTS := ["grip", "stock", "pump", "handle", "foregrip", "magazine", "frame", "lower", "handguard", "trigger"]

func _ready() -> void:
	if data == null:
		push_error("[Weapon] no WeaponData assigned")
		return
	current_ammo = get_effective_mag_size()
	reserve_ammo = get_effective_reserve_max()
	if _fire_sfx_player and data.fire_sfx:
		_fire_sfx_player.stream = data.fire_sfx
	if _reload_sfx_player and data.reload_sfx:
		_reload_sfx_player.stream = data.reload_sfx
	_rest_position = position
	_apply_pbr_materials()

func get_effective_mag_size() -> int:
	return int(data.mag_size * CardSystem.get_modifier(&"mag_size"))

func get_effective_reserve_max() -> int:
	return int(data.reserve_ammo_max * CardSystem.get_modifier(&"reserve"))

func get_effective_reload_time() -> float:
	return data.reload_time * CardSystem.get_modifier(&"reload_time")

func get_effective_fire_rate() -> float:
	return data.fire_rate * CardSystem.get_modifier(&"fire_rate")

func _process(delta: float) -> void:
	_update_kick(delta)
	_decay_muzzle_flash(delta)
	if _fire_cooldown > 0.0:
		_fire_cooldown = max(0.0, _fire_cooldown - delta)
	if _reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_finish_reload()
		return
	if data == null:
		return
	# Block all weapon input while the cursor is loose — that means a menu is open
	# (card draft, shop, wave complete, etc.) or the player hasn't engaged yet.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_suppress_until_release = true
		return
	# After returning to gameplay, require the trigger to be released before firing.
	# This eats the click that captures the pointer or closes a UI panel.
	if _suppress_until_release:
		if Input.is_action_pressed("shoot"):
			return
		_suppress_until_release = false
	var wants_fire := false
	if data.automatic:
		wants_fire = Input.is_action_pressed("shoot")
	else:
		wants_fire = Input.is_action_just_pressed("shoot")
	if wants_fire:
		try_fire()
	if Input.is_action_just_pressed("reload"):
		try_reload()

func try_fire() -> bool:
	if _fire_cooldown > 0.0 or _reloading:
		return false
	if current_ammo <= 0:
		try_reload()
		return false
	_fire()
	return true

func try_reload() -> bool:
	if _reloading or current_ammo >= get_effective_mag_size():
		return false
	if not data.infinite_reserve and reserve_ammo <= 0:
		return false
	_reloading = true
	_reload_timer = get_effective_reload_time()
	_play_reload_sfx()
	return true

func is_reloading() -> bool:
	return _reloading

func get_ammo_state() -> Dictionary:
	return {
		"current": current_ammo,
		"reserve": reserve_ammo,
		"mag_size": get_effective_mag_size() if data else 0,
		"reloading": _reloading,
		"weapon_name": data.display_name if data else "",
		"infinite_reserve": data.infinite_reserve if data else false,
	}

func _fire() -> void:
	current_ammo -= 1
	_fire_cooldown = 1.0 / max(0.1, get_effective_fire_rate())
	# SFX first so the ear gets the leading edge on the same frame as the visual.
	_play_fire_sfx()
	_flash_muzzle()
	_kick()
	# Pellet weapons (shotgun) eject one shell at reload-end, not per-fire.
	if data.pellet_count <= 1:
		_eject_casing("right")
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		EventBus.weapon_fired.emit(self, _build_payload())
		return
	var pellets: int = max(1, data.pellet_count)
	for i in pellets:
		var pellet_payload := _build_payload()
		if pellets > 1:
			pellet_payload["damage"] = data.base_damage  # per-pellet damage stays at base
		if CardSystem and CardSystem.has_method("mutate_payload"):
			pellet_payload = CardSystem.mutate_payload(pellet_payload)
		_resolve_pellet(cam, pellet_payload)
	# Emit one weapon_fired per trigger pull (not per pellet) so HUD updates once.
	EventBus.weapon_fired.emit(self, _build_payload())

func _build_payload() -> Dictionary:
	return {
		"damage": data.base_damage,
		"headshot_multiplier": data.headshot_multiplier,
		"ammo_cost": 1,
		"source_weapon": self,
		"is_headshot": false,
		"hit_position": Vector3.ZERO,
		"hit_normal": Vector3.UP,
		"penetration_remaining": 0,
		"knockback_force": 0.0,
	}

func _resolve_pellet(cam: Camera3D, payload: Dictionary) -> void:
	var forward := -cam.global_transform.basis.z
	var right := cam.global_transform.basis.x
	var up := cam.global_transform.basis.y
	var dir := forward
	if data.spread_angle_deg > 0.0:
		var spread_rad := deg_to_rad(data.spread_angle_deg)
		var yaw := randf_range(-spread_rad, spread_rad)
		var pitch := randf_range(-spread_rad, spread_rad)
		dir = forward.rotated(up, yaw).rotated(right, pitch).normalized()
	var from := cam.global_transform.origin
	var to := from + dir * 100.0
	# Broad ray (zombies + world) so we always get a tracer endpoint, even on a "miss".
	var query := PhysicsRayQueryParameters3D.create(from, to, RAY_MASK)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := cam.get_world_3d().direct_space_state.intersect_ray(query)
	var endpoint: Vector3 = to
	var endpoint_normal: Vector3 = -dir
	var hit_node: Node = null
	if not result.is_empty():
		endpoint = result.position
		endpoint_normal = result.normal
		hit_node = result.collider
	_spawn_tracer(from, endpoint)
	if hit_node == null:
		return
	payload["hit_position"] = endpoint
	payload["hit_normal"] = endpoint_normal
	var is_enemy := hit_node.has_method("take_damage") and hit_node.is_in_group("zombies")
	if not is_enemy:
		# Hit world (barrier/floor) — sparks + bullet hole decal, no damage path.
		_spawn_sparks(endpoint, endpoint_normal)
		_stamp_bullethole(endpoint, endpoint_normal)
		return
	var hit: Node = hit_node
	if not hit.has_method("take_damage"):
		return
	var is_headshot := false
	if hit.has_method("is_headshot_position"):
		is_headshot = hit.is_headshot_position(result.position)
	payload["is_headshot"] = is_headshot
	var dmg: float = payload["damage"]
	if is_headshot:
		dmg *= float(payload["headshot_multiplier"])
	hit.take_damage(dmg, self, is_headshot, result.position)

func _finish_reload() -> void:
	var needed: int = get_effective_mag_size() - current_ammo
	var taken: int = needed
	if not data.infinite_reserve:
		taken = min(needed, reserve_ammo)
		reserve_ammo -= taken
	current_ammo += taken
	_reloading = false
	if data.pellet_count > 1:
		_eject_casing("down")
	EventBus.weapon_reloaded.emit(self)

func _play_fire_sfx() -> void:
	# Single, explicit call. No more dual paths (in-tscn stream + AudioMan synth)
	# layering on top of each other. AudioMan handles the synth lookup by weapon id.
	if data != null:
		AudioMan.play_weapon_fire(data.id)

func _play_reload_sfx() -> void:
	# Same single-path treatment for reload. No more in-tscn AudioStreamPlayer3D
	# autoplay-style behavior alongside the synth.
	AudioMan.play_weapon_reload()

func _flash_muzzle() -> void:
	if muzzle_light == null or not (muzzle_light is OmniLight3D):
		return
	var ml: OmniLight3D = muzzle_light
	ml.light_energy = 9.0
	ml.omni_range = 6.5
	# No tween — decays in _process below. Avoids allocating a Tween node every shot,
	# which was a small but real cost on the web build (~12x per shotgun pull).
	_muzzle_flash_active = true

func _muzzle_origin() -> Vector3:
	if muzzle_light is Node3D:
		return (muzzle_light as Node3D).global_position
	return global_position

func _spawn_tracer(from: Vector3, to: Vector3) -> void:
	# Pooled — was allocating a BulletTracer + StandardMaterial3D every shot,
	# which stuttered the web build (shotgun fired 12 of them per pull).
	var muzzle := _muzzle_origin()
	var dist := (to - muzzle).length()
	if dist < 0.05:
		return
	var pool := _get_tracer_pool()
	if pool != null and pool.has_method("fire"):
		pool.call("fire", muzzle, to)
		return
	# Fallback: legacy per-shot instantiate. Used only if the pool didn't spawn.
	var t := TRACER_SCENE.instantiate()
	get_tree().current_scene.add_child(t)
	if t.has_method("setup"):
		t.setup(muzzle, to)

var _cached_tracer_pool: Node = null
var _cached_bullethole_pool: Node = null

func _stamp_bullethole(at: Vector3, normal: Vector3) -> void:
	if _cached_bullethole_pool == null or not is_instance_valid(_cached_bullethole_pool):
		var existing := get_tree().get_nodes_in_group("bullethole_pool")
		if existing.is_empty():
			var p: Node = BULLETHOLE_POOL_SCENE.instantiate()
			get_tree().current_scene.add_child(p)
			_cached_bullethole_pool = p
		else:
			_cached_bullethole_pool = existing[0]
	if _cached_bullethole_pool.has_method("stamp"):
		_cached_bullethole_pool.call("stamp", at, normal)

func _get_tracer_pool() -> Node:
	if _cached_tracer_pool != null and is_instance_valid(_cached_tracer_pool):
		return _cached_tracer_pool
	var pools := get_tree().get_nodes_in_group("tracer_pool")
	if pools.is_empty():
		var p: Node = TRACER_POOL_SCENE.instantiate()
		get_tree().current_scene.add_child(p)
		_cached_tracer_pool = p
	else:
		_cached_tracer_pool = pools[0]
	return _cached_tracer_pool

func _spawn_sparks(at: Vector3, normal: Vector3) -> void:
	var s := SPARKS_SCENE.instantiate() as Node3D
	get_tree().current_scene.add_child(s)
	s.global_position = at
	# Aim the spark cone along the surface normal.
	if normal.length() > 0.001 and absf(normal.dot(Vector3.UP)) < 0.99:
		s.look_at(at + normal, Vector3.UP)
	# Rotate so process material's local +Y points along the normal:
	# our PPM has direction (0,1,0), so we want local Y aligned with normal.
	# Easiest: rotate so basis.y = normal.
	var up := normal.normalized()
	var ref := Vector3.UP if absf(up.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right := ref.cross(up).normalized()
	var fwd := up.cross(right).normalized()
	s.global_transform.basis = Basis(right, up, fwd)

func _kick() -> void:
	# Instantly add the kick; _update_kick springs it back to rest.
	_kick_offset.z = KICK_BACK_M
	_kick_pitch = deg_to_rad(KICK_PITCH_DEG)

func begin_swap_in() -> void:
	# Drop the weapon below its rest position and let _update_kick spring it up.
	_kick_offset.y = -0.18
	_kick_pitch = deg_to_rad(-4.0)

func _decay_muzzle_flash(delta: float) -> void:
	if not _muzzle_flash_active or muzzle_light == null:
		return
	var ml: OmniLight3D = muzzle_light
	ml.light_energy = max(0.0, ml.light_energy - MUZZLE_DECAY_PER_SEC * delta)
	if ml.light_energy <= 0.001:
		ml.light_energy = 0.0
		_muzzle_flash_active = false

func _update_kick(delta: float) -> void:
	var decay := exp(-delta / max(0.02, _kick_recovery))
	_kick_offset *= decay
	_kick_pitch *= decay
	position = _rest_position + _kick_offset
	# Negative X rotation pitches the muzzle (-Z) upward.
	rotation.x = -_kick_pitch

func _eject_casing(mode: String) -> void:
	var pool := _find_casing_pool()
	if pool == null:
		return
	pool.eject(_muzzle_origin(), global_transform.basis, mode)

func _find_casing_pool() -> CasingPool:
	var pools := get_tree().get_nodes_in_group("casing_pool")
	if pools.is_empty():
		return null
	var p := pools[0]
	if p is CasingPool:
		return p
	return null

func _apply_pbr_materials() -> void:
	# Skip override on weapons that bring their own GLB model — the imported
	# materials are correct and our flat polymer/metal swatches would erase them.
	if has_node("Model"):
		return
	for mi in _collect_mesh_instances(self):
		var lower := String(mi.name).to_lower()
		var is_polymer := false
		for hint in POLYMER_NAME_HINTS:
			if lower.find(hint) != -1:
				is_polymer = true
				break
		var mat: Material = WEAPON_POLYMER_MAT if is_polymer else WEAPON_METAL_MAT
		mi.set_surface_override_material(0, mat)

func _collect_mesh_instances(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for child in n.get_children():
		if child is MeshInstance3D:
			out.append(child)
		out.append_array(_collect_mesh_instances(child))
	return out
