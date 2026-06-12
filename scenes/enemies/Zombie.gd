class_name Zombie extends CharacterBody3D

enum AIState { IDLE, CHASE, ATTACK, STAGGER, DIE }

# Corpse lingers so the Death animation reads, then shrinks out quickly.
const CORPSE_LINGER: float = 1.05
const CORPSE_SHRINK: float = 0.35
const BARRIER_RADIUS: float = 3.0

@export var data: EnemyData

# Audio exports kept because Zombie.tscn assigns them; only attack_growl and
# attack_hit actually play (v0.9 audio restart silenced the rest).
@export_group("Audio")
@export var groan_01: AudioStream
@export var groan_02: AudioStream
@export var groan_03: AudioStream
@export var attack_growl: AudioStream
@export var attack_hit: AudioStream
@export var death_01: AudioStream
@export var death_02: AudioStream

@onready var _audio: AudioStreamPlayer3D = $AudioPlayer
@onready var _model: Node3D = $Model if has_node("Model") else null

var _anim_player: AnimationPlayer = null
var _anim_names: Dictionary = {}  # "walk"/"attack"/"death" -> imported animation name
var _base_pitch: float = 1.0
var current_hp: float = 0.0
var state: int = AIState.IDLE
var _target: Node3D = null
var _attack_cooldown: float = 0.0
var _idle_timer: float = 0.5
var _stagger_timer: float = 0.0
var _die_timer: float = 0.0
var _gravity: float = 9.8
var _enraged: bool = false  # Director phase-2 trigger
var _hit_flash_active: bool = false
# Material overrides created once per zombie; tint/flash just set albedo on
# these instead of re-duplicating materials per hit.
var _tint_overrides: Array[StandardMaterial3D] = []
var _current_tint: Color = Color.WHITE

func _ready() -> void:
	if data == null:
		push_error("[Zombie] no EnemyData assigned")
		queue_free()
		return
	current_hp = data.max_hp
	collision_layer = 4
	collision_mask = 2
	add_to_group("zombies")
	_init_audio_pitch()
	_init_anim_player()
	_apply_data_visuals()
	_find_target()

func _init_anim_player() -> void:
	if _model == null:
		return
	_anim_player = _find_anim_player(_model)
	if _anim_player == null:
		return
	_anim_player.playback_default_blend_time = 0.15
	# Resolve imported animation names case-insensitively — exporters sometimes
	# prefix or suffix track names.
	for anim_name in _anim_player.get_animation_list():
		var low := String(anim_name).to_lower()
		var anim := _anim_player.get_animation(anim_name)
		if anim == null:
			continue
		if low.contains("walk"):
			_anim_names["walk"] = String(anim_name)
			anim.loop_mode = Animation.LOOP_LINEAR
		elif low.contains("attack"):
			_anim_names["attack"] = String(anim_name)
			anim.loop_mode = Animation.LOOP_NONE
		elif low.contains("death") or low.contains("die"):
			_anim_names["death"] = String(anim_name)
			anim.loop_mode = Animation.LOOP_NONE
	# Faster archetypes shamble faster (walker move_speed ~1.2 is the baseline).
	if data != null:
		_anim_player.speed_scale = clamp(data.move_speed / 1.2, 0.7, 2.2)

func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var ap := _find_anim_player(c)
		if ap != null:
			return ap
	return null

func _play_anim(key: String, restart: bool = false) -> void:
	if _anim_player == null or not _anim_names.has(key):
		return
	var anim_name: String = _anim_names[key]
	if not restart and _anim_player.current_animation == anim_name and _anim_player.is_playing():
		return
	_anim_player.play(anim_name)
	if restart:
		_anim_player.seek(0.0, true)

func _init_audio_pitch() -> void:
	# Per-zombie variance so a horde isn't monotonous, biased by archetype.
	var bias: float = 1.0
	match data.id if data else &"":
		&"tank", &"director": bias = 0.85
		&"runner": bias = 1.10
		&"subject": bias = 0.9
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
	# Archetype tint multiplies over the Mixamo texture. body_color values were
	# authored for flat albedo — lighten them so the multiply doesn't crush the
	# texture to black (e.g. Director's 0.18-red would render near-black).
	var body_tint: Color
	if bool(MetaProgress.get_setting("colorblind", false)):
		body_tint = _colorblind_body_for(data.id).lerp(Color.WHITE, 0.25)
	else:
		body_tint = data.body_color.lerp(Color.WHITE, 0.45)
	_apply_glb_tint(body_tint)
	_play_anim("walk")

func _colorblind_body_for(id: StringName) -> Color:
	# High-contrast palette distinguishable without red/green discrimination.
	match id:
		&"walker":        return Color(0.65, 0.65, 0.7)
		&"runner":        return Color(0.25, 0.55, 0.85)
		&"tank":          return Color(0.85, 0.7, 0.2)
		&"spitter":       return Color(0.55, 0.3, 0.8)
		&"exploder":      return Color(0.95, 0.5, 0.1)
		&"walker_elite":  return Color(0.2, 0.85, 0.75)
		&"subject":       return Color(0.7, 0.7, 0.95)
		&"director":      return Color(0.9, 0.8, 0.5)
	return Color(0.65, 0.65, 0.7)

func _apply_glb_tint(tint: Color) -> void:
	_current_tint = tint
	if _model == null:
		return
	if _tint_overrides.is_empty():
		for child in _collect_meshes(_model):
			var src: Material = child.get_active_material(0)
			var dup: StandardMaterial3D
			if src is StandardMaterial3D:
				dup = (src as StandardMaterial3D).duplicate()
			else:
				dup = StandardMaterial3D.new()
				dup.roughness = 0.92
			child.set_surface_override_material(0, dup)
			_tint_overrides.append(dup)
	for m in _tint_overrides:
		m.albedo_color = tint

func _collect_meshes(n: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_collect_meshes(c))
	return out

func _find_target() -> void:
	var barriers := get_tree().get_nodes_in_group("barriers")
	if barriers.size() > 0:
		_target = barriers[0]

func _physics_process(delta: float) -> void:
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
	_play_anim("walk")
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
	var recruit_mult: float = 0.9 if bool(MetaProgress.get_setting("recruit_mode", false)) else 1.0
	# Token-shop "Chill Emitter" upgrade — applies to all zombies for one wave.
	return data.move_speed * rage_mult * recruit_mult * GameState.zombie_speed_mult_next_wave

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
	_play_anim("attack", true)
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
			# Self-destruct: vanish almost immediately (they exploded).
			state = AIState.DIE
			_die_timer = 0.05
			collision_layer = 0
			EventBus.enemy_killed.emit(self, null, false, global_position)

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
	if current_hp <= 0.0:
		state = AIState.DIE
		_die_timer = CORPSE_LINGER + CORPSE_SHRINK
		collision_layer = 0
		# Extra spray on the kill blow.
		_spawn_blood_burst(hit_position, is_headshot)
		_play_anim("death")
		_begin_dissolve()
		if data:
			GameState.tokens += data.token_drop
			EventBus.tokens_changed.emit(GameState.tokens, data.token_drop)
		EventBus.enemy_killed.emit(self, source, is_headshot, hit_position)
		return
	# Only survivors play the hit reaction — on a killing blow its scale tween
	# would race the dissolve shrink tween.
	_play_hit_reaction(is_headshot)

func is_headshot_position(pos: Vector3) -> bool:
	# Head zone scales with archetype size — Director is 2.2x tall, so a fixed
	# 1.35m threshold would count chest shots as headshots on big zombies.
	return pos.y > global_position.y + 1.35 * scale.y

func _check_director_rage() -> void:
	# Director (final boss) enters a phase-2 rage when HP drops below 50% — faster,
	# hits harder, body shifts red to telegraph the threat increase.
	if _enraged or data == null or data.id != &"director":
		return
	if current_hp > data.max_hp * 0.5:
		return
	_enraged = true
	_apply_glb_tint(Color(0.95, 0.3, 0.25))
	# Scale-pop exclamation. Blocks the hit-pop tween while running so two
	# tweens never fight over `scale`.
	_hit_flash_active = true
	var tw := create_tween()
	tw.tween_property(self, "scale", scale * 1.15, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", scale, 0.32)
	tw.finished.connect(func(): _hit_flash_active = false)
	_play_audio(attack_growl)

func _play_hit_reaction(is_headshot: bool) -> void:
	# Brief scale-pop + white flash on hit. Sells "you connected" without a
	# rigged stagger animation.
	if _hit_flash_active:
		return
	_hit_flash_active = true
	var base_scale := scale
	var pop_scale := base_scale * (1.12 if is_headshot else 1.05)
	var tw := create_tween()
	tw.tween_property(self, "scale", pop_scale, 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", base_scale, 0.10)
	tw.finished.connect(func(): _hit_flash_active = false)
	if is_headshot:
		_flash_white()

func _flash_white() -> void:
	# Critical-hit flash — sets albedo on the cached overrides (no allocations),
	# restores the current tint (handles rage recolor correctly).
	if _tint_overrides.is_empty():
		return
	for m in _tint_overrides:
		m.albedo_color = Color(1, 1, 1)
	get_tree().create_timer(0.06).timeout.connect(func():
		if is_instance_valid(self):
			for m in _tint_overrides:
				m.albedo_color = _current_tint
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
	var pool := _get_blood_pool()
	if pool != null and pool.has_method("burst"):
		pool.call("burst", p, headshot)

func _begin_dissolve() -> void:
	# Let the Death animation play out, then shrink the corpse away. One tween,
	# no per-mesh material allocations (those caused the old per-kill hitch).
	var tw := create_tween()
	tw.tween_interval(CORPSE_LINGER)
	tw.tween_property(self, "scale", scale * 0.05, CORPSE_SHRINK).set_trans(Tween.TRANS_CUBIC)
