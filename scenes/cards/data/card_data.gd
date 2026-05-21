class_name CardData extends Resource

@export_category("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_category("Rarity")
@export_enum("Common", "Rare", "Legendary", "Curse") var rarity: int = 0
@export_range(0.1, 5.0, 0.1) var draft_weight: float = 1.0

@export_category("Stat Modifiers (1.0 = no change; multiplicative)")
@export var fire_rate_mult: float = 1.0
@export var damage_mult: float = 1.0
@export var mag_size_mult: float = 1.0
@export var reload_time_mult: float = 1.0
@export var recoil_mult: float = 1.0
@export var headshot_mult_mult: float = 1.0
@export var reserve_mult: float = 1.0

@export_category("Conditional Effect")
@export var effect_id: StringName = &""  # "marksman_refund", "last_round", "lifesteal", or ""

@export_category("Synergy (optional — leave blank for normal cards)")
@export var requires_tag: StringName = &""           # e.g. &"fire" — card only activates when deck has N of this tag
@export_range(0, 10) var requires_count: int = 0     # N — minimum other-card count to activate

func format_effect_text() -> String:
	var parts: Array[String] = []
	if not is_equal_approx(fire_rate_mult, 1.0):
		parts.append("%+d%% Fire Rate" % int(round((fire_rate_mult - 1.0) * 100)))
	if not is_equal_approx(damage_mult, 1.0):
		parts.append("%+d%% Damage" % int(round((damage_mult - 1.0) * 100)))
	if not is_equal_approx(mag_size_mult, 1.0):
		parts.append("%+d%% Mag Size" % int(round((mag_size_mult - 1.0) * 100)))
	if not is_equal_approx(reload_time_mult, 1.0):
		parts.append("%+d%% Reload Speed" % int(round((1.0 / reload_time_mult - 1.0) * 100)))
	if not is_equal_approx(recoil_mult, 1.0):
		parts.append("%+d%% Recoil" % int(round((recoil_mult - 1.0) * 100)))
	if not is_equal_approx(headshot_mult_mult, 1.0):
		parts.append("%+d%% Headshot Damage" % int(round((headshot_mult_mult - 1.0) * 100)))
	if not is_equal_approx(reserve_mult, 1.0):
		parts.append("%+d%% Reserve Ammo" % int(round((reserve_mult - 1.0) * 100)))
	return "  ".join(parts)
