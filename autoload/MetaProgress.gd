extends Node

# Persistent across runs. Loaded from user://meta.save on launch.

var lifetime_score: int = 0
var lifetime_kills: int = 0
var best_round: int = 0
var research_data: int = 0
var unlocks: Dictionary = {}  # unlock_id -> true
var settings: Dictionary = {}  # key -> value
# Starter arsenal: pistol + sidearm. AR / shotgun / future weapons unlock via RD.
var unlocked_weapons: Array = ["pistol_m1", "sidearm_backup"]
var unlocked_attachments: Array = []
# Run accounting for the lifetime stats screen.
var total_runs: int = 0
var total_victories: int = 0
var total_rd_earned: int = 0

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
	total_runs += 1
	total_rd_earned += earned
	# Victory = cleared all available waves (set via SpawnRing.run_ended payload).
	# Detect by reaching round 20 which is the current final wave.
	if GameState.current_round >= 20:
		total_victories += 1
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

func has_weapon(id: String) -> bool:
	return unlocked_weapons.has(id)

func unlock_weapon(id: String) -> void:
	if not unlocked_weapons.has(id):
		unlocked_weapons.append(id)
		SaveSystem.save_meta()

func buy_weapon(id: String, cost: int) -> bool:
	if has_weapon(id):
		return false
	if research_data < cost:
		return false
	research_data -= cost
	unlocked_weapons.append(id)
	SaveSystem.save_meta()
	return true

func has_attachment(id: String) -> bool:
	return unlocked_attachments.has(id)

func unlock_attachment(id: String) -> void:
	if not unlocked_attachments.has(id):
		unlocked_attachments.append(id)
		SaveSystem.save_meta()

func buy_attachment(id: String, cost: int) -> bool:
	if has_attachment(id):
		return false
	if research_data < cost:
		return false
	research_data -= cost
	unlocked_attachments.append(id)
	SaveSystem.save_meta()
	return true

func reset_all() -> void:
	lifetime_score = 0
	lifetime_kills = 0
	best_round = 0
	research_data = 0
	unlocks = {}
	settings = {}
	unlocked_weapons = ["pistol_m1", "sidearm_backup"]
	unlocked_attachments = []
	SaveSystem.save_meta()

func to_dict() -> Dictionary:
	return {
		"lifetime_score": lifetime_score,
		"lifetime_kills": lifetime_kills,
		"best_round": best_round,
		"research_data": research_data,
		"unlocks": unlocks,
		"settings": settings,
		"unlocked_weapons": unlocked_weapons,
		"unlocked_attachments": unlocked_attachments,
		"total_runs": total_runs,
		"total_victories": total_victories,
		"total_rd_earned": total_rd_earned,
	}

func from_dict(data: Dictionary) -> void:
	lifetime_score = data.get("lifetime_score", 0)
	lifetime_kills = data.get("lifetime_kills", 0)
	best_round = data.get("best_round", 0)
	research_data = data.get("research_data", 0)
	unlocks = data.get("unlocks", {})
	settings = data.get("settings", {})
	unlocked_weapons = data.get("unlocked_weapons", ["pistol_m1", "sidearm_backup"])
	unlocked_attachments = data.get("unlocked_attachments", [])
	total_runs = data.get("total_runs", 0)
	total_victories = data.get("total_victories", 0)
	total_rd_earned = data.get("total_rd_earned", 0)
	# Guard: pistol + sidearm are starter — always present even if save was hand-edited.
	if not unlocked_weapons.has("pistol_m1"):
		unlocked_weapons.append("pistol_m1")
	if not unlocked_weapons.has("sidearm_backup"):
		unlocked_weapons.append("sidearm_backup")

func get_setting(key: String, default_value):
	return settings.get(key, default_value)

func set_setting(key: String, value) -> void:
	settings[key] = value
	EventBus.settings_changed.emit(key, value)
	SaveSystem.save_meta()

func gore_enabled() -> bool:
	return bool(get_setting("gore_enabled", true))

func get_fov() -> float:
	return float(get_setting("fov", 75.0))
