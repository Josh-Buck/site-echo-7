class_name Weapon extends Node3D

@export var data: WeaponData

var current_ammo: int = 0
var reserve_ammo: int = 0
var _fire_cooldown: float = 0.0
var _reloading: bool = false
var _reload_timer: float = 0.0
var _suppress_until_release: bool = true  # block fire until cursor captured + trigger released

@onready var muzzle_light: Node = get_node_or_null("MuzzleLight")

const ENEMY_MASK: int = 4  # physics layer 3

func _ready() -> void:
	if data == null:
		push_error("[Weapon] no WeaponData assigned")
		return
	current_ammo = get_effective_mag_size()
	reserve_ammo = get_effective_reserve_max()

func get_effective_mag_size() -> int:
	return int(data.mag_size * CardSystem.get_modifier(&"mag_size"))

func get_effective_reserve_max() -> int:
	return int(data.reserve_ammo_max * CardSystem.get_modifier(&"reserve"))

func get_effective_reload_time() -> float:
	return data.reload_time * CardSystem.get_modifier(&"reload_time")

func get_effective_fire_rate() -> float:
	return data.fire_rate * CardSystem.get_modifier(&"fire_rate")

func _process(delta: float) -> void:
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
	if _reloading or reserve_ammo <= 0 or current_ammo >= get_effective_mag_size():
		return false
	_reloading = true
	_reload_timer = get_effective_reload_time()
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
	}

func _fire() -> void:
	current_ammo -= 1
	_fire_cooldown = 1.0 / max(0.1, get_effective_fire_rate())
	_flash_muzzle()
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
	var query := PhysicsRayQueryParameters3D.create(from, to, ENEMY_MASK)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := cam.get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return
	var hit: Node = result.collider
	payload["hit_position"] = result.position
	payload["hit_normal"] = result.normal
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
	var taken: int = min(needed, reserve_ammo)
	current_ammo += taken
	reserve_ammo -= taken
	_reloading = false
	EventBus.weapon_reloaded.emit(self)

func _flash_muzzle() -> void:
	if muzzle_light == null or not (muzzle_light is OmniLight3D):
		return
	var ml: OmniLight3D = muzzle_light
	ml.light_energy = 3.5
	var tw := create_tween()
	tw.tween_property(ml, "light_energy", 0.0, 0.08)
