class_name Zombie extends CharacterBody3D

enum AIState { IDLE, CHASE, ATTACK, STAGGER, DIE }

const BLOOD_BURST_SCENE := preload("res://scenes/enemies/vfx/BloodBurst.tscn")
const DISSOLVE_TIME: float = 0.55

@export var data: EnemyData

@export_group("Audio")
@export var groan_01: AudioStream
@export var groan_02: AudioStream
@export var groan_03: AudioStream
@export var attack_growl: AudioStream
@export var attack_hit: AudioStream
@export var death_01: AudioStream
@export var death_02: AudioStream

@onready var mesh: MeshInstance3D = $Mesh
@onready var _audio: AudioStreamPlayer3D = $AudioPlayer
@onready var _foot_audio: AudioStreamPlayer3D = $FootstepPlayer

var _base_pitch: float = 1.0

var current_hp: float = 0.0
var state: int = AIState.IDLE
var _target: Node3D = null
var _attack_cooldown: float = 0.0
var _idle_timer: float = 0.5
var _stagger_timer: float = 0.0
var _die_timer: float = 0.0
var _gravity: float = 9.8
var _groan_timer: float = 0.0
var _footstep_timer: float = 0.0
var _footstep_interval: float = 0.45
var _footstep_pool: Array = []
var _enraged: bool = false  # Director phase-2 trigger

const BARRIER_RADIUS: float = 3.0
# Cap on simultaneous footstep emitters per tick — nearest-N to listener.
const FOOTSTEP_AUDIBLE_CAP: int = 6

const FOOTSTEPS_CONCRETE := [
	preload("res://audio/sfx/footsteps/concrete/a_1.ogg"),
	preload("res://audio/sfx/footsteps/concrete/a_2.ogg"),
	preload("res://audio/sfx/footsteps/concrete/a_3.ogg"),
	preload("res://audio/sfx/footsteps/concrete/a_4.ogg"),
]
const FOOTSTEPS_METAL := [
	preload("res://audio/sfx/footsteps/metal/grate_1.ogg"),
	preload("res://audio/sfx/footsteps/metal/grate_2.ogg"),
	preload("res://audio/sfx/footsteps/metal/grate_3.ogg"),
	preload("res://audio/sfx/footsteps/metal/grate_4.ogg"),
]

const BODY_MAT_PATH := "res://art/materials/weapon_polymer/material.tres"
const TANK_BODY_MAT_PATH := "res://art/materials/rusty_steel/material.tres"

func _ready() -> void:
	if data == null:
		push_error("[Zombie] no EnemyData assigned")
		queue_free()
		return
	current_hp = data.max_hp
	collision_layer = 4
	collision_mask = 2
	add_to_group("zombies")
	_groan_timer = randf_range(2.0, 6.0)
	_init_audio_pitch()
	_init_footsteps()
	_apply_data_visuals()
	_apply_pbr_body_material()
	_find_target()

func _init_footsteps() -> void:
	# Cadence scales with archetype: faster mover = quicker step.
	var id: StringName = data.id if data else &""
	match id:
		&"runner": _footstep_interval = 0.22
		&"tank", &"director": _footstep_interval = 0.6
		&"subject": _footstep_interval = 0.5
		_: _footstep_interval = 0.45
	# Surface pool chosen once at spawn — the arena doesn't change mid-run.
	_footstep_pool = _pick_footstep_pool()
	# Stagger initial offset so a wave doesn't fire footsteps in lockstep.
	_footstep_timer = randf_range(0.0, _footstep_interval)

func _pick_footstep_pool() -> Array:
	# Main.tscn replaces its Arena child in-place (no scene_change), so checking
	# the current_scene path always returns "Main.tscn". We have to read the
	# actual Arena instance's source file instead.
	var cs := get_tree().current_scene
	if cs:
		var arena := cs.get_node_or_null("Arena")
		if arena and arena.scene_file_path.find("CoolingTower") != -1:
			return FOOTSTEPS_METAL
	return FOOTSTEPS_CONCRETE

func _init_audio_pitch() -> void:
	# Per-zombie variance so a horde isn't monotonous, biased by archetype.
	var bias: float = 1.0
	var id: StringName = data.id if data else &""
	match id:
		&"tank", &"director": bias = 0.85
		&"runner": bias = 1.10
		&"subject": bias = 0.9
		_:
			# Node-name fallback when data isn't keyed conventionally.
			var n := name.to_lower()
			if "tank" in n: bias = 0.85
			elif "runner" in n: bias = 1.10
	_base_pitch = bias * randf_range(0.9, 1.1)

func _play_audio(stream: AudioStream) -> void:
	if stream == null or _audio == null:
		return
	_audio.stream = stream
	_audio.pitch_scale = _base_pitch * randf_range(0.97, 1.03)
	_audio.play()

func _apply_data_visuals() -> void:
	if data == null:
		return
	scale = Vector3.ONE * data.size_scale
	_tint_mesh($Mesh, data.body_color, false)
	_tint_mesh($Head, data.head_color, false)
	# Colorblind mode replaces the red/orange eye glow with high-contrast hues
	# per archetype so the player can still distinguish them at a glance.
	var eye_col: Color = data.eye_color
	if bool(MetaProgress.get_setting("colorblind", false)):
		eye_col = _colorblind_eye_for(data.id)
	_tint_mesh($EyeL, eye_col, true, 4.0)
	_tint_mesh($EyeR, eye_col, true, 4.0)
	# Tint limbs to a darkened variant of the body so the whole zombie reads as one
	# decaying creature instead of a body + grey detached limbs.
	var limb_color: Color = data.body_color.darkened(0.25)
	_tint_mesh_if_present(&"ArmL", limb_color, false)
	_tint_mesh_if_present(&"ArmR", limb_color, false)
	_tint_mesh_if_present(&"LegL", limb_color, false)
	_tint_mesh_if_present(&"LegR", limb_color, false)
	_tint_mesh_if_present(&"Shoulders", data.body_color.darkened(0.4), false)

func _colorblind_eye_for(id: StringName) -> Color:
	# Distinct, easily-distinguishable hues that don't rely on red/green discrimination.
	# Tested for deuteranopia + protanopia legibility.
	match id:
		&"walker":        return Color(1.0, 1.0, 1.0)
		&"runner":        return Color(0.3, 0.7, 1.0)
		&"tank":          return Color(1.0, 0.85, 0.0)
		&"spitter":       return Color(0.7, 0.4, 1.0)
		&"exploder":      return Color(1.0, 0.5, 0.0)
		&"walker_elite":  return Color(0.0, 1.0, 0.85)
		&"subject":       return Color(0.85, 0.85, 1.0)
		&"director":      return Color(1.0, 0.95, 0.7)
	return Color(1.0, 1.0, 1.0)

func _tint_mesh_if_present(node_name: StringName, color: Color, glowy: bool) -> void:
	var m := get_node_or_null(NodePath(node_name)) as MeshInstance3D
	if m != null:
		_tint_mesh(m, color, glowy)

func _tint_mesh(m: MeshInstance3D, color: Color, glowy: bool, emission_strength: float = 3.0) -> void:
	if m == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.0
	mat.roughness = 0.85
	if glowy:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_strength
	m.set_surface_override_material(0, mat)

func _apply_pbr_body_material() -> void:
	# Body + head get a PBR base (polymer for grunts, rusty steel for armored Tanks)
	# while preserving the per-archetype tint that distinguishes the silhouette.
	# Eye glow logic is untouched.
	if data == null:
		return
	var id: StringName = data.id
	var path := TANK_BODY_MAT_PATH if (id == &"tank" or id == &"director") else BODY_MAT_PATH
	if not ResourceLoader.exists(path):
		return
	var base: StandardMaterial3D = load(path)
	if base == null:
		return
	_apply_tinted_pbr($Mesh, base, data.body_color)
	_apply_tinted_pbr($Head, base, data.head_color)

func _apply_tinted_pbr(m: MeshInstance3D, base: StandardMaterial3D, tint: Color) -> void:
	if m == null:
		return
	var dup := base.duplicate() as StandardMaterial3D
	# Modulate albedo with the team tint so PBR detail reads but identification holds.
	dup.albedo_color = tint
	m.set_surface_override_material(0, dup)

func _find_target() -> void:
	var barriers := get_tree().get_nodes_in_group("barriers")
	if barriers.size() > 0:
		_target = barriers[0]

func _physics_process(delta: float) -> void:
	# Zombie groans muted at the source. With 10+ zombies stacking, even quiet
	# groans read as background chatter / muffled gunfire. Re-enable as a single
	# "horde ambient" 2D bed later if needed.
	_groan_timer -= delta
	# Footsteps disabled (same reason as groans — too many overlapping sources).
	match state:
		AIState.IDLE:
			_state_idle(delta)
		AIState.CHASE:
			_state_chase(delta)
		AIState.ATTACK:
			_state_attack(delta)
		AIState.STAGGER:
			_state_stagger(delta)
		AIState.DIE:
			_state_die(delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	move_and_slide()

func _state_idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		state = AIState.CHASE

func _state_chase(_delta: float) -> void:
	if _target == null:
		return
	var to_target := _target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	if dist <= data.attack_range + BARRIER_RADIUS:
		state = AIState.ATTACK
		velocity.x = 0.0
		velocity.z = 0.0
		return
	if dist < 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	# Direct steering — arena is a flat circle with the barrier as the only obstacle.
	# CharacterBody3D.move_and_slide handles sliding along the barrier collision.
	var dir := to_target / dist
	var spd := _effective_move_speed()
	velocity.x = dir.x * spd
	velocity.z = dir.z * spd
	look_at(global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)

func _effective_move_speed() -> float:
	if data == null:
		return 0.0
	var rage_mult: float = 1.5 if _enraged else 1.0
	# Token-shop "Chill Emitter" upgrade — applies to all zombies for one wave.
	return data.move_speed * rage_mult * GameState.zombie_speed_mult_next_wave

func _effective_attack_damage() -> float:
	if data == null:
		return 0.0
	return data.attack_damage * (1.25 if _enraged else 1.0)

func _state_attack(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _target == null:
		state = AIState.CHASE
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist > data.attack_range + BARRIER_RADIUS + 0.5:
		state = AIState.CHASE
		return
	_attack_cooldown -= delta
	if _attack_cooldown <= 0.0:
		_perform_attack()
		_attack_cooldown = 1.0 / max(0.1, data.attack_rate)

func _perform_attack() -> void:
	var dmg := _effective_attack_damage()
	match data.attack_type:
		0:  # Melee
			_play_audio(attack_growl)
			if _target and _target.has_method("take_damage"):
				_target.take_damage(dmg, self)
				_play_audio(attack_hit)
		1:  # Ranged
			_play_audio(attack_growl)
			_fire_projectile()
		2:  # Suicide
			if _target and _target.has_method("take_damage"):
				_target.take_damage(dmg, self)
				_play_audio(attack_hit)
			# Self-destruct: skip past stagger, go straight to die.
			state = AIState.DIE
			_die_timer = 0.05
			collision_layer = 0
			_play_random_death()
			EventBus.enemy_killed.emit(self, null, false, global_position)

func _try_play_footstep() -> void:
	if _foot_audio == null or _footstep_pool.is_empty():
		return
	# Listener is the locked player at origin (player is stationary by design).
	var self_d2: float = global_position.x * global_position.x + global_position.z * global_position.z
	# Rank ourselves by distance among living chasers. Skip if not in nearest N.
	var closer_count: int = 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if z == self:
			continue
		var zz := z as Node3D
		if zz == null:
			continue
		var d2: float = zz.global_position.x * zz.global_position.x + zz.global_position.z * zz.global_position.z
		if d2 < self_d2:
			closer_count += 1
			if closer_count >= FOOTSTEP_AUDIBLE_CAP:
				return
	var stream: AudioStream = _footstep_pool[randi() % _footstep_pool.size()]
	_foot_audio.stream = stream
	_foot_audio.pitch_scale = _base_pitch * randf_range(0.92, 1.08)
	_foot_audio.play()

func _play_random_groan() -> void:
	var pool: Array[AudioStream] = []
	if groan_01: pool.append(groan_01)
	if groan_02: pool.append(groan_02)
	if groan_03: pool.append(groan_03)
	if pool.is_empty():
		return
	_play_audio(pool[randi() % pool.size()])

func _play_random_death() -> void:
	# Death OGGs disabled. With 10+ kills per wave they layer into a percussive
	# backdrop that reads as gunfire. The visual blood burst + dissolve is the
	# kill feedback; a clean kill confirm comes from the on-screen score popup
	# (HUD enemy_killed listener).
	pass

func _fire_projectile() -> void:
	if data.projectile_scene == null or _target == null:
		return
	var proj := data.projectile_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	if proj is Node3D:
		var origin: Vector3 = global_position + Vector3(0.0, 1.4, 0.0)
		(proj as Node3D).global_position = origin
		var dir: Vector3 = (_target.global_position - origin).normalized()
		if proj.has_method("launch"):
			proj.launch(dir, data.projectile_speed, data.attack_damage)

func _state_stagger(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_stagger_timer -= delta
	if _stagger_timer <= 0.0:
		state = AIState.CHASE

func _state_die(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_die_timer -= delta
	if _die_timer <= 0.0:
		queue_free()

func take_damage(amount: float, source: Node = null, is_headshot: bool = false, hit_position: Vector3 = Vector3.ZERO) -> void:
	if state == AIState.DIE:
		return
	# Armor: non-headshot hits reduced by 50%. Headshots punch through armor.
	if data and data.armor and not is_headshot:
		amount *= 0.5
	current_hp -= amount
	EventBus.enemy_damaged.emit(self, amount, source, hit_position, is_headshot)
	_spawn_blood_burst(hit_position, is_headshot)
	_check_director_rage()
	_play_hit_reaction(is_headshot)
	if current_hp <= 0.0:
		state = AIState.DIE
		_die_timer = DISSOLVE_TIME
		collision_layer = 0
		# Extra spray on the kill blow.
		_spawn_blood_burst(hit_position, is_headshot)
		_play_random_death()
		_begin_dissolve()
		if data:
			GameState.tokens += data.token_drop
			EventBus.tokens_changed.emit(GameState.tokens, data.token_drop)
		EventBus.enemy_killed.emit(self, source, is_headshot, hit_position)

func is_headshot_position(pos: Vector3) -> bool:
	# Head sphere is centered at +1.55, radius 0.2. Anything in the head sphere zone counts.
	return pos.y > global_position.y + 1.35

func _check_director_rage() -> void:
	# Director (final boss) enters a phase-2 rage when HP drops below 50% — faster,
	# hits harder, body color shifts to telegraph the threat increase.
	if _enraged or data == null or data.id != &"director":
		return
	if current_hp > data.max_hp * 0.5:
		return
	_enraged = true
	# Recolor body + head to a brighter red, intensify eye glow.
	var rage_body := Color(0.85, 0.05, 0.08, 1)
	var rage_head := Color(1.0, 0.1, 0.12, 1)
	var rage_eyes := Color(1.0, 0.4, 0.3, 1)
	_tint_mesh($Mesh, rage_body, false)
	_tint_mesh($Head, rage_head, false)
	_tint_mesh($EyeL, rage_eyes, true, 7.0)
	_tint_mesh($EyeR, rage_eyes, true, 7.0)
	# Brief scale-pop tween — visual exclamation.
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.15, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", scale, 0.32)
	# Diegetic audio cue: re-use death roar at full pitch as a phase-shift bellow.
	_play_audio(attack_growl)

var _hit_flash_active: bool = false

func _play_hit_reaction(is_headshot: bool) -> void:
	# Brief scale-pop + white-tint flash on hit. Sells "you connected" feedback
	# without the cost of a rigged stagger animation.
	if _hit_flash_active:
		return
	_hit_flash_active = true
	var base_scale := scale
	var pop_scale := base_scale * (1.18 if is_headshot else 1.08)
	var tw := create_tween()
	tw.tween_property(self, "scale", pop_scale, 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", base_scale, 0.10)
	tw.finished.connect(func(): _hit_flash_active = false)
	if is_headshot:
		_flash_white()

func _flash_white() -> void:
	# Critical-hit flash — body briefly tints toward white. Reverts via tween that
	# re-applies the archetype color.
	if data == null:
		return
	var orig_body := data.body_color
	_tint_mesh($Mesh, Color(1, 1, 1), false)
	get_tree().create_timer(0.06).timeout.connect(func():
		if is_instance_valid(self) and state != AIState.DIE:
			_tint_mesh($Mesh, orig_body, false)
	)

const BLOOD_POOL_SCENE := preload("res://scenes/enemies/vfx/BloodBurstPool.tscn")
var _cached_blood_pool: Node = null

func _get_blood_pool() -> Node:
	if _cached_blood_pool != null and is_instance_valid(_cached_blood_pool):
		return _cached_blood_pool
	var existing := get_tree().get_nodes_in_group("bloodburst_pool")
	if existing.is_empty():
		var p := BLOOD_POOL_SCENE.instantiate()
		get_tree().current_scene.add_child(p)
		_cached_blood_pool = p
	else:
		_cached_blood_pool = existing[0]
	return _cached_blood_pool

func _spawn_blood_burst(at: Vector3, headshot: bool) -> void:
	if not MetaProgress.gore_enabled():
		return
	var p := at
	if p == Vector3.ZERO:
		p = global_position + Vector3(0, 1.0, 0)
	# Pooled — was instantiating + queue_freeing a GPUParticles3D + ParticleProcessMaterial
	# per kill which uploaded shader/material to GPU each time. Stutter on web.
	var pool := _get_blood_pool()
	if pool != null and pool.has_method("burst"):
		pool.call("burst", p, headshot)

func _begin_dissolve() -> void:
	# Previously this duplicated the StandardMaterial3D on every child mesh and made
	# a fade tween per mesh — 9 allocations + 9 tweens per kill on the humanoid
	# zombie, which was the user's per-kill hitch. Now: one tween that scales the
	# whole zombie down to a sliver. Visual reads as "they collapsed."
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(scale.x * 0.05, scale.y * 0.05, scale.z * 0.05), DISSOLVE_TIME).set_trans(Tween.TRANS_CUBIC)

func _all_mesh_instances(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out.append_array(_all_mesh_instances(c))
	return out
