class_name ChallengeData extends Resource

# Persistent achievement-style goal. Tracked by ChallengeTracker autoload.
# tracking_kind tells the tracker which counter/event drives this challenge.

@export_category("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_category("Tier")
@export_enum("Bronze", "Silver", "Gold", "Platinum") var tier: int = 0
@export var rd_payout: int = 10

@export_category("Tracking")
# kills_total          - any enemy kill increments
# headshots_total      - headshot kills increment (lifetime)
# headshots_in_round   - resets each wave; consecutive count
# rounds_reached       - target_value = round number to reach
# weapon_kills         - kills with weapon_filter id
# no_damage_round      - 1 if any single round ends with 0 barrier damage
# no_damage_streak     - consecutive clean rounds
# rounds_reached_clean - rounds_reached AND no barrier damage so far this run
# deck_size_in_run     - card_drafted up to peak deck size in a run
# specialist_round     - reach target_value round having only fired weapon_filter
# boss_killed          - enemy_filter id matches killed enemy
@export var tracking_kind: StringName = &"kills_total"
@export var target_value: int = 1

@export_category("Filters (optional)")
@export var weapon_filter: StringName = &""
@export var enemy_filter: StringName = &""

func tier_name() -> String:
	return ["Bronze", "Silver", "Gold", "Platinum"][tier]
