extends Node

# Procedural audio: SFX synthesized at runtime as AudioStreamWAV via simple DSP.
# All sounds cache after first generation. Pure GDScript — no external assets.

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 16

var _gesture_received: bool = false
var _cache: Dictionary = {}  # String id -> AudioStreamWAV
var _2d_pool: Array[AudioStreamPlayer] = []
var _3d_pool: Array[AudioStreamPlayer3D] = []
var _2d_idx: int = 0
var _3d_idx: int = 0

func _ready() -> void:
	print("[AudioMan] ready")
	_build_pools()
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.weapon_reloaded.connect(_on_weapon_reloaded)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.barrier_damaged.connect(_on_barrier_damaged)
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.card_drafted.connect(_on_card_drafted)
	EventBus.shop_opened.connect(_on_shop_opened)

func _build_pools() -> void:
	for i in POOL_SIZE:
		var p2d := AudioStreamPlayer.new()
		p2d.bus = &"Master"
		add_child(p2d)
		_2d_pool.append(p2d)
		var p3d := AudioStreamPlayer3D.new()
		p3d.bus = &"Master"
		p3d.max_distance = 40.0
		p3d.unit_size = 5.0
		add_child(p3d)
		_3d_pool.append(p3d)

func register_first_gesture() -> void:
	if _gesture_received:
		return
	_gesture_received = true
	print("[AudioMan] first user gesture registered, audio enabled")

func can_play() -> bool:
	return _gesture_received

func play_sfx(id: String, pos = null) -> void:
	if not _gesture_received:
		return
	var stream := _get_sfx(id)
	if stream == null:
		return
	if pos == null:
		_play_2d(stream)
	else:
		_play_3d(stream, pos as Vector3)

func _play_2d(stream: AudioStreamWAV) -> void:
	# Round-robin so rapid fire doesn't kill itself.
	var p := _2d_pool[_2d_idx]
	_2d_idx = (_2d_idx + 1) % _2d_pool.size()
	p.stream = stream
	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()

func _play_3d(stream: AudioStreamWAV, pos: Vector3) -> void:
	var p := _3d_pool[_3d_idx]
	_3d_idx = (_3d_idx + 1) % _3d_pool.size()
	p.stream = stream
	p.pitch_scale = randf_range(0.92, 1.08)
	p.global_position = pos
	p.play()

func _get_sfx(id: String) -> AudioStreamWAV:
	if not _cache.has(id):
		var s := _synth(id)
		if s != null:
			_cache[id] = s
	return _cache.get(id)

func _synth(id: String) -> AudioStreamWAV:
	match id:
		"pistol_fire": return _synth_pistol_fire()
		"shotgun_fire": return _synth_shotgun_fire()
		"ar_fire": return _synth_ar_fire()
		"reload": return _synth_reload()
		"zombie_groan": return _synth_zombie_groan()
		"zombie_death": return _synth_zombie_death()
		"barrier_hit": return _synth_barrier_hit()
		"barrier_destroyed": return _synth_barrier_destroyed()
		"ui_click": return _synth_ui_click()
		"wave_start": return _synth_wave_start()
		"card_pick": return _synth_card_pick()
		"shop_open": return _synth_shop_open()
	push_warning("[AudioMan] unknown sfx id: %s" % id)
	return null

# --- Synth helpers ---

func _make_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var s: float = clamp(samples[i], -1.0, 1.0)
		var v: int = int(s * 32767.0)
		bytes.encode_s16(i * 2, v)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

# --- Specific sounds ---

func _synth_pistol_fire() -> AudioStreamWAV:
	var dur := 0.16
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 28.0)
		var noise: float = randf() * 2.0 - 1.0
		if i > 0:
			noise = noise * 0.45 + samples[i-1] * 0.55
		samples[i] = noise * env * 0.7
	return _make_stream(samples)

func _synth_shotgun_fire() -> AudioStreamWAV:
	var dur := 0.28
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 14.0)
		var noise: float = randf() * 2.0 - 1.0
		if i > 0:
			noise = noise * 0.3 + samples[i-1] * 0.7
		var thump: float = sin(2.0 * PI * 80.0 * t) * exp(-t * 25.0) * 0.4
		samples[i] = (noise * 0.7 + thump) * env * 0.95
	return _make_stream(samples)

func _synth_ar_fire() -> AudioStreamWAV:
	var dur := 0.09
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 45.0)
		var noise: float = randf() * 2.0 - 1.0
		if i > 0:
			noise = noise * 0.6 + samples[i-1] * 0.4
		samples[i] = noise * env * 0.55
	return _make_stream(samples)

func _synth_reload() -> AudioStreamWAV:
	var dur := 0.45
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var click1: float = (randf() * 2.0 - 1.0) * exp(-t * 60.0) * 0.6
		var click2_t: float = t - 0.18
		var click2: float = 0.0
		if click2_t > 0.0:
			click2 = (randf() * 2.0 - 1.0) * exp(-click2_t * 55.0) * 0.5
		var slide_t: float = t - 0.32
		var slide: float = 0.0
		if slide_t > 0.0:
			slide = (randf() * 2.0 - 1.0) * exp(-slide_t * 18.0) * 0.4
		samples[i] = click1 + click2 + slide
	return _make_stream(samples)

func _synth_zombie_groan() -> AudioStreamWAV:
	var dur := 0.75
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var freq: float = 70.0 + randf_range(-15.0, 15.0)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = sin(PI * t / dur) * exp(-t * 1.5)
		var vibrato: float = 1.0 + sin(t * 16.0) * 0.06
		var fund: float = sin(2.0 * PI * freq * vibrato * t) * 0.55
		var harm: float = sin(2.0 * PI * freq * 2.0 * vibrato * t) * 0.22
		var rasp: float = (randf() * 2.0 - 1.0) * 0.22
		samples[i] = (fund + harm + rasp) * env * 0.85
	return _make_stream(samples)

func _synth_zombie_death() -> AudioStreamWAV:
	var dur := 0.5
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var freq_start := 130.0
	var freq_end := 45.0
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var f: float = lerp(freq_start, freq_end, t / dur)
		var env: float = (1.0 - t / dur) * 0.7
		var tone: float = sin(2.0 * PI * f * t) * 0.5
		var rasp: float = (randf() * 2.0 - 1.0) * 0.35
		samples[i] = (tone + rasp) * env
	return _make_stream(samples)

func _synth_barrier_hit() -> AudioStreamWAV:
	var dur := 0.22
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 14.0)
		var clang: float = sin(2.0 * PI * 220.0 * t) * 0.35 + sin(2.0 * PI * 330.0 * t) * 0.28 + sin(2.0 * PI * 510.0 * t) * 0.15
		var click: float = (randf() * 2.0 - 1.0) * exp(-t * 70.0) * 0.5
		samples[i] = (clang + click) * env
	return _make_stream(samples)

func _synth_barrier_destroyed() -> AudioStreamWAV:
	var dur := 1.2
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 2.0)
		var rumble: float = sin(2.0 * PI * 55.0 * t) * 0.5 + sin(2.0 * PI * 75.0 * t) * 0.35
		var crash: float = (randf() * 2.0 - 1.0) * exp(-t * 6.0) * 0.6
		samples[i] = (rumble + crash) * env
	return _make_stream(samples)

func _synth_ui_click() -> AudioStreamWAV:
	var dur := 0.06
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 70.0)
		var tone: float = sin(2.0 * PI * 780.0 * t)
		samples[i] = tone * env * 0.35
	return _make_stream(samples)

func _synth_wave_start() -> AudioStreamWAV:
	var dur := 0.7
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var f0 := 200.0
	var f1 := 580.0
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var f: float = lerp(f0, f1, t / dur)
		var env: float = sin(PI * t / dur) * 0.45
		var tone: float = sin(2.0 * PI * f * t) + sin(2.0 * PI * f * 1.5 * t) * 0.45
		samples[i] = tone * env
	return _make_stream(samples)

func _synth_card_pick() -> AudioStreamWAV:
	var dur := 0.3
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var f: float = lerp(440.0, 880.0, t / dur)
		var env: float = exp(-t * 6.0) * 0.4
		samples[i] = sin(2.0 * PI * f * t) * env
	return _make_stream(samples)

func _synth_shop_open() -> AudioStreamWAV:
	var dur := 0.4
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = (sin(PI * t / dur)) * 0.4
		var tone: float = sin(2.0 * PI * 330.0 * t) * 0.5 + sin(2.0 * PI * 440.0 * t) * 0.3
		samples[i] = tone * env
	return _make_stream(samples)

# --- EventBus listeners ---

func _on_weapon_fired(weapon: Node, _payload: Dictionary) -> void:
	if weapon == null or not ("data" in weapon) or weapon.data == null:
		return
	play_sfx(_weapon_fire_sfx_id(weapon.data.id))

func _weapon_fire_sfx_id(weapon_id: StringName) -> String:
	match weapon_id:
		&"pistol_m1": return "pistol_fire"
		&"shotgun_combat": return "shotgun_fire"
		&"ar_standard": return "ar_fire"
		_: return "pistol_fire"

func _on_weapon_reloaded(_weapon: Node) -> void:
	play_sfx("reload")

func _on_enemy_killed(enemy: Node, _src: Node, _hs: bool, _pos: Vector3) -> void:
	var pos := _pos
	if enemy is Node3D:
		pos = (enemy as Node3D).global_position
	play_sfx("zombie_death", pos)

func _on_barrier_damaged(_amount: float, attacker: Node) -> void:
	var pos := Vector3.ZERO
	if attacker is Node3D:
		pos = (attacker as Node3D).global_position
	play_sfx("barrier_hit", pos)

func _on_barrier_destroyed() -> void:
	play_sfx("barrier_destroyed")

func _on_wave_started(_round: int, _composition: Array) -> void:
	play_sfx("wave_start")

func _on_card_drafted(card) -> void:
	if card != null:
		play_sfx("card_pick")

func _on_shop_opened() -> void:
	play_sfx("shop_open")
