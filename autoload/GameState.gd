extends Node

# Bump on every push so the title screen reflects the build the user is playing.
# Format: vMAJOR.MINOR.PATCH — bump PATCH on every commit, MINOR on a feature/system
# landing, MAJOR at 1.0 (release).
const VERSION: String = "v0.6.1"

# Current-run state. Reset on death. Not persisted.

var current_round: int = 0
var current_score: int = 0
var tokens: int = 0
var tokens_earned_this_run: int = 0
var run_active: bool = false
var kills_by_type: Dictionary = {}  # display_name -> int
var card_usage: Dictionary = {}  # card display_name -> kills-while-equipped
# Token-shop emplacement state.
var turret_count: int = 0
# Applied to zombie move_speed at spawn; reset to 1.0 once a wave starts so the
# slow lasts exactly one wave (the wave you bought it for).
var zombie_speed_mult_next_wave: float = 1.0

func _ready() -> void:
	print("[GameState] ready")
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.tokens_changed.connect(_on_tokens_changed)
	EventBus.wave_started.connect(_on_wave_started)

func _on_wave_started(_round_n: int, _composition) -> void:
	# Slow field is one-wave only — consume the modifier so it doesn't persist.
	zombie_speed_mult_next_wave = 1.0

func start_run() -> void:
	current_round = 0
	current_score = 0
	tokens = 0
	tokens_earned_this_run = 0
	turret_count = 0
	zombie_speed_mult_next_wave = 1.0
	kills_by_type.clear()
	card_usage.clear()
	# Apply meta-unlocked run-start perks.
	if MetaProgress.has_unlock(&"perk_combat_veteran"):
		tokens += 20
		tokens_earned_this_run += 20
	run_active = true
	EventBus.run_started.emit()

func end_run() -> void:
	run_active = false
	var stats := {
		"rounds": current_round,
		"score": current_score,
		"tokens": tokens,
	}
	EventBus.run_ended.emit(stats)

func _on_enemy_killed(enemy: Node, _src: Node, _hs: bool, _pos: Vector3) -> void:
	var label := "Zombie"
	if enemy != null and "data" in enemy and enemy.data != null and enemy.data.display_name != "":
		label = enemy.data.display_name
	kills_by_type[label] = int(kills_by_type.get(label, 0)) + 1
	# Attribute kill to every currently-equipped card (proxy for "card use").
	for card in CardSystem.active_deck:
		var key: String = card.display_name
		card_usage[key] = int(card_usage.get(key, 0)) + 1

func _on_tokens_changed(_new_total: int, delta: int) -> void:
	if delta > 0:
		tokens_earned_this_run += delta

func get_top_cards(n: int = 3) -> Array:
	var entries: Array = []
	for k in card_usage.keys():
		entries.append({"name": k, "uses": int(card_usage[k])})
	entries.sort_custom(func(a, b): return a["uses"] > b["uses"])
	return entries.slice(0, n)

func compute_rd_payout() -> int:
	# floor(tokens / 10) × round-survival multiplier (per design-plan).
	var round_mult: float = 1.0 + (float(current_round) * 0.05)
	var earned: int = int(floor(float(tokens) / 10.0) * round_mult)
	if current_round >= 20:
		earned += 300
	elif current_round >= 15:
		earned += 100
	elif current_round >= 10:
		earned += 40
	return earned
