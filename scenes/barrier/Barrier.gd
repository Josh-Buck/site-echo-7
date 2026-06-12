extends StaticBody3D

signal hp_changed(current: float, max_hp_val: float)

@export var max_hp: float = 100.0

var current_hp: float = 0.0
var _destroyed: bool = false
var _regen_rate: float = 0.0  # HP/sec, active only during the wave granted via Shop

func _ready() -> void:
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
	# Recruit Mode: settings-driven so it applies regardless of ready order
	# (Barrier readies before Main calls GameState.start_run).
	if bool(MetaProgress.get_setting("recruit_mode", false)):
		max_hp *= 1.5
	current_hp = max_hp
	add_to_group("barriers")
	collision_layer = 2
	collision_mask = 0
	hp_changed.emit(current_hp, max_hp)
	EventBus.wave_ended.connect(_on_wave_ended)

func _process(delta: float) -> void:
	if _destroyed or _regen_rate <= 0.0:
		return
	if current_hp >= max_hp:
		return
	current_hp = min(max_hp, current_hp + _regen_rate * delta)
	hp_changed.emit(current_hp, max_hp)

func _on_wave_ended(_round_n: int) -> void:
	# Regen is a one-wave effect granted at the previous between-wave shop.
	_regen_rate = 0.0

func enable_regen_next_wave(rate: float) -> void:
	_regen_rate = rate

func bump_max_hp(amount: float) -> void:
	max_hp += amount
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)

func take_damage(amount: float, attacker: Node = null) -> void:
	if _destroyed:
		return
	current_hp = max(0.0, current_hp - amount)
	EventBus.barrier_damaged.emit(amount, attacker)
	hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		_destroyed = true
		# v0.9 audio: explicit call — AudioMan no longer listens on EventBus.
		AudioMan.play_barrier_destroyed()
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
