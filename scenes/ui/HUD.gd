extends CanvasLayer

@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPBar/HPLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var wave_label: Label = $WaveLabel
@onready var score_label: Label = $ScoreLabel
@onready var tokens_label: Label = $TokensLabel
@onready var click_hint: Label = $ClickHint

var _active_weapon: Node = null

func _process(_delta: float) -> void:
	click_hint.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	# Poll active weapon ammo for in-between-fire reload progress.
	if _active_weapon and _active_weapon.has_method("get_ammo_state"):
		_update_ammo_from_weapon(_active_weapon)

func _ready() -> void:
	EventBus.barrier_damaged.connect(_on_barrier_damaged)
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed)
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.weapon_reloaded.connect(_on_weapon_reloaded)
	EventBus.weapon_swapped.connect(_on_weapon_swapped)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.tokens_changed.connect(_on_tokens_changed)
	_update_hp(100.0, 100.0)
	ammo_label.text = "-- / --"
	weapon_label.text = ""
	wave_label.text = "WAVE 0"
	score_label.text = "0"
	tokens_label.text = "TOKENS: 0"

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
