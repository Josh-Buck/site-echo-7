extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var tokens_label: Label = $Panel/VBox/TokensLabel
@onready var offer_row: HBoxContainer = $Panel/VBox/OfferRow
@onready var continue_button: Button = $Panel/VBox/ContinueButton

const OFFER_POOL: Array[Dictionary] = [
	{"id": "ammo_topup", "name": "Ammo Top-Up", "desc": "Refill active weapon's reserve ammo.", "cost": 30},
	{"id": "barrier_repair", "name": "Barrier Repair", "desc": "Restore +30 barrier HP.", "cost": 50},
	{"id": "all_ammo", "name": "Full Resupply", "desc": "Refill ALL weapons' reserves.", "cost": 75},
	{"id": "barrier_full", "name": "Field Welder", "desc": "Repair barrier to full HP.", "cost": 150},
	{"id": "mag_refill", "name": "Speed Loader", "desc": "Instantly refill the active mag.", "cost": 20},
	# New emplacement / utility offers — deliberately weak alternatives to ammo.
	{"id": "turret_place", "name": "Auto-Turret", "desc": "Deploy a slow auto-turret (8 dmg / 1.6s, 14m range). Stacks up to 4.", "cost": 90},
	{"id": "barrier_regen", "name": "Field Regenerator", "desc": "Barrier slowly auto-heals +1 HP/s for this wave only.", "cost": 40},
	{"id": "max_hp_boost", "name": "Reinforced Plating", "desc": "+15 barrier max HP for the rest of the run (and heals 15).", "cost": 60},
	{"id": "slow_field", "name": "Chill Emitter", "desc": "Zombies move 20% slower for the next wave.", "cost": 45},
]

var _current_offers: Array[Dictionary] = []
# Latched by wave_ended. Quartermaster perk fires card_drafted at run start
# (before wave 1), and we don't want the shop to pop up then.
var _allow_open: bool = false

func _ready() -> void:
	panel.visible = false
	EventBus.card_drafted.connect(_on_card_drafted)
	EventBus.tokens_changed.connect(_on_tokens_changed)
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.run_started.connect(_on_run_started)
	continue_button.pressed.connect(_on_continue_pressed)
	continue_button.mouse_entered.connect(AudioMan.play_ui_hover)

func _on_run_started() -> void:
	_allow_open = false

func _on_wave_ended(_round_n: int) -> void:
	_allow_open = true

func _on_card_drafted(_card) -> void:
	if not _allow_open:
		return
	# One-shot per wave so a mid-run perk draft (e.g. future card pool refresh) can't
	# re-trigger the shop.
	_allow_open = false
	_generate_offers()
	_populate()
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	_update_tokens()
	EventBus.shop_opened.emit()

func _generate_offers() -> void:
	_current_offers.clear()
	var pool := OFFER_POOL.duplicate()
	# Hide turret offer once at cap (4 turrets) — no dead choices.
	if GameState.turret_count >= TURRET_ANCHORS.size():
		pool = pool.filter(func(o): return o["id"] != "turret_place")
	pool.shuffle()
	for i in min(3, pool.size()):
		_current_offers.append(pool[i])

func _populate() -> void:
	for c in offer_row.get_children():
		c.queue_free()
	for i in _current_offers.size():
		var btn := _make_offer_button(_current_offers[i], i)
		offer_row.add_child(btn)

func _make_offer_button(offer: Dictionary, idx: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(280, 240)
	btn.text = "%s\n\n%s\n\n%d TOKENS" % [offer["name"], offer["desc"], int(offer["cost"])]
	btn.clip_text = false
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	btn.add_theme_font_size_override("font_size", 20)
	btn.disabled = GameState.tokens < int(offer["cost"])
	btn.pressed.connect(_on_buy.bind(idx))
	btn.mouse_entered.connect(AudioMan.play_ui_hover)
	return btn

func _on_buy(idx: int) -> void:
	if idx < 0 or idx >= _current_offers.size():
		return
	var offer = _current_offers[idx]
	var cost: int = int(offer["cost"])
	if GameState.tokens < cost:
		return
	AudioMan.play_ui_confirm()
	GameState.tokens -= cost
	EventBus.tokens_changed.emit(GameState.tokens, -cost)
	_apply_effect(String(offer["id"]))
	_current_offers.remove_at(idx)
	_populate()

func _apply_effect(effect_id: String) -> void:
	# Don't emit weapon_reloaded here — it would play the reload SFX on top of
	# the shop's confirm sound, reading as a phantom reload click. HUD polls
	# the active weapon's ammo state every frame so display still updates.
	match effect_id:
		"ammo_topup":
			var w := _get_active_weapon()
			if w != null:
				w.reserve_ammo = w.get_effective_reserve_max()
		"all_ammo":
			var wm := _get_weapon_manager()
			if wm != null:
				for child in wm.get_children():
					if child is Weapon:
						var weapon: Weapon = child
						weapon.reserve_ammo = weapon.get_effective_reserve_max()
		"mag_refill":
			var w := _get_active_weapon()
			if w != null:
				var mag: int = w.get_effective_mag_size()
				var needed: int = mag - w.current_ammo
				if needed > 0:
					var taken: int = min(needed, w.reserve_ammo)
					w.current_ammo += taken
					w.reserve_ammo -= taken
		"barrier_repair":
			var barriers := get_tree().get_nodes_in_group("barriers")
			if barriers.size() > 0:
				var b: Node = barriers[0]
				if b.has_method("repair"):
					b.repair(30.0)
		"barrier_full":
			var barriers := get_tree().get_nodes_in_group("barriers")
			if barriers.size() > 0:
				var b: Node = barriers[0]
				if "max_hp" in b and b.has_method("repair"):
					b.repair(b.max_hp)
		"turret_place":
			_place_turret()
		"barrier_regen":
			var barriers := get_tree().get_nodes_in_group("barriers")
			if barriers.size() > 0 and barriers[0].has_method("enable_regen_next_wave"):
				barriers[0].enable_regen_next_wave(1.0)
		"max_hp_boost":
			var barriers := get_tree().get_nodes_in_group("barriers")
			if barriers.size() > 0 and barriers[0].has_method("bump_max_hp"):
				barriers[0].bump_max_hp(15.0)
		"slow_field":
			GameState.zombie_speed_mult_next_wave = 0.8

const TURRET_SCENE := preload("res://scenes/turret/Turret.tscn")
const TURRET_ANCHORS := [
	Vector3(3.5, 0.0, 3.5),
	Vector3(-3.5, 0.0, 3.5),
	Vector3(-3.5, 0.0, -3.5),
	Vector3(3.5, 0.0, -3.5),
]

func _place_turret() -> void:
	var slot := GameState.turret_count
	if slot >= TURRET_ANCHORS.size():
		return  # cap at 4
	GameState.turret_count += 1
	var t := TURRET_SCENE.instantiate()
	get_tree().current_scene.add_child(t)
	(t as Node3D).global_position = TURRET_ANCHORS[slot]

func _get_weapon_manager() -> WeaponManager:
	var n := get_tree().current_scene.find_child("WeaponHolder", true, false)
	if n is WeaponManager:
		return n as WeaponManager
	return null

func _get_active_weapon() -> Weapon:
	var wm := _get_weapon_manager()
	if wm == null:
		return null
	return wm.get_active_weapon()

func _update_tokens() -> void:
	tokens_label.text = "Tokens Available: %d" % GameState.tokens

func _on_tokens_changed(_total: int, _delta: int) -> void:
	if not panel.visible:
		return
	_update_tokens()
	_populate()

func _on_continue_pressed() -> void:
	AudioMan.play_ui_click()
	panel.visible = false
	# Stay paused — WaveComplete is the next overlay and will re-affirm pause.
	EventBus.shop_done.emit()
