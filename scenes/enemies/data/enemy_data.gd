class_name EnemyData extends Resource

@export_category("Identity")
@export var id: StringName = &""
@export var display_name: String = ""

@export_category("Stats")
@export var max_hp: float = 30.0
@export_range(0.1, 20.0, 0.1) var move_speed: float = 1.5
@export var attack_damage: float = 5.0
@export_range(0.1, 10.0, 0.1) var attack_range: float = 1.5
@export_range(0.1, 5.0, 0.05) var attack_rate: float = 1.0
@export var headshot_multiplier: float = 2.0
@export var armor: bool = false

@export_category("Attack Behavior")
@export_enum("Melee", "Ranged", "Suicide") var attack_type: int = 0
@export var projectile_speed: float = 12.0
@export var projectile_scene: PackedScene

@export_category("Drops")
@export var token_drop: int = 1

@export_category("Visual")
@export var scene: PackedScene
@export var size_scale: float = 1.0
@export var body_color: Color = Color(0.36, 0.3, 0.26)
@export var head_color: Color = Color(0.55, 0.42, 0.36)
@export var eye_color: Color = Color(0.9, 0.18, 0.12)
