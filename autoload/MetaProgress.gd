extends Node

# Persistent across runs. Loaded from user://meta.save on launch.

var lifetime_score: int = 0
var lifetime_kills: int = 0
var best_round: int = 0
var research_data: int = 0
var unlocks: Dictionary = {}  # unlock_id -> true
var settings: Dictionary = {}  # key -> value

func _ready() -> void:
	print("[MetaProgress] ready")
	SaveSystem.load_meta()

func add_score(amount: int) -> void:
	lifetime_score += amount
	SaveSystem.save_meta()

func record_run_end() -> int:
	if GameState.current_round > best_round:
		best_round = GameState.current_round
	var earned: int = GameState.compute_rd_payout()
	research_data += earned
	SaveSystem.save_meta()
	return earned

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
	settings = {}
	SaveSystem.save_meta()

func to_dict() -> Dictionary:
	return {
		"lifetime_score": lifetime_score,
		"lifetime_kills": lifetime_kills,
		"best_round": best_round,
		"research_data": research_data,
		"unlocks": unlocks,
		"settings": settings,
	}

func from_dict(data: Dictionary) -> void:
	lifetime_score = data.get("lifetime_score", 0)
	lifetime_kills = data.get("lifetime_kills", 0)
	best_round = data.get("best_round", 0)
	research_data = data.get("research_data", 0)
	unlocks = data.get("unlocks", {})
	settings = data.get("settings", {})

func get_setting(key: String, default_value):
	return settings.get(key, default_value)

func set_setting(key: String, value) -> void:
	settings[key] = value
	SaveSystem.save_meta()
