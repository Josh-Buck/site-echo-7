extends StaticBody3D

signal hp_changed(current: float, max_hp_val: float)

const HIT_LIGHT_A := preload("res://audio/sfx/barrier/hit_01.ogg")
const HIT_LIGHT_B := preload("res://audio/sfx/barrier/hit_02.ogg")
const HIT_HEAVY := preload("res://audio/sfx/barrier/hit_heavy.ogg")
const CRITICAL_ALARM := preload("res://audio/sfx/barrier/critical_alarm.ogg")

@export var max_hp: float = 100.0

var current_hp: float = 0.0
var _destroyed: bool = false
var _heavy_threshold: float = 0.0
var _alarm_player: AudioStreamPlayer = null
var _alarm_active: bool = false
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
	current_hp = max_hp
	# Heavy hits = 12% of starting HP. With 100 base HP, that's 12 dmg — Runner/Tank tier.
	_heavy_threshold = max_hp * 0.12
	add_to_group("barriers")
	collision_layer = 2
	collision_mask = 0
	_alarm_player = AudioStreamPlayer.new()
	_alarm_player.stream = CRITICAL_ALARM
	_alarm_player.bus = &"Master"
	_alarm_player.volume_db = -16.0
	_alarm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	if CRITICAL_ALARM is AudioStreamOggVorbis:
		var alarm: AudioStreamOggVorbis = CRITICAL_ALARM
		alarm.loop = true
	add_child(_alarm_player)
	hp_changed.emit(current_hp, max_hp)
	EventBus.wave_ended.connect(_on_wave_ended)

func _process(delta: float) -> void:
	if _destroyed or _regen_rate <= 0.0:
		return
	if current_hp >= max_hp:
		return
	current_hp = min(max_hp, current_hp + _regen_rate * delta)
	hp_changed.emit(current_hp, max_hp)
	_update_alarm()

func _on_wave_ended(_round_n: int) -> void:
	# Regen is a one-wave effect granted at the previous between-wave shop.
	_regen_rate = 0.0

func enable_regen_next_wave(rate: float) -> void:
	_regen_rate = rate

func bump_max_hp(amount: float) -> void:
	max_hp += amount
	current_hp = min(max_hp, current_hp + amount)
	_heavy_threshold = max_hp * 0.12
	hp_changed.emit(current_hp, max_hp)
	_update_alarm()

func take_damage(amount: float, attacker: Node = null) -> void:
	if _destroyed:
		return
	current_hp = max(0.0, current_hp - amount)
	EventBus.barrier_damaged.emit(amount, attacker)
	hp_changed.emit(current_hp, max_hp)
	_play_impact(amount, attacker)
	_update_alarm()
	if current_hp <= 0.0:
		_destroyed = true
		_stop_alarm()
		EventBus.barrier_destroyed.emit()

func repair(amount: float) -> void:
	if _destroyed:
		return
	current_hp = min(max_hp, current_hp + amount)
	hp_changed.emit(current_hp, max_hp)
	_update_alarm()

func get_hp_fraction() -> float:
	if max_hp <= 0.0:
		return 0.0
	return current_hp / max_hp

func _play_impact(amount: float, attacker: Node) -> void:
	var pos := global_position + Vector3(0, 0.5, 0)
	if attacker is Node3D:
		pos = (attacker as Node3D).global_position
	var stream: AudioStream
	var vol_db: float
	if amount >= _heavy_threshold:
		stream = HIT_HEAVY
		vol_db = -2.0
	else:
		stream = HIT_LIGHT_B if randi() % 2 == 0 else HIT_LIGHT_A
		vol_db = -6.0
	AudioMan.play_3d_at(stream, pos, vol_db, 28.0, 0.05)

func _update_alarm() -> void:
	var frac := get_hp_fraction()
	if not _alarm_active and frac <= 0.25:
		_start_alarm()
	elif _alarm_active and frac >= 0.30:
		_stop_alarm()

func _start_alarm() -> void:
	if _alarm_player == null or _alarm_active:
		return
	_alarm_active = true
	if AudioMan.can_play():
		_alarm_player.play()

func _stop_alarm() -> void:
	if _alarm_player == null or not _alarm_active:
		return
	_alarm_active = false
	_alarm_player.stop()
