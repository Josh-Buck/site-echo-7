extends Node

# Persistent achievement-style goal tracker. Loads ChallengeData .tres files
# from scenes/cards/data/challenges/, listens on EventBus, awards RD via
# MetaProgress on completion, persists completion + counters in MetaProgress.settings.

# Carries the full resource for UI. EventBus.challenge_completed already exists
# but only carries id+payout; UI binds here to render name/tier without re-lookup.
signal completed(challenge: ChallengeData)

const CHALLENGES_DIR: String = "res://scenes/cards/data/challenges"
const COMPLETED_KEY: String = "challenges_completed"      # Dictionary: id -> true
const COUNTERS_KEY: String = "challenges_counters"        # Dictionary: counter_name -> int

# Static manifest. DirAccess enumeration of res:// is unreliable in web PCK builds —
# it silently returns nothing and the game ships with zero challenges. Keep this
# list in sync when adding new .tres files.
const CHALLENGE_PATHS: Array[String] = [
	"res://scenes/cards/data/challenges/clean_round_1.tres",
	"res://scenes/cards/data/challenges/clean_round_streak_5.tres",
	"res://scenes/cards/data/challenges/clean_to_r10.tres",
	"res://scenes/cards/data/challenges/deck_size_8.tres",
	"res://scenes/cards/data/challenges/deck_size_12.tres",
	"res://scenes/cards/data/challenges/deck_size_15.tres",
	"res://scenes/cards/data/challenges/defeat_director.tres",
	"res://scenes/cards/data/challenges/defeat_subject.tres",
	"res://scenes/cards/data/challenges/headshots_50.tres",
	"res://scenes/cards/data/challenges/headshots_250.tres",
	"res://scenes/cards/data/challenges/headshots_1000.tres",
	"res://scenes/cards/data/challenges/headshots_5000.tres",
	"res://scenes/cards/data/challenges/kills_ar_100.tres",
	"res://scenes/cards/data/challenges/kills_pistol_100.tres",
	"res://scenes/cards/data/challenges/kills_pistol_500.tres",
	"res://scenes/cards/data/challenges/kills_shotgun_100.tres",
	"res://scenes/cards/data/challenges/kills_sidearm_100.tres",
	"res://scenes/cards/data/challenges/specialist_ar_r10.tres",
	"res://scenes/cards/data/challenges/specialist_pistol_r10.tres",
	"res://scenes/cards/data/challenges/specialist_shotgun_r10.tres",
	"res://scenes/cards/data/challenges/streak_headshots_10.tres",
	"res://scenes/cards/data/challenges/survive_r5.tres",
	"res://scenes/cards/data/challenges/survive_r10.tres",
	"res://scenes/cards/data/challenges/survive_r15.tres",
	"res://scenes/cards/data/challenges/survive_r20.tres",
	"res://scenes/cards/data/challenges/survive_r30.tres",
]

var challenges: Array[ChallengeData] = []                 # all loaded
var _by_id: Dictionary = {}                               # id -> ChallengeData

# Lifetime persistent counters. Keys we write under COUNTERS_KEY:
#   "headshots_total", "kills_<weapon_id>"
# Run-scoped counters (reset on run start):
var _run_headshots_in_round_max: int = 0
var _run_headshots_in_round_current: int = 0
var _run_clean_streak: int = 0
var _run_round_started_clean: bool = true
var _run_took_any_damage: bool = false
var _run_deck_size_peak: int = 0
var _run_weapons_used: Dictionary = {}                    # weapon id -> true

func _ready() -> void:
	print("[ChallengeTracker] ready")
	_load_challenges()
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.barrier_damaged.connect(_on_barrier_damaged)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.card_drafted.connect(_on_card_drafted)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)

func _load_challenges() -> void:
	for path in CHALLENGE_PATHS:
		var res: Resource = load(path)
		if res is ChallengeData:
			var cd: ChallengeData = res
			challenges.append(cd)
			_by_id[cd.id] = cd
		else:
			push_warning("[ChallengeTracker] missing or invalid challenge: %s" % path)
	print("[ChallengeTracker] loaded %d challenges" % challenges.size())

# --- persistence helpers ----------------------------------------------------

func _completed() -> Dictionary:
	return MetaProgress.get_setting(COMPLETED_KEY, {})

func _counters() -> Dictionary:
	return MetaProgress.get_setting(COUNTERS_KEY, {})

func is_completed(id: StringName) -> bool:
	return _completed().get(String(id), false)

func get_counter(key: String) -> int:
	return int(_counters().get(key, 0))

func _set_counter(key: String, value: int) -> void:
	var c := _counters()
	c[key] = value
	MetaProgress.set_setting(COUNTERS_KEY, c)

func _inc_counter(key: String, delta: int = 1) -> int:
	var v := get_counter(key) + delta
	_set_counter(key, v)
	return v

func _mark_complete(cd: ChallengeData) -> void:
	if is_completed(cd.id):
		return
	var c := _completed()
	c[String(cd.id)] = true
	MetaProgress.set_setting(COMPLETED_KEY, c)
	MetaProgress.research_data += cd.rd_payout
	SaveSystem.save_meta()
	EventBus.research_data_changed.emit(MetaProgress.research_data, cd.rd_payout)
	EventBus.challenge_completed.emit(cd.id, cd.rd_payout)
	# Also push the resource for the toast UI via a side-channel.
	last_completed = cd
	completed.emit(cd)
	print("[ChallengeTracker] COMPLETED %s (+%d RD)" % [cd.id, cd.rd_payout])

var last_completed: ChallengeData = null

# --- event handlers ---------------------------------------------------------

func _on_run_started() -> void:
	_run_headshots_in_round_max = 0
	_run_headshots_in_round_current = 0
	_run_clean_streak = 0
	_run_took_any_damage = false
	_run_round_started_clean = true
	_run_deck_size_peak = 0
	_run_weapons_used.clear()

func _on_run_ended(_stats) -> void:
	pass

func _on_wave_started(_round_number: int, _composition) -> void:
	_run_headshots_in_round_current = 0
	_run_round_started_clean = true

func _on_wave_ended(round_number: int) -> void:
	# No-damage round / streak / rounds_reached_clean.
	if _run_round_started_clean:
		_run_clean_streak += 1
	else:
		_run_clean_streak = 0

	# Iterate all challenges for round-based triggers.
	for cd in challenges:
		if is_completed(cd.id):
			continue
		match String(cd.tracking_kind):
			"rounds_reached":
				if round_number >= cd.target_value:
					_mark_complete(cd)
			"no_damage_round":
				if _run_round_started_clean:
					_mark_complete(cd)
			"no_damage_streak":
				if _run_clean_streak >= cd.target_value:
					_mark_complete(cd)
			"rounds_reached_clean":
				if not _run_took_any_damage and round_number >= cd.target_value:
					_mark_complete(cd)
			"specialist_round":
				if round_number >= cd.target_value and _is_specialist(cd.weapon_filter):
					_mark_complete(cd)
			"headshots_in_round":
				if _run_headshots_in_round_max >= cd.target_value:
					_mark_complete(cd)

func _on_barrier_damaged(_amount: float, _attacker) -> void:
	_run_round_started_clean = false
	_run_took_any_damage = true

func _on_weapon_fired(weapon, _payload) -> void:
	if weapon == null or not ("data" in weapon) or weapon.data == null:
		return
	_run_weapons_used[weapon.data.id] = true

func _on_card_drafted(card) -> void:
	if card == null:
		return
	var size: int = CardSystem.active_deck.size()
	if size > _run_deck_size_peak:
		_run_deck_size_peak = size
	for cd in challenges:
		if is_completed(cd.id):
			continue
		if String(cd.tracking_kind) == "deck_size_in_run" and _run_deck_size_peak >= cd.target_value:
			_mark_complete(cd)

func _on_enemy_killed(enemy, source_weapon, headshot: bool, _pos) -> void:
	# Lifetime totals.
	_inc_counter("kills_total", 1)
	if headshot:
		var hs_total := _inc_counter("headshots_total", 1)
		_run_headshots_in_round_current += 1
		if _run_headshots_in_round_current > _run_headshots_in_round_max:
			_run_headshots_in_round_max = _run_headshots_in_round_current
		_check_threshold("headshots_total", hs_total)
		_check_in_round_streak()
	else:
		# Headshot streak is consecutive headshots; non-headshot kill resets the run streak counter.
		_run_headshots_in_round_current = 0

	# Per-weapon kills.
	var wid: StringName = &""
	if source_weapon != null and "data" in source_weapon and source_weapon.data != null:
		wid = source_weapon.data.id
	if wid != &"":
		var k := "kills_" + String(wid)
		var v := _inc_counter(k, 1)
		_check_weapon_threshold(wid, v)

	# Boss kills.
	var eid: StringName = &""
	if enemy != null and "data" in enemy and enemy.data != null:
		eid = enemy.data.id
	if eid != &"":
		for cd in challenges:
			if is_completed(cd.id):
				continue
			if String(cd.tracking_kind) == "boss_killed" and cd.enemy_filter == eid:
				_mark_complete(cd)

func _check_threshold(counter_name: String, value: int) -> void:
	for cd in challenges:
		if is_completed(cd.id):
			continue
		if String(cd.tracking_kind) == counter_name and value >= cd.target_value:
			_mark_complete(cd)

func _check_weapon_threshold(wid: StringName, value: int) -> void:
	for cd in challenges:
		if is_completed(cd.id):
			continue
		if String(cd.tracking_kind) == "weapon_kills" and cd.weapon_filter == wid and value >= cd.target_value:
			_mark_complete(cd)

func _check_in_round_streak() -> void:
	for cd in challenges:
		if is_completed(cd.id):
			continue
		if String(cd.tracking_kind) == "headshots_in_round" and _run_headshots_in_round_current >= cd.target_value:
			_mark_complete(cd)

func _is_specialist(weapon_id: StringName) -> bool:
	# "Only fired weapon_id this run." Allows sidearm fallback to count as a violation too —
	# specialist runs mean ONLY that weapon. We exempt nothing.
	if _run_weapons_used.is_empty():
		return false
	if _run_weapons_used.size() == 1 and _run_weapons_used.has(weapon_id):
		return true
	return false

# --- public API for UI ------------------------------------------------------

func all_challenges() -> Array[ChallengeData]:
	return challenges

func completion_count() -> int:
	return _completed().size()
