extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPBar/HPLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var wave_label: Label = $WaveLabel
@onready var score_label: Label = $ScoreLabel
@onready var tokens_label: Label = $TokensLabel
@onready var deck_label: Label = $DeckLabel
@onready var click_hint: Label = $ClickHint
@onready var hit_marker: Label = $HitMarker
@onready var boss_banner: Label = $BossBanner
@onready var streak_label: Label = $StreakLabel
@onready var low_hp_vignette: TextureRect = $LowHpVignette
@onready var damage_arrow_anchor: Control = $DamageArrowAnchor
@onready var damage_arrow: Label = $DamageArrowAnchor/DamageArrow
@onready var wave_intro_banner: Label = $WaveIntroBanner
@onready var crosshair: Label = $Crosshair if has_node("Crosshair") else null
@onready var fps_label: Label = $FpsLabel if has_node("FpsLabel") else null

var _active_weapon: Node = null
var _hit_marker_timer: float = 0.0
var _kill_streak: int = 0
var _vignette_phase: float = 0.0
var _damage_arrow_timer: float = 0.0

func _process(delta: float) -> void:
	click_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	if crosshair:
		crosshair.visible = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if _active_weapon and _active_weapon.has_method("get_ammo_state"):
		_update_ammo_from_weapon(_active_weapon)
	if _hit_marker_timer > 0.0:
		_hit_marker_timer -= delta
		if _hit_marker_timer <= 0.0:
			hit_marker.visible = false
	_tick_low_hp_vignette(delta)
	if _damage_arrow_timer > 0.0:
		_damage_arrow_timer -= delta
		if _damage_arrow_timer <= 0.0:
			damage_arrow.modulate.a = 0.0
		else:
			damage_arrow.modulate.a = clamp(_damage_arrow_timer / 0.6, 0.0, 1.0)
	if fps_label and fps_label.visible:
		fps_label.text = "%d fps" % int(Engine.get_frames_per_second())

func _ready() -> void:
	EventBus.barrier_damaged.connect(_on_barrier_damaged)
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed)
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.weapon_reloaded.connect(_on_weapon_reloaded)
	EventBus.weapon_swapped.connect(_on_weapon_swapped)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.tokens_changed.connect(_on_tokens_changed)
	EventBus.card_drafted.connect(_on_card_drafted)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	hit_marker.visible = false
	boss_banner.visible = false
	streak_label.visible = false
	wave_intro_banner.visible = false
	_update_hp(100.0, 100.0)
	ammo_label.text = "-- / --"
	weapon_label.text = ""
	wave_label.text = "WAVE 0"
	score_label.text = "0"
	tokens_label.text = "TOKENS: 0"
	_update_deck_display()
	# Player+WeaponManager are higher in the scene tree, so they ready BEFORE HUD and
	# the initial weapon_swapped emit fires before this _ready connects. Poll once
	# so the ammo label shows real numbers instead of "-- / --" until first shot.
	call_deferred("_seed_active_weapon")
	_apply_crosshair_settings()
	_apply_fps_setting()
	EventBus.settings_changed.connect(_on_settings_changed)

func _on_settings_changed(key: String, _value) -> void:
	if key == "crosshair_size" or key == "crosshair_style" or key == "crosshair_color":
		_apply_crosshair_settings()
	elif key == "show_fps":
		_apply_fps_setting()

func _apply_crosshair_settings() -> void:
	if crosshair == null:
		return
	var style: String = String(MetaProgress.get_setting("crosshair_style", "cross"))
	var size: int = int(MetaProgress.get_setting("crosshair_size", 22))
	var hue: String = String(MetaProgress.get_setting("crosshair_color", "white"))
	match style:
		"dot":     crosshair.text = "·"
		"x":       crosshair.text = "×"
		"plus":    crosshair.text = "+"
		"cross":   crosshair.text = "+"
		_:         crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", size)
	var col: Color = Color(0.9, 0.95, 1, 0.85)
	match hue:
		"white":   col = Color(0.9, 0.95, 1, 0.85)
		"green":   col = Color(0.4, 1, 0.5, 0.85)
		"yellow":  col = Color(1, 0.95, 0.4, 0.85)
		"red":     col = Color(1, 0.4, 0.4, 0.85)
		"cyan":    col = Color(0.4, 0.95, 1, 0.85)
	crosshair.add_theme_color_override("font_color", col)

func _apply_fps_setting() -> void:
	if fps_label == null:
		return
	fps_label.visible = bool(MetaProgress.get_setting("show_fps", false))

func _seed_active_weapon() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var wm := scene.find_child("WeaponHolder", true, false)
	if wm != null and wm.has_method("get_active_weapon"):
		var w = wm.get_active_weapon()
		if w != null:
			_active_weapon = w
			_update_ammo_from_weapon(_active_weapon)

func _update_hp(current: float, max_val: float) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = current
	hp_label.text = "BARRIER %d / %d" % [int(round(current)), int(round(max_val))]

func _update_ammo_from_weapon(weapon: Node) -> void:
	if weapon == null or not weapon.has_method("get_ammo_state"):
		ammo_label.text = "-- / --"
		ammo_label.modulate = Color(1, 1, 1, 1)
		weapon_label.text = ""
		return
	var s: Dictionary = weapon.get_ammo_state()
	if s.get("reloading", false):
		ammo_label.text = "RELOADING..."
		ammo_label.modulate = Color(1, 1, 1, 1)
	else:
		var reserve_text: String = "∞" if s.get("infinite_reserve", false) else str(int(s.get("reserve", 0)))
		ammo_label.text = "%d / %s" % [int(s.get("current", 0)), reserve_text]
		# Low-ammo pulse: when current < 25% of mag, flash red.
		var current: int = int(s.get("current", 0))
		var mag: int = int(s.get("mag_size", 1))
		if mag > 0 and float(current) / float(mag) <= 0.25:
			# Sine-pulse the modulate; tied to engine time so it animates without _process.
			var t: float = float(Time.get_ticks_msec()) * 0.006
			var pulse: float = 0.5 + 0.5 * sin(t)
			ammo_label.modulate = Color(1.0, lerp(0.45, 1.0, 1.0 - pulse), lerp(0.45, 1.0, 1.0 - pulse), 1.0)
		else:
			ammo_label.modulate = Color(1, 1, 1, 1)
	weapon_label.text = s.get("weapon_name", "")

func _on_barrier_damaged(_amount: float, attacker: Node) -> void:
	var barriers := get_tree().get_nodes_in_group("barriers")
	if barriers.size() > 0:
		var b = barriers[0]
		_update_hp(b.current_hp, b.max_hp)
	# Reset kill streak when the barrier takes any damage.
	if _kill_streak >= 3:
		# Audible streak-break feedback. Only fires if we lost an actual streak.
		AudioMan.play_sfx("streak_break")
	_kill_streak = 0
	streak_label.visible = false
	_show_damage_arrow_toward(attacker)

func _on_barrier_destroyed() -> void:
	_update_hp(0.0, 100.0)

func _on_weapon_fired(weapon: Node, _payload: Dictionary) -> void:
	_active_weapon = weapon
	_update_ammo_from_weapon(weapon)

func _on_weapon_reloaded(weapon: Node) -> void:
	_active_weapon = weapon
	_update_ammo_from_weapon(weapon)

func _on_weapon_swapped(_old: Node, new_weapon: Node) -> void:
	_active_weapon = new_weapon
	_update_ammo_from_weapon(new_weapon)

func _on_wave_started(round_n: int, _composition: Array) -> void:
	wave_label.text = "WAVE %d" % round_n
	_show_wave_intro(round_n)
	match round_n:
		10:
			_show_boss_banner("⚠  MINI-BOSS: THE SUBJECT  ⚠")
		15:
			_show_boss_banner("⚠  THE SUBJECT RETURNS  ⚠")
		19:
			_show_boss_banner("⚠  TWO OF THEM  ⚠")
		20:
			_show_boss_banner("☢  FINAL BOSS: THE DIRECTOR  ☢")

func _show_wave_intro(round_n: int) -> void:
	# Pulls the live wave data from SpawnRing so we can list per-type counts.
	var spawn_ring := get_tree().current_scene.find_child("SpawnRing", true, false)
	if spawn_ring == null or not spawn_ring.has_method("get_current_wave"):
		return
	var wd = spawn_ring.get_current_wave()
	if wd == null or wd.composition.is_empty():
		return
	var parts: Array[String] = []
	for i in wd.composition.size():
		var enemy = wd.composition[i]
		var count: int = int(wd.counts[i]) if i < wd.counts.size() else 0
		if count <= 0 or enemy == null:
			continue
		parts.append("%d %s" % [count, enemy.display_name])
	if parts.is_empty():
		return
	# Line 1: wave composition. Line 2: deck reminder so the player remembers their build.
	var lines: Array[String] = []
	lines.append("WAVE %d  —  %s" % [round_n, "  ·  ".join(parts)])
	if not CardSystem.active_deck.is_empty():
		var deck_names: Array[String] = []
		for c in CardSystem.active_deck:
			deck_names.append(c.display_name)
		lines.append("Deck: " + "  ·  ".join(deck_names))
	wave_intro_banner.text = "\n".join(lines)
	wave_intro_banner.visible = true
	wave_intro_banner.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(wave_intro_banner, "modulate:a", 0.0, 1.0)
	tw.tween_callback(func(): wave_intro_banner.visible = false)

func _show_boss_banner(text: String) -> void:
	boss_banner.text = text
	boss_banner.visible = true
	boss_banner.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(boss_banner, "modulate:a", 0.0, 1.5)
	tw.tween_callback(func(): boss_banner.visible = false)

func _on_enemy_killed(_enemy: Node, _src: Node, headshot: bool, _pos: Vector3) -> void:
	GameState.current_score += 1
	score_label.text = "%d" % GameState.current_score
	MetaProgress.lifetime_kills += 1
	_kill_streak += 1
	_update_streak_label()
	if _kill_streak == 3 or _kill_streak == 5 or _kill_streak == 10 or _kill_streak == 20:
		_pop_streak_tier()
	# Kill-flavored hit marker stacks on top of the damage-flavored one.
	# Headshot hit-pause is owned by the HitPause node (Player.tscn child) — single owner of time_scale.
	_flash_hit_marker(headshot, true)

func _streak_tier(streak: int) -> Dictionary:
	if streak >= 20:
		return {"label": "ECHO LEGEND", "color": Color(1.0, 0.4, 1.0), "size": 44}
	if streak >= 10:
		return {"label": "UNSTOPPABLE", "color": Color(1.0, 0.55, 0.25), "size": 38}
	if streak >= 5:
		return {"label": "RAMPAGE", "color": Color(1.0, 0.75, 0.3), "size": 32}
	if streak >= 3:
		return {"label": "STREAK", "color": Color(1.0, 0.9, 0.5), "size": 26}
	return {}

func _update_streak_label() -> void:
	var tier := _streak_tier(_kill_streak)
	if tier.is_empty():
		streak_label.visible = false
		return
	streak_label.visible = true
	streak_label.text = "%s ×%d" % [tier["label"], _kill_streak]
	streak_label.add_theme_color_override("font_color", tier["color"])
	streak_label.add_theme_font_size_override("font_size", int(tier["size"]))

func _pop_streak_tier() -> void:
	streak_label.pivot_offset = streak_label.size * 0.5
	streak_label.scale = Vector2(1.6, 1.6)
	streak_label.modulate = Color(1.8, 1.5, 0.6, 1)
	var tw := create_tween()
	tw.tween_property(streak_label, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(streak_label, "modulate", Color(1, 1, 1, 1), 0.45)

func _on_tokens_changed(new_total: int, _delta: int) -> void:
	tokens_label.text = "TOKENS: %d" % new_total

func _on_card_drafted(_card) -> void:
	_update_deck_display()

func _update_deck_display() -> void:
	if deck_label == null:
		return
	var deck = CardSystem.active_deck
	if deck.is_empty():
		deck_label.text = "DECK: (empty)"
		return
	var names: Array[String] = []
	for c in deck:
		names.append(c.display_name)
	deck_label.text = "DECK: " + " · ".join(names)

func _on_enemy_damaged(_enemy, amount: float, _src, hit_position: Vector3, is_headshot: bool) -> void:
	_flash_hit_marker(is_headshot, false)
	_spawn_damage_number(amount, hit_position, is_headshot)

func _spawn_damage_number(amount: float, world_pos: Vector3, headshot: bool) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	if cam.is_position_behind(world_pos):
		return
	var screen_pos := cam.unproject_position(world_pos)
	var label := Label.new()
	label.text = str(int(round(amount)))
	label.position = screen_pos + Vector2(randf_range(-12, 12), -16)
	label.add_theme_font_size_override("font_size", 26 if headshot else 18)
	label.add_theme_color_override("font_color", Color(1, 0.6, 0.2) if headshot else Color(1, 1, 1))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tw := create_tween()
	tw.tween_property(label, "position:y", label.position.y - 50.0, 0.8)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tw.tween_callback(label.queue_free)

func _flash_hit_marker(headshot: bool, killed: bool) -> void:
	hit_marker.visible = true
	_hit_marker_timer = 0.18 if killed else 0.1
	var col := Color(1, 1, 1, 1)
	var scl := 1.0
	if killed:
		col = Color(1.0, 0.85, 0.2, 1) if headshot else Color(1.0, 0.25, 0.25, 1)
		scl = 1.6 if headshot else 1.35
	hit_marker.add_theme_color_override("font_color", col)
	hit_marker.pivot_offset = hit_marker.size * 0.5
	hit_marker.scale = Vector2.ONE * scl
	var tw := create_tween()
	tw.tween_property(hit_marker, "scale", Vector2.ONE, 0.18)

func _tick_low_hp_vignette(delta: float) -> void:
	var hp_ratio: float = 1.0
	if hp_bar.max_value > 0:
		hp_ratio = hp_bar.value / hp_bar.max_value
	var target: float = 0.0
	if hp_ratio < 0.3 and hp_bar.value > 0.0:
		_vignette_phase += delta * 4.5
		var pulse: float = 0.5 + 0.5 * sin(_vignette_phase)
		var severity: float = clamp((0.3 - hp_ratio) / 0.3, 0.0, 1.0)
		target = lerp(0.35, 0.85, severity) * lerp(0.65, 1.0, pulse)
	else:
		_vignette_phase = 0.0
	low_hp_vignette.modulate.a = lerp(low_hp_vignette.modulate.a, target, clamp(delta * 6.0, 0.0, 1.0))

func _show_damage_arrow_toward(attacker: Node) -> void:
	if attacker == null or not (attacker is Node3D):
		return
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var att_pos: Vector3 = (attacker as Node3D).global_position
	var cam_pos: Vector3 = cam.global_position
	# Direction in world XZ plane from camera to attacker.
	var to_att := Vector2(att_pos.x - cam_pos.x, att_pos.z - cam_pos.z)
	if to_att.length() < 0.01:
		return
	# Camera forward on XZ.
	var fwd3 := -cam.global_transform.basis.z
	var fwd := Vector2(fwd3.x, fwd3.z)
	if fwd.length() < 0.01:
		return
	# Signed angle from forward to attacker direction.
	var ang := fwd.angle_to(to_att)
	# Anchor child arrow at top — rotating the anchor swings the arrow around screen center.
	damage_arrow_anchor.rotation = ang
	damage_arrow.modulate.a = 1.0
	_damage_arrow_timer = 0.6
