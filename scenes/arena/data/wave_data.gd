class_name WaveData extends Resource

@export var id: StringName = &""
@export var round_number: int = 1
@export var composition: Array[Resource] = []  # of EnemyData
@export var counts: Array[int] = []
@export var spawn_window_seconds: float = 30.0
@export var simultaneous_active_cap: int = 8
