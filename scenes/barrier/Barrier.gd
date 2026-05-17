extends StaticBody3D

signal hp_changed(current: float, max_hp_val: float)

@export var max_hp: float = 100.0

var current_hp: float = 0.0
var _destroyed: bool = false

func _ready() -> void:
	# Apply meta-unlocked barrier HP bonuses.
	var bonus: float = 0.0
	if MetaProgress.has_unlock(&"barrier_hp_1"):
		bonus += 10.0
	if MetaProgress.has_unlock(&"barrier_hp_2"):
		bonus += 20.0
	if MetaProgress.has_unlock(&"barrier_hp_3"):
		bonus += 30.0
	if MetaProgress.has_unlock(&"perk_reinforced_barrier"):
		bonus += max_hp * 0.2
	max_hp += bonus
	current_hp = max_hp
	add_to_group("barriers")
	collision_layer = 2
	collision_mask = 0
	hp_changed.emit(current_hp, max_hp)

func take_damage(amount: float, attacker: Node = null) -> void:
	if _destroyed:
		return
	current_hp = max(0.0, current_hp - amount)
	EventBus.barrier_damaged.emit(amount, attacker)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		_destroyed = true
		EventBus.barrier_destroyed.emit()

func repair(amount: float) -> void:
	if _destroyed:
		return
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func get_hp_fraction() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp
