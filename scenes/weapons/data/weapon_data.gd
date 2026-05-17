class_name WeaponData extends Resource

@export_category("Identity")
@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_category("Damage")
@export var base_damage: float = 10.0
@export var headshot_multiplier: float = 2.0
@export_enum("hitscan", "projectile") var damage_type: int = 0

@export_category("Fire")
@export_range(0.1, 30.0, 0.1) var fire_rate: float = 4.0
@export var automatic: bool = false
@export var mag_size: int = 12
@export var reserve_ammo_max: int = 120

@export_category("Reload")
@export_range(0.1, 5.0, 0.05) var reload_time: float = 1.5

@export_category("Recoil")
@export var recoil_vertical: float = 1.5
@export var recoil_horizontal: float = 0.4
@export var recoil_recovery: float = 0.3

@export_category("Audio/Visual")
@export var fire_sfx: AudioStream
@export var reload_sfx: AudioStream
@export var viewmodel_scene: PackedScene
