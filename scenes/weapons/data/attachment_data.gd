class_name AttachmentData extends Resource

# Schema-only stub. Application of these effects to a Weapon's stats is
# deliberately TODO — that wiring belongs to a future weapon-attachment pass
# (zombie-gameplay-dev lane). For now this resource exists so the editor
# inspector, save schema, and MetaScreen can be developed against a real type.

@export_category("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_category("Fit")
# Which weapon ids (per WeaponData.id) this attachment can be installed on.
@export var weapon_filter: Array[StringName] = []
# Body slot the attachment occupies. Only one attachment per slot per weapon.
@export var slot: StringName = &"muzzle"

@export_category("Effect")
# Identifies how the value applies. Examples: damage_mul, recoil_mul,
# mag_size_add, reload_time_mul, spread_mul, fire_rate_mul.
@export var effect_kind: StringName = &"damage_mul"
@export var effect_value: float = 1.0

@export_category("Economy")
@export var rd_cost: int = 100
