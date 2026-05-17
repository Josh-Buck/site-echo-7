extends Node

# Card draft pool, active deck, effect resolution pipeline.
# Stubbed for M0. Real implementation lands in M2.

var active_deck: Array = []  # CardData instances
var draft_pool: Array = []

func _ready() -> void:
	print("[CardSystem] ready")

func reset_run_deck() -> void:
	active_deck.clear()

# Future: mutate_payload(payload: Dictionary) -> Dictionary
#   Called by Weapon.gd before damage application. Walks active_deck,
#   each card may mutate the payload (damage, ammo cost, etc).
