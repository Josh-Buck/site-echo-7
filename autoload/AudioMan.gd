extends Node

# AUDIO — RESTART (v0.9). Previous iterations layered procedural synths, real
# OGGs, positional 3D, EventBus listeners on every fire/kill/hit/spawn/wave —
# user reported "constant gunshots when not shooting" across 4+ attempts to
# trim it. This version starts from zero.
#
# Design:
#  - Tiny 2D-only pool (6 players). No 3D positional audio at all.
#  - Procedural synths are SOFT, SHORT, PURE SINE. No noise components,
#    no rasp, no crack. If something needs to feel percussive it gets a
#    short envelope, not a noise burst.
#  - No EventBus listeners. Callers explicitly request sounds. No more
#    "X happens, listener fires SFX." Every play() is initiated by code
#    that has a SPECIFIC reason to make a sound right then.
#  - Player weapon fire and reload play through here.
#  - UI hover/click/confirm play through here.
#  - That's it. Nothing else makes sound.

const SAMPLE_RATE: int = 22050
const POOL_SIZE: int = 6
const UI_CLICK_PATH := "res://audio/sfx/ui/click.ogg"
const UI_HOVER_PATH := "res://audio/sfx/ui/hover.ogg"
const UI_CONFIRM_PATH := "res://audio/sfx/ui/confirm.ogg"
const CARD_FLIP_PATH := "res://audio/sfx/ui/card_flip.ogg"
const DRAFT_APPEAR_PATH := "res://audio/sfx/ui/draft_appear.ogg"

var _gesture_received: bool = false
var _pool: Array[AudioStreamPlayer] = []
var _idx: int = 0
var _cache: Dictionary = {}        # id -> AudioStreamWAV
var _stream_cache: Dictionary = {} # path -> AudioStream

func _ready() -> void:
	print("[AudioMan] ready (restart v0.9)")
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bus_name: StringName = &"SFX" if AudioServer.get_bus_index("SFX") >= 0 else &"Master"
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = bus_name
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_pool.append(p)
	call_deferred("_apply_volumes_from_settings")

# --- public API: gesture gate -------------------------------------------------

func register_first_gesture() -> void:
	if _gesture_received:
		return
	_gesture_received = true
	print("[AudioMan] first user gesture registered, audio enabled")
	start_music()

func can_play() -> bool:
	return _gesture_received

# --- ambient music bed ----------------------------------------------------------
# A dark pure-sine chord pad, ~18s seamless loop, built procedurally so it ships
# no audio file. No rhythm, no noise, no transients — it cannot read as gunfire.
# Routes through the Music bus so the existing Music slider controls it.
# Built async in small chunks so the one-time generation never hitches a frame.

const MUSIC_RATE: int = 11025  # pads have no high-frequency content; half rate halves cost
var _music_player: AudioStreamPlayer = null
var _music_building: bool = false

func start_music() -> void:
	if _music_building or (_music_player != null and _music_player.playing):
		return
	_music_building = true
	_build_and_play_music()

func _build_and_play_music() -> void:
	# Four dark chords. Each occupies an overlapping window with a sin^2 envelope
	# that is zero at its window edges, so the crossfading sum is continuous.
	# Every frequency is quantized to a whole number of cycles over the loop
	# length, which makes the loop point mathematically seamless.
	var chords := [
		[110.0, 164.81, 220.0],    # A2 E3 A3 — home
		[87.31, 130.81, 174.61],   # F2 C3 F3 — sink
		[98.0, 146.83, 196.0],     # G2 D3 G3 — lift
		[82.41, 123.47, 164.81],   # E2 B2 E3 — tension
	]
	var seg := 4.5
	var total: float = seg * chords.size()
	# Quantize frequencies: integer cycle counts over `total` seconds.
	var q_chords: Array = []
	for c in chords:
		var qc: Array = []
		for f in c:
			qc.append(round(f * total) / total)
		# Detuned shadow of the root for slow shimmer.
		qc.append(round((c[0] + 0.7) * total) / total)
		q_chords.append(qc)
	var n := int(total * MUSIC_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	var chunk := 8192
	var i := 0
	while i < n:
		var end: int = mini(i + chunk, n)
		for s in range(i, end):
			var t: float = float(s) / MUSIC_RATE
			var v: float = 0.0
			for c in q_chords.size():
				var u: float = fposmod(t - float(c) * seg, total)
				if u < 2.0 * seg:
					var env: float = sin(PI * u / (2.0 * seg))
					var amp: float = env * env * 0.10
					var freqs: Array = q_chords[c]
					v += sin(TAU * freqs[0] * t) * amp
					v += sin(TAU * freqs[1] * t) * amp * 0.8
					v += sin(TAU * freqs[2] * t) * amp * 0.6
					v += sin(TAU * freqs[3] * t) * amp * 0.5
			samples[s] = v
		i = end
		if not is_inside_tree():
			_music_building = false
			return
		await get_tree().process_frame
	var stream := _make_stream_rate(samples, MUSIC_RATE)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = n
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music" if AudioServer.get_bus_index("Music") >= 0 else &"Master"
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_music_player.stream = stream
	_music_player.volume_db = -14.0
	add_child(_music_player)
	_music_player.play()
	_music_building = false
	print("[AudioMan] ambient music bed started (%.0fs loop)" % total)

# --- public API: volumes ------------------------------------------------------

func _apply_volumes_from_settings() -> void:
	set_master_volume(float(MetaProgress.get_setting("master_volume", 1.0)))
	set_bus_linear("SFX", float(MetaProgress.get_setting("sfx_volume", 1.0)))
	set_bus_linear("Music", float(MetaProgress.get_setting("music_volume", 1.0)))

func set_master_volume(linear: float) -> void:
	set_bus_linear("Master", linear)

func set_bus_linear(bus_name: String, linear: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	linear = clamp(linear, 0.0, 1.0)
	if linear <= 0.0001:
		AudioServer.set_bus_mute(bus, true)
		return
	AudioServer.set_bus_mute(bus, false)
	AudioServer.set_bus_volume_db(bus, linear_to_db(linear))

# --- public API: play ---------------------------------------------------------

# 2D one-shot. Used for everything: fire, reload, UI, run-end. No positional 3D.
func play_2d(stream: AudioStream, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	if stream == null or not _gesture_received:
		return
	var p := _pool[_idx]
	_idx = (_idx + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 if pitch_jitter <= 0.0 else 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.play()

# Compatibility shim — call sites previously used play_3d_at for fire/hit
# positional sounds. We route to 2D now. The "pos" arg is ignored.
func play_3d_at(stream: AudioStream, _pos: Vector3, volume_db: float = 0.0, _max_distance: float = 30.0, pitch_jitter: float = 0.0) -> void:
	play_2d(stream, volume_db, pitch_jitter)

# Lookup table for synth one-shots. Caller passes an id and we play the
# pre-generated WAV. Unknown ids no-op.
func play_sfx(id: String, _pos = null) -> void:
	if not _gesture_received:
		return
	var stream := _get_sfx(id)
	if stream != null:
		play_2d(stream, -3.0)

func _get_sfx(id: String) -> AudioStreamWAV:
	if not _cache.has(id):
		var s := _synth(id)
		if s != null:
			_cache[id] = s
	return _cache.get(id)

# --- UI helpers ---------------------------------------------------------------

func play_ui_click() -> void:
	_play_ui("click")

func play_ui_hover() -> void:
	_play_ui("hover")

func play_ui_confirm() -> void:
	_play_ui("confirm")

func play_card_flip() -> void:
	_play_ui("card_flip")

func play_draft_appear() -> void:
	_play_ui("draft_appear")

const _UI_PATHS := {
	"click":         UI_CLICK_PATH,
	"hover":         UI_HOVER_PATH,
	"confirm":       UI_CONFIRM_PATH,
	"card_flip":     CARD_FLIP_PATH,
	"draft_appear":  DRAFT_APPEAR_PATH,
}

func _play_ui(name: String) -> void:
	var path: Variant = _UI_PATHS.get(name)
	if path == null:
		return
	var stream: AudioStream = _load_stream(String(path))
	if stream != null:
		play_2d(stream, -6.0, 0.04)

func _load_stream(path: String) -> AudioStream:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not ResourceLoader.exists(path):
		return null
	var s: AudioStream = load(path)
	_stream_cache[path] = s
	return s

# --- synthesis: ONE pop for fire, ONE click for reload, ONE thud for end ----
#
# These are the only sounds the game procedurally generates. All pure-sine
# with simple envelopes. No noise components. If you can hear a "shot"
# when the player hasn't fired, it's coming from somewhere OTHER than this
# file — none of these sounds layer or loop.

func _synth(id: String) -> AudioStreamWAV:
	match id:
		"pistol_fire":       return _synth_fire(0.10, 180.0)
		"ar_fire":           return _synth_fire(0.08, 240.0)
		"shotgun_fire":      return _synth_fire(0.18, 90.0)
		"smg_fire":          return _synth_fire(0.07, 260.0)
		"bolt_fire":         return _synth_fire(0.22, 110.0)
		"sidearm_fire":      return _synth_fire(0.10, 200.0)
		"reload":            return _synth_click(0.12)
		"barrier_destroyed": return _synth_thud(0.6)
		"streak_break":      return _synth_streak_break()
	return null

func _synth_streak_break() -> AudioStreamWAV:
	# Two quick descending sine notes — "streak lost" cue. Pure sine, no noise.
	var dur := 0.18
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var f: float = 440.0 if t < dur * 0.45 else 370.0
		var env: float = exp(-t * 6.0) * 0.35
		samples[i] = sin(2.0 * PI * f * t) * env
	return _make_stream(samples)

func _synth_fire(dur: float, freq: float) -> AudioStreamWAV:
	# Pure-sine pop. Sharp exponential attack + decay. NO noise component.
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 28.0) * 0.42
		samples[i] = sin(2.0 * PI * freq * t) * env
	return _make_stream(samples)

func _synth_click(dur: float) -> AudioStreamWAV:
	# Short upward-sweep click for reload. Pure sine.
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 50.0) * 0.35
		var f: float = lerp(900.0, 600.0, t / dur)
		samples[i] = sin(2.0 * PI * f * t) * env
	return _make_stream(samples)

func _synth_thud(dur: float) -> AudioStreamWAV:
	# Low decaying thud for barrier-destroyed run-end. Pure sine at ~60 Hz.
	var n := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t: float = float(i) / SAMPLE_RATE
		var env: float = exp(-t * 4.0) * 0.55
		samples[i] = sin(2.0 * PI * 60.0 * t) * env
	return _make_stream(samples)

func _make_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	return _make_stream_rate(samples, SAMPLE_RATE)

func _make_stream_rate(samples: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var s: float = clamp(samples[i], -1.0, 1.0)
		bytes.encode_s16(i * 2, int(s * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	return stream

# --- explicit play helpers used by gameplay ---------------------------------

# Weapon.gd calls this with the weapon's data.id. We map id -> synth -> play.
func play_weapon_fire(weapon_id: StringName) -> void:
	if not _gesture_received:
		return
	var sfx_id := "pistol_fire"
	match weapon_id:
		&"pistol_m1":      sfx_id = "pistol_fire"
		&"ar_standard":    sfx_id = "ar_fire"
		&"shotgun_combat": sfx_id = "shotgun_fire"
		&"smg_compact":    sfx_id = "smg_fire"
		&"bolt_action":    sfx_id = "bolt_fire"
		&"sidearm_backup": sfx_id = "sidearm_fire"
	play_sfx(sfx_id)

func play_weapon_reload() -> void:
	play_sfx("reload")

func play_barrier_destroyed() -> void:
	play_sfx("barrier_destroyed")
