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

var _active_weapon: Node = null
var _hit_marker_timer: float = 0.0
var _kill_streak: int = 0
var _vignette_phase: float = 0.0
var _damage_arrow_timer: float = 0.0

func _process(delta: float) -> void:
	click_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
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
	_update_hp(100.0, 100.0)
	ammo_label.text = "-- / --"
	weapon_label.text = ""
	wave_label.text = "WAVE 0"
	score_label.text = "0"
	tokens_label.text = "TOKENS: 0"
	_update_deck_display()

func _update_hp(current: float, max_val: float) -> void:
	hp_bar.max_value = max_val
	hp_bar.value = current
	hp_label.text = "BARRIER %d / %d" % [int(round(current)), int(round(max_val))]

func _update_ammo_from_weapon(weapon: Node) -> void:
	if weapon == null or not weapon.has_method("get_ammo_state"):
		ammo_label.text = "-- / --"
		weapon_label.text = ""
		return
	var s: Dictionary = weapon.get_ammo_state()
	if s.get("reloading", false):
		ammo_label.text = "RELOADING..."
	else:
		var reserve_text: String = "∞" if s.get("infinite_reserve", false) else str(int(s.get("reserve", 0)))
		ammo_label.text = "%d / %s" % [int(s.get("current", 0)), reserve_text]
	weapon_label.text = s.get("weapon_name", "")

func _on_barrier_damaged(_amount: float, attacker: Node) -> void:
	var barriers := get_tree().get_nodes_in_group("barriers")
	if barriers.size() > 0:
		var b = barriers[0]
		_update_hp(b.current_hp, b.max_hp)
	# Reset kill streak when the barrier takes any damage.
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
	match round_n:
		10:
			_show_boss_banner("⚠  MINI-BOSS: THE SUBJECT  ⚠")
		15:
			_show_boss_banner("⚠  THE SUBJECT RETURNS  ⚠")
		19:
			_show_boss_banner("⚠  TWO OF THEM  ⚠")
		20:
			_show_boss_banner("☢  FINAL BOSS: THE DIRECTOR  ☢")

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
	streak_label.text = "STREAK ×%d" % _kill_streak
	streak_label.visible = _kill_streak >= 3
	if _kill_streak == 5 or _kill_streak == 10 or _kill_streak == 25 or _kill_streak == 50 or _kill_streak == 100:
		_flash_streak_milestone()
	if headshot:
		_hit_pause()
	# Kill-flavored hit marker stacks on top of the damage-flavored one.
	_flash_hit_marker(headshot, true)

func _flash_streak_milestone() -> void:
	streak_label.modulate = Color(1.5, 1.2, 0.4, 1)
	var tw := create_tween()
	tw.tween_property(streak_label, "modulate", Color(1, 1, 1, 1), 0.6)

func _hit_pause() -> void:
	# Brief Engine.time_scale dip for "punch" on critical kills.
	# create_timer args: time, process_always, process_in_physics, ignore_time_scale
	Engine.time_scale = 0.08
	var t := get_tree().create_timer(0.055, true, false, true)
	t.timeout.connect(func(): Engine.time_scale = 1.0)

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
	var hp_ratio := 1.0
	if hp_bar.max_value > 0:
		hp_ratio = hp_bar.value / hp_bar.max_value
	var target := 0.0
	if hp_ratio < 0.3 and hp_bar.value > 0.0:
		_vignette_phase += delta * 4.5
		var pulse := 0.5 + 0.5 * sin(_vignette_phase)
		# Stronger as HP gets lower.
		var severity := clamp((0.3 - hp_ratio) / 0.3, 0.0, 1.0)
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
