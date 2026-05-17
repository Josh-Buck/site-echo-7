class_name Zombie extends CharacterBody3D

enum AIState { IDLE, CHASE, ATTACK, STAGGER, DIE }

@export var data: EnemyData

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var mesh: MeshInstance3D = $Mesh

var current_hp: float = 0.0
var state: int = AIState.IDLE
var _target: Node3D = null
var _attack_cooldown: float = 0.0
var _idle_timer: float = 0.5
var _stagger_timer: float = 0.0
var _die_timer: float = 0.0
var _nav_update_interval: float = 0.25
var _nav_update_accum: float = 0.0
var _gravity: float = 9.8

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
	_nav_update_accum = randf() * _nav_update_interval  # stagger crowd
	nav.path_desired_distance = 0.5
	nav.target_desired_distance = data.attack_range + BARRIER_RADIUS
	nav.avoidance_enabled = false
	_apply_data_visuals()
	_find_target()

func _apply_data_visuals() -> void:
	if data == null:
		return
	scale = Vector3.ONE * data.size_scale
	_tint_mesh($Mesh, data.body_color, false)
	_tint_mesh($Head, data.head_color, false)
	_tint_mesh($EyeL, data.eye_color, true)
	_tint_mesh($EyeR, data.eye_color, true)

func _tint_mesh(m: MeshInstance3D, color: Color, glowy: bool) -> void:
	if m == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.0
	mat.roughness = 0.85
	if glowy:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 3.0
	m.set_surface_override_material(0, mat)

func _find_target() -> void:
	var barriers := get_tree().get_nodes_in_group("barriers")
	if barriers.size() > 0:
		_target = barriers[0]

func _physics_process(delta: float) -> void:
	_nav_update_accum += delta
	if _nav_update_accum >= _nav_update_interval:
		_nav_update_accum = 0.0
		_update_nav_target()
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

func _update_nav_target() -> void:
	if _target == null:
		return
	nav.target_position = _target.global_position

func _state_idle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		state = AIState.CHASE

func _state_chase(_delta: float) -> void:
	if _target == null:
		return
	var dist := global_position.distance_to(_target.global_position)
	if dist <= data.attack_range + BARRIER_RADIUS:
		state = AIState.ATTACK
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var next := nav.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	dir = dir.normalized()
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
		if _target.has_method("take_damage"):
			_target.take_damage(data.attack_damage, self)
		_attack_cooldown = 1.0 / max(0.1, data.attack_rate)

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
	EventBus.enemy_damaged.emit(self, amount, source)
	if current_hp <= 0.0:
		state = AIState.DIE
		_die_timer = 0.6
		collision_layer = 0
		if data:
			GameState.tokens += data.token_drop
			EventBus.tokens_changed.emit(GameState.tokens, data.token_drop)
		EventBus.enemy_killed.emit(self, source, is_headshot, hit_position)

func is_headshot_position(pos: Vector3) -> bool:
	# Head sphere is centered at +1.55, radius 0.2. Anything in the head sphere zone counts.
	return pos.y > global_position.y + 1.35
