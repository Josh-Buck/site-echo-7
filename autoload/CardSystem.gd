extends Node

# Active deck + draft pool + payload mutation.
# M2b: hardcoded starter pool. M3 ties to MetaProgress unlocks.

var active_deck: Array[CardData] = []
var available_pool: Array[CardData] = []
var current_offer: Array[CardData] = []

signal cards_offered_local(cards: Array)
signal card_added_local(card: CardData)

# Tag map keyed by card id. Determines synergy eligibility. Adding a tag here is
# cheaper than editing 30 .tres files and keeps the synergy taxonomy in one place.
const CARD_TAGS := {
	# fire / damage cluster
	&"damage_1":           ["fire"],
	&"hot_loads":          ["fire"],
	&"magnum_frame":       ["fire"],
	&"bunker_buster":      ["fire"],
	&"glass_cannon":       ["fire"],
	&"gambler":            ["fire"],
	# precision / headshot cluster
	&"headstrong":         ["precision"],
	&"trick_shot":         ["precision"],
	&"sniper":             ["precision"],
	&"surgical":           ["precision"],
	&"marksman":           ["precision"],
	&"last_round":         ["precision"],
	# ammo / mag / reserve cluster
	&"mag_size_1":         ["ammo"],
	&"heavy_mag":          ["ammo"],
	&"field_workshop":     ["ammo"],
	&"stockpile":          ["ammo"],
	&"reserve_boost":      ["ammo"],
	&"reload_speed":       ["ammo"],
	# rate cluster (fast cards)
	&"fire_rate_1":        ["rate"],
	&"hair_trigger":       ["rate"],
	&"adrenaline":         ["rate", "fire"],
	&"berserker":          ["rate"],
	&"lightweight":        ["rate"],
	&"combat_drill":       ["rate", "ammo"],
	&"field_specialist":   ["rate", "fire", "precision"],
	&"field_trauma":       ["rate"],
	&"the_edge":           ["rate", "fire", "ammo", "precision"],
	&"vampire_rounds":     [],  # neutral effect — no tag needed
	&"cold_steel":         ["precision"],  # recoil-down helps precision feel
	&"recoil_down":        ["precision"],
	&"field_sights":       ["precision"],
	&"quickdraw":          ["rate", "ammo"],
	&"heavy_slugs":        ["fire"],
	&"suppressing_fire":   ["rate"],
	&"tactical_reload":    ["ammo"],
}

const STARTER_CARDS: Array[String] = [
	"res://scenes/cards/data/fire_rate_1.tres",
	"res://scenes/cards/data/damage_1.tres",
	"res://scenes/cards/data/mag_1.tres",
	"res://scenes/cards/data/reload_speed.tres",
	"res://scenes/cards/data/recoil_down.tres",
	"res://scenes/cards/data/reserve_boost.tres",
	"res://scenes/cards/data/stockpile.tres",
	"res://scenes/cards/data/headstrong.tres",
	"res://scenes/cards/data/marksman.tres",
	"res://scenes/cards/data/last_round.tres",
	"res://scenes/cards/data/adrenaline.tres",
	"res://scenes/cards/data/heavy_mag.tres",
	"res://scenes/cards/data/lightweight.tres",
	"res://scenes/cards/data/magnum.tres",
	"res://scenes/cards/data/surgical.tres",
	"res://scenes/cards/data/berserker.tres",
	"res://scenes/cards/data/sniper.tres",
	"res://scenes/cards/data/field_specialist.tres",
	"res://scenes/cards/data/glass_cannon.tres",
	"res://scenes/cards/data/field_trauma.tres",
	"res://scenes/cards/data/field_workshop.tres",
	"res://scenes/cards/data/hot_loads.tres",
	"res://scenes/cards/data/hair_trigger.tres",
	"res://scenes/cards/data/cold_steel.tres",
	"res://scenes/cards/data/trick_shot.tres",
	"res://scenes/cards/data/combat_drill.tres",
	"res://scenes/cards/data/bunker_buster.tres",
	"res://scenes/cards/data/the_edge.tres",
	"res://scenes/cards/data/vampire_rounds.tres",
	"res://scenes/cards/data/gambler.tres",
	"res://scenes/cards/data/pyromaniac.tres",
	"res://scenes/cards/data/surgical_precision.tres",
	"res://scenes/cards/data/munitions_specialist.tres",
	"res://scenes/cards/data/field_sights.tres",
	"res://scenes/cards/data/quickdraw.tres",
	"res://scenes/cards/data/heavy_slugs.tres",
	"res://scenes/cards/data/suppressing_fire.tres",
	"res://scenes/cards/data/tactical_reload.tres",
]

func _ready() -> void:
	print("[CardSystem] ready")
	_load_starter_pool()
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.run_started.connect(_on_run_started)

func _load_starter_pool() -> void:
	available_pool.clear()
	for path in STARTER_CARDS:
		var res := ResourceLoader.load(path)
		if res is CardData:
			available_pool.append(res)
		else:
			push_warning("[CardSystem] could not load card: %s" % path)
	print("[CardSystem] starter pool loaded: %d cards" % available_pool.size())

var _first_draft_done: bool = false

func _on_run_started() -> void:
	active_deck.clear()
	_first_draft_done = false
	# Quartermaster perk: pre-draft one random card.
	if MetaProgress.has_unlock(&"perk_quartermaster") and not available_pool.is_empty():
		var card = _pick_weighted(available_pool.duplicate())
		if card != null:
			active_deck.append(card)
			EventBus.card_drafted.emit(card)

func reset_run_deck() -> void:
	active_deck.clear()
	_first_draft_done = false

func _on_wave_ended(_round_n: int) -> void:
	var count := 3
	if not _first_draft_done and MetaProgress.has_unlock(&"perk_quick_draft"):
		count = 5
	_first_draft_done = true
	offer_cards(count)

func offer_cards(count: int) -> void:
	current_offer.clear()
	if available_pool.is_empty():
		EventBus.card_offered.emit(current_offer)
		return
	# Exclude already-drafted cards so the player never sees duplicates.
	var pool := available_pool.duplicate()
	for c in active_deck:
		pool.erase(c)
	if pool.is_empty():
		EventBus.card_offered.emit(current_offer)
		return
	for i in min(count, pool.size()):
		var picked := _pick_weighted(pool)
		if picked != null:
			current_offer.append(picked)
			pool.erase(picked)
	cards_offered_local.emit(current_offer)
	EventBus.card_offered.emit(current_offer)

func pick_card(idx: int) -> void:
	if idx < 0 or idx >= current_offer.size():
		return
	var card: CardData = current_offer[idx]
	active_deck.append(card)
	current_offer.clear()
	card_added_local.emit(card)
	EventBus.card_drafted.emit(card)

func skip_draft() -> void:
	current_offer.clear()
	EventBus.card_drafted.emit(null)

func get_modifier(stat: StringName) -> float:
	var m := 1.0
	for card in active_deck:
		if not _is_card_active(card):
			continue
		match stat:
			&"fire_rate": m *= card.fire_rate_mult
			&"damage": m *= card.damage_mult
			&"mag_size": m *= card.mag_size_mult
			&"reload_time": m *= card.reload_time_mult
			&"recoil": m *= card.recoil_mult
			&"headshot_mult": m *= card.headshot_mult_mult
			&"reserve": m *= card.reserve_mult
	return m

# Synergy cards (requires_tag set) only contribute when at least
# requires_count OTHER cards in the deck share the tag.
func _is_card_active(card: CardData) -> bool:
	if card.requires_tag == &"":
		return true
	var needed: int = card.requires_count
	if needed <= 0:
		return true
	var found := 0
	for other in active_deck:
		if other == card:
			continue
		if _card_has_tag(other, card.requires_tag):
			found += 1
			if found >= needed:
				return true
	return false

func _card_has_tag(card: CardData, tag: StringName) -> bool:
	var tags: Variant = CARD_TAGS.get(card.id)
	if tags == null:
		return false
	for t in tags:
		if StringName(t) == tag:
			return true
	return false

func count_tag(tag: StringName) -> int:
	var n := 0
	for card in active_deck:
		if _card_has_tag(card, tag):
			n += 1
	return n

func mutate_payload(payload: Dictionary) -> Dictionary:
	payload["damage"] = payload.get("damage", 0.0) * get_modifier(&"damage")
	payload["headshot_multiplier"] = payload.get("headshot_multiplier", 1.0) * get_modifier(&"headshot_mult")
	# Conditional effects only fire when the card is active (synergy-gated cards skip otherwise).
	for card in active_deck:
		if not _is_card_active(card):
			continue
		if card.effect_id == &"last_round":
			var weapon = payload.get("source_weapon")
			if weapon != null and "current_ammo" in weapon and weapon.current_ammo == 1:
				payload["damage"] *= 3.0
	return payload

func _on_enemy_killed(_enemy: Node, source_weapon: Node, is_headshot: bool, _pos: Vector3) -> void:
	# Lifesteal: every kill heals the barrier by 1 HP.
	for card in active_deck:
		if card.effect_id == &"lifesteal":
			var barriers := get_tree().get_nodes_in_group("barriers")
			if barriers.size() > 0:
				var b = barriers[0]
				if b.has_method("repair"):
					b.repair(1.0)
			break
	# Marksman: refund 1 reserve round on headshot kill.
	# Note: don't emit weapon_reloaded — that'd play the reload SFX for an ammo refund.
	# HUD polls the active weapon's ammo state in _process so it picks up the change naturally.
	if is_headshot and source_weapon != null:
		for card in active_deck:
			if card.effect_id == &"marksman_refund":
				if "reserve_ammo" in source_weapon:
					source_weapon.reserve_ammo = int(source_weapon.reserve_ammo) + 1
					break

func _pick_weighted(pool: Array) -> CardData:
	var total_w := 0.0
	for c in pool:
		total_w += c.draft_weight
	var roll := randf() * total_w
	var accum := 0.0
	for c in pool:
		accum += c.draft_weight
		if roll <= accum:
			return c
	return pool.back() if not pool.is_empty() else null
