extends Node

# Persistent across runs. Loaded from user://meta.save on launch.

var lifetime_score: int = 0
var lifetime_kills: int = 0
var best_round: int = 0
var research_data: int = 0
var unlocks: Dictionary = {}  # unlock_id -> true

func _ready() -> void:
	print("[MetaProgress] ready")
	SaveSystem.load_meta()

func add_score(amount: int) -> void:
	lifetime_score += amount
	SaveSystem.save_meta()

func record_run_end() -> void:
	if GameState.current_round > best_round:
		best_round = GameState.current_round
	# Convert remaining tokens to RD at end of run (10:1 with round bonus).
	var round_mult: float = 1.0 + (float(GameState.current_round) * 0.05)
	var earned := int(float(GameState.tokens) / 10.0 * round_mult)
	research_data += earned
	SaveSystem.save_meta()

func has_unlock(id: StringName) -> bool:
	return unlocks.get(id, false)

func buy_unlock(id: StringName, cost: int) -> bool:
	if has_unlock(id):
		return false
	if research_data < cost:
		return false
	research_data -= cost
	unlocks[id] = true
	SaveSystem.save_meta()
	return true

func reset_all() -> void:
	lifetime_score = 0
	lifetime_kills = 0
	best_round = 0
	research_data = 0
	unlocks = {}
	SaveSystem.save_meta()

func to_dict() -> Dictionary:
	return {
		"lifetime_score": lifetime_score,
		"lifetime_kills": lifetime_kills,
		"best_round": best_round,
		"research_data": research_data,
		"unlocks": unlocks,
	}

func from_dict(data: Dictionary) -> void:
	lifetime_score = data.get("lifetime_score", 0)
	lifetime_kills = data.get("lifetime_kills", 0)
	best_round = data.get("best_round", 0)
	research_data = data.get("research_data", 0)
	unlocks = data.get("unlocks", {})
