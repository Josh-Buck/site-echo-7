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

var _active_weapon: Node = null
var _hit_marker_timer: float = 0.0

func _process(delta: float) -> void:
	click_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	if _active_weapon and _active_weapon.has_method("get_ammo_state"):
		_update_ammo_from_weapon(_active_weapon)
	if _hit_marker_timer > 0.0:
		_hit_marker_timer -= delta
		if _hit_marker_timer <= 0.0:
			hit_marker.visible = false

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
		ammo_label.text = "%d / %d" % [int(s.get("current", 0)), int(s.get("reserve", 0))]
	weapon_label.text = s.get("weapon_name", "")

func _on_barrier_damaged(_amount: float, _attacker: Node) -> void:
	var barriers := get_tree().get_nodes_in_group("barriers")
	if barriers.size() > 0:
		var b = barriers[0]
		_update_hp(b.current_hp, b.max_hp)

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

func _on_enemy_killed(_enemy: Node, _src: Node, _headshot: bool, _pos: Vector3) -> void:
	GameState.current_score += 1
	score_label.text = "%d" % GameState.current_score
	MetaProgress.lifetime_kills += 1

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
	hit_marker.visible = true
	_hit_marker_timer = 0.12
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
