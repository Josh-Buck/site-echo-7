extends Node

# Decoupled signal hub. Systems emit and listen here, never reach across the tree.

signal enemy_killed(enemy, source_weapon, headshot, position)
signal enemy_damaged(enemy, amount, source_weapon)
signal wave_started(round_number, composition)
signal wave_ended(round_number)
signal card_drafted(card_data)
signal card_offered(choices)
signal weapon_fired(weapon, payload)
signal weapon_reloaded(weapon)
signal weapon_swapped(old_weapon, new_weapon)
signal barrier_damaged(amount, attacker)
signal barrier_destroyed()
signal tokens_changed(new_total, delta)
signal research_data_changed(new_total, delta)
signal run_started()
signal run_ended(stats)
signal challenge_completed(challenge_id, rd_payout)

func _ready() -> void:
	print("[EventBus] ready")
