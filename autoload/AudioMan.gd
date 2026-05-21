extends Node

# Procedural audio: SFX synthesized at runtime as AudioStreamWAV via simple DSP.
# All sounds cache after first generation. Pure GDScript — no external assets.

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 16

# Pre-loaded streams for the curated SFX set.
const UI_CLICK_PATH := "res://audio/sfx/ui/click.ogg"
const UI_HOVER_PATH := "res://audio/sfx/ui/hover.ogg"
const UI_CONFIRM_PATH := "res://audio/sfx/ui/confirm.ogg"
const CARD_FLIP_PATH := "res://audio/sfx/ui/card_flip.ogg"
const DRAFT_APPEAR_PATH := "res://audio/sfx/ui/draft_appear.ogg"

var _gesture_received: bool = false
var _ui_sfx_paths: Dictionary = {
	"click": UI_CLICK_PATH,
	"hover": UI_HOVER_PATH,
	"confirm": UI_CONFIRM_PATH,
	"card_flip": CARD_FLIP_PATH,
	"draft_appear": DRAFT_APPEAR_PATH
}
var _cache: Dictionary = {}  # String id -> AudioStreamWAV
var _2d_pool: Array[AudioStreamPlayer] = []
var _3d_pool: Array[AudioStreamPlayer3D] = []
var _2d_idx: int = 0
var _3d_idx: int = 0
var _stream_cache: Dictionary = {}  # path -> AudioStream

func _ready() -> void:
	print("[AudioMan] ready")
	# Keep playing audio through pause-tree (so UI sounds work in pause menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_pools()
	# Apply master volume from saved settings (after MetaProgress loads in its _ready).
	call_deferred("_apply_master_volume")
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.weapon_reloaded.connect(_on_weapon_reloaded)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.barrier_damaged.connect(_on_barrier_damaged)
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.card_drafted.connect(_on_card_drafted)
	EventBus.shop_opened.connect(_on_shop_opened)

func _build_pools() -> void:
	# Route to SFX bus (Settings slider controls it). Falls back to Master if
	# the project's bus layout doesn't have SFX (older saves / external imports).
	var bus_name: StringName = &"SFX" if AudioServer.get_bus_index("SFX") >= 0 else &"Master"
	for i in POOL_SIZE:
		var p2d := AudioStreamPlayer.new()
		p2d.bus = bus_name
		p2d.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p2d)
		_2d_pool.append(p2d)
		var p3d := AudioStreamPlayer3D.new()
		p3d.bus = bus_name
		p3d.max_distance = 40.0
		p3d.unit_size = 5.0
		p3d.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p3d)
		_3d_pool.append(p3d)

func register_first_gesture() -> void:
	if _gesture_received:
		return
	_gesture_received = true
	print("[AudioMan] first user gesture registered, audio enabled")

func _apply_master_volume() -> void:
	var vol: float = float(MetaProgress.get_setting("master_volume", 1.0))
	set_master_volume(vol)

func set_master_volume(linear: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	linear = clamp(linear, 0.0, 1.0)
	if linear <= 0.0001:
		AudioServer.set_bus_mute(bus, true)
		return
	AudioServer.set_bus_mute(bus, false)
	AudioServer.set_bus_volume_db(bus, linear_to_db(linear))

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

# --- General-purpose stream players (for loaded .ogg assets) ---

func play_2d(stream: AudioStream, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	if stream == null or not _gesture_received:
		return
	var p := _2d_pool[_2d_idx]
	_2d_idx = (_2d_idx + 1) % _2d_pool.size()
	p.stream = stream
	p.volume_db = volume_db
	if pitch_jitter > 0.0:
		p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	else:
		p.pitch_scale = 1.0
	p.play()

func play_3d_at(stream: AudioStream, pos: Vector3, volume_db: float = 0.0, max_distance: float = 30.0, pitch_jitter: float = 0.0) -> void:
	if stream == null or not _gesture_received:
		return
	var p := _3d_pool[_3d_idx]
	_3d_idx = (_3d_idx + 1) % _3d_pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.max_distance = max_distance
	if pitch_jitter > 0.0:
		p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	else:
		p.pitch_scale = 1.0
	p.global_position = pos
	p.play()

func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path)
	_stream_cache[path] = s
	return s

# --- UI helper hooks (exposed; UI layer calls these) ---

func _play_ui_sfx(id: String) -> void:
	var path := _ui_sfx_paths.get(id)
	if path == null:
		push_warning("[AudioMan] unknown UI sfx id: %s" % id)
		return
	play_2d(_load_stream(path), -4.0, 0.04)

func play_ui_click() -> void:
	_play_ui_sfx("click")

func play_ui_hover() -> void:
	_play_ui_sfx("hover")

func play_ui_confirm() -> void:
	_play_ui_sfx("confirm")

func play_card_flip() -> void:
	_play_ui_sfx("card_flip")

func play_draft_appear() -> void:
	_play_ui_sfx("draft_appear")

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
	# Weapon plays its own positional fire SFX when a real sample is assigned.
	if weapon.data.fire_sfx != null:
		return
	play_sfx(_weapon_fire_sfx_id(weapon.data.id))

func _weapon_fire_sfx_id(weapon_id: StringName) -> String:
	match weapon_id:
		&"pistol_m1": return "pistol_fire"
		&"shotgun_combat": return "shotgun_fire"
		&"ar_standard": return "ar_fire"
		_: return "pistol_fire"

func _on_weapon_reloaded(weapon: Node) -> void:
	# Reload SFX now plays at reload-start from the weapon itself when a real sample is
	# assigned. This synth fallback only fires for weapons without one.
	if weapon != null and ("data" in weapon) and weapon.data != null and weapon.data.reload_sfx != null:
		return
	play_sfx("reload")

func _on_enemy_killed(enemy: Node, _src: Node, _hs: bool, _pos: Vector3) -> void:
	var pos := _pos
	if enemy is Node3D:
		pos = (enemy as Node3D).global_position
	play_sfx("zombie_death", pos)

func _on_barrier_damaged(_amount: float, _attacker: Node) -> void:
	# Barrier.gd plays the curated impact streams itself with damage-tier routing.
	pass

func _on_barrier_destroyed() -> void:
	play_sfx("barrier_destroyed")

func _on_wave_started(_round: int, _composition: Array) -> void:
	play_sfx("wave_start")

func _on_card_drafted(card) -> void:
	if card != null:
		play_sfx("card_pick")

func _on_shop_opened() -> void:
	play_sfx("shop_open")
