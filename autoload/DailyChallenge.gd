extends Node

# Daily seeded challenge. One goal per UTC date, picked deterministically so
# every player sees the same daily on the same day. Completion grants bonus
# RD via MetaProgress. State persists in MetaProgress.settings:
#   daily_date       — ISO date string of last completed daily (e.g. "2026-05-21")
#   daily_completed  — bool, true once the player clears today's
# We re-check on run_ended and title-screen entry.

signal daily_completed_today

const TEMPLATES := [
	{"id": "kills_50",     "text": "Get 50 kills in one run",        "kind": "kills",       "target": 50,  "reward": 100},
	{"id": "kills_100",    "text": "Get 100 kills in one run",       "kind": "kills",       "target": 100, "reward": 150},
	{"id": "headshots_20", "text": "Land 20 headshot kills in one run", "kind": "headshots", "target": 20,  "reward": 100},
	{"id": "headshots_50", "text": "Land 50 headshot kills in one run", "kind": "headshots", "target": 50,  "reward": 150},
	{"id": "round_5",      "text": "Reach Wave 5",                   "kind": "round",       "target": 5,   "reward": 80},
	{"id": "round_8",      "text": "Reach Wave 8",                   "kind": "round",       "target": 8,   "reward": 120},
	{"id": "round_12",     "text": "Reach Wave 12",                  "kind": "round",       "target": 12,  "reward": 200},
	{"id": "tokens_500",   "text": "Earn 500 tokens in one run",     "kind": "tokens",      "target": 500, "reward": 120},
	{"id": "deck_8",       "text": "Draft 8 cards in one run",       "kind": "deck",        "target": 8,   "reward": 120},
	{"id": "clean_r3",     "text": "Clear Wave 3 with no barrier damage", "kind": "clean", "target": 3,   "reward": 130},
]

var _run_headshots: int = 0
var _run_kills: int = 0
var _run_tokens_earned: int = 0
var _run_took_damage: bool = false

func _ready() -> void:
	print("[DailyChallenge] ready, today=%s, goal=%s" % [_today(), today_goal()["id"]])
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.barrier_damaged.connect(_on_barrier_damaged)
	EventBus.tokens_changed.connect(_on_tokens_changed)
	EventBus.wave_ended.connect(_on_wave_ended)

func _today() -> String:
	# UTC date as YYYY-MM-DD. Stable across timezones.
	var dict := Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [int(dict["year"]), int(dict["month"]), int(dict["day"])]

func _today_seed() -> int:
	# Deterministic per-date seed for picking today's template.
	var s := _today()
	return hash(s)

func today_goal() -> Dictionary:
	var idx: int = _today_seed() % TEMPLATES.size()
	return TEMPLATES[idx]

func today_completed() -> bool:
	var completed_date: String = String(MetaProgress.get_setting("daily_completed_date", ""))
	return completed_date == _today()

func _on_run_started() -> void:
	_run_headshots = 0
	_run_kills = 0
	_run_tokens_earned = 0
	_run_took_damage = false

func _on_enemy_killed(_e, _src, headshot: bool, _pos) -> void:
	_run_kills += 1
	if headshot:
		_run_headshots += 1

func _on_barrier_damaged(_amt: float, _attacker) -> void:
	_run_took_damage = true

func _on_tokens_changed(_total: int, delta: int) -> void:
	if delta > 0:
		_run_tokens_earned += delta

func _on_wave_ended(round_n: int) -> void:
	# Clean-round goals can complete mid-run when they reach the target wave
	# WITHOUT having taken any barrier damage so far.
	if today_completed():
		return
	var goal: Dictionary = today_goal()
	if goal["kind"] == "clean" and round_n >= int(goal["target"]) and not _run_took_damage:
		_award_daily(goal)

func _on_run_ended(_stats: Dictionary) -> void:
	if today_completed():
		return
	var goal: Dictionary = today_goal()
	var done: bool = false
	match String(goal["kind"]):
		"kills":     done = _run_kills >= int(goal["target"])
		"headshots": done = _run_headshots >= int(goal["target"])
		"round":     done = GameState.current_round >= int(goal["target"])
		"tokens":    done = _run_tokens_earned >= int(goal["target"])
		"deck":      done = CardSystem.active_deck.size() >= int(goal["target"])
	if done:
		_award_daily(goal)

func _award_daily(goal: Dictionary) -> void:
	if today_completed():
		return
	var rd: int = int(goal["reward"])
	MetaProgress.research_data += rd
	MetaProgress.set_setting("daily_completed_date", _today())
	SaveSystem.save_meta()
	EventBus.research_data_changed.emit(MetaProgress.research_data, rd)
	daily_completed_today.emit()
	print("[DailyChallenge] daily complete (%s) +%d RD" % [goal["id"], rd])
