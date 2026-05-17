class_name Weapon extends Node3D

@export var data: WeaponData

var current_ammo: int = 0
var reserve_ammo: int = 0
var _fire_cooldown: float = 0.0
var _reloading: bool = false
var _reload_timer: float = 0.0

const ENEMY_MASK: int = 4  # physics layer 3 = bit (1 << 2)

func _ready() -> void:
	if data == null:
		push_error("[Weapon] no WeaponData assigned")
		return
	current_ammo = data.mag_size
	reserve_ammo = data.reserve_ammo_max

func _process(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown = max(0.0, _fire_cooldown - delta)
	if _reloading:
		_reload_timer -= delta
		if _reload_timer <= 0.0:
			_finish_reload()

func _unhandled_input(event: InputEvent) -> void:
	if data == null:
		return
	if event.is_action_pressed("shoot"):
		try_fire()
	elif event.is_action_pressed("reload"):
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
	if _reloading or reserve_ammo <= 0 or current_ammo >= data.mag_size:
		return false
	_reloading = true
	_reload_timer = data.reload_time
	return true

func is_reloading() -> bool:
	return _reloading

func get_ammo_state() -> Dictionary:
	return {
		"current": current_ammo,
		"reserve": reserve_ammo,
		"mag_size": data.mag_size if data else 0,
		"reloading": _reloading,
	}

func _fire() -> void:
	current_ammo -= 1
	_fire_cooldown = 1.0 / max(0.1, data.fire_rate)
	var payload := _build_payload()
	if CardSystem and CardSystem.has_method("mutate_payload"):
		payload = CardSystem.mutate_payload(payload)
	_resolve_hit(payload)
	EventBus.weapon_fired.emit(self, payload)

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

func _resolve_hit(payload: Dictionary) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.global_transform.origin
	var to := from + (-cam.global_transform.basis.z) * 100.0
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
	var needed: int = data.mag_size - current_ammo
	var taken: int = min(needed, reserve_ammo)
	current_ammo += taken
	reserve_ammo -= taken
	_reloading = false
	EventBus.weapon_reloaded.emit(self)
