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

const BARRIER_RADIUS: float = 3.0

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
	_apply_data_visuals()
	_find_target()

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
	_tint_mesh($EyeL, data.eye_color, true, 4.0)
	_tint_mesh($EyeR, data.eye_color, true, 4.0)

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

func _find_target() -> void:
	var barriers := get_tree().get_nodes_in_group("barriers")
	if barriers.size() > 0:
		_target = barriers[0]

func _physics_process(delta: float) -> void:
	_groan_timer -= delta
	if _groan_timer <= 0.0 and state != AIState.DIE and state != AIState.ATTACK:
		_groan_timer = randf_range(4.0, 10.0)
		_play_random_groan()
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
	velocity.x = dir.x * data.move_speed
	velocity.z = dir.z * data.move_speed
	look_at(global_position + Vector3(dir.x, 0.0, dir.z), Vector3.UP)

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
	match data.attack_type:
		0:  # Melee
			_play_audio(attack_growl)
			if _target and _target.has_method("take_damage"):
				_target.take_damage(data.attack_damage, self)
				_play_audio(attack_hit)
		1:  # Ranged
			_play_audio(attack_growl)
			_fire_projectile()
		2:  # Suicide
			if _target and _target.has_method("take_damage"):
				_target.take_damage(data.attack_damage, self)
				_play_audio(attack_hit)
			# Self-destruct: skip past stagger, go straight to die.
			state = AIState.DIE
			_die_timer = 0.05
			collision_layer = 0
			_play_random_death()
			EventBus.enemy_killed.emit(self, null, false, global_position)

func _play_random_groan() -> void:
	var pool: Array[AudioStream] = []
	if groan_01: pool.append(groan_01)
	if groan_02: pool.append(groan_02)
	if groan_03: pool.append(groan_03)
	if pool.is_empty():
		return
	_play_audio(pool[randi() % pool.size()])

func _play_random_death() -> void:
	var pool: Array[AudioStream] = []
	if death_01: pool.append(death_01)
	if death_02: pool.append(death_02)
	if pool.is_empty():
		return
	_play_audio(pool[randi() % pool.size()])

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

func _spawn_blood_burst(at: Vector3, headshot: bool) -> void:
	var p := at
	if p == Vector3.ZERO:
		p = global_position + Vector3(0, 1.0, 0)
	var b := BLOOD_BURST_SCENE.instantiate() as Node3D
	get_tree().current_scene.add_child(b)
	b.global_position = p
	if b.has_method("setup"):
		b.setup(headshot)

func _begin_dissolve() -> void:
	# Slump + fade. Avoid replacing every surface material — just override on the whole
	# CharacterBody3D's child MeshInstance3Ds with a transparency-enabled copy.
	for child in _all_mesh_instances(self):
		var mat: Material = child.get_active_material(0)
		var sm := mat as StandardMaterial3D
		var dup: StandardMaterial3D = sm.duplicate() if sm else StandardMaterial3D.new()
		dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		child.set_surface_override_material(0, dup)
		var tw := create_tween()
		tw.tween_property(dup, "albedo_color:a", 0.0, DISSOLVE_TIME)
	var tw2 := create_tween()
	tw2.tween_property(self, "scale:y", scale.y * 0.15, DISSOLVE_TIME).set_trans(Tween.TRANS_CUBIC)

func _all_mesh_instances(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		out.append_array(_all_mesh_instances(c))
	return out
