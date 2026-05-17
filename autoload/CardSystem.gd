extends Node

# Card draft pool, active deck, effect resolution pipeline.
# Stubbed in M0/M1. Real implementation lands in M2.

var active_deck: Array = []  # CardData instances
var draft_pool: Array = []

func _ready() -> void:
	print("[CardSystem] ready")

func reset_run_deck() -> void:
	active_deck.clear()

# Called by Weapon.gd before damage application. Walks active_deck and lets
# each card mutate the payload. M1 returns the payload unchanged.
func mutate_payload(payload: Dictionary) -> Dictionary:
	return payload
