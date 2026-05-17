extends Node

# Current-run state. Reset on death. Not persisted.

var current_round: int = 0
var current_score: int = 0
var tokens: int = 0
var run_active: bool = false

func _ready() -> void:
	print("[GameState] ready")

func start_run() -> void:
	current_round = 0
	current_score = 0
	tokens = 0
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
