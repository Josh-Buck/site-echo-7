extends Node3D

@export var waves: Array[Resource] = []  # of WaveData
@export var auto_start: bool = true

const TELEGRAPH_LEAD: float = 0.9  # seconds before spawn — gives player time to spin toward the breach

var _spawn_points: Array = []
var _spawn_queue: Array = []  # of EnemyData
var _active_count: int = 0
var _pending_count: int = 0  # telegraphed but not yet finalized
var _total_to_spawn: int = 0
var _wave_active: bool = false
var _spawn_timer: float = 0.0
var _spawn_interval: float = 1.0
var _last_spawn_index: int = -1
var _current_wave_index: int = -1
var _current_wave: WaveData = null
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	EventBus.enemy_killed.connect(_on_enemy_killed)
	await get_tree().process_frame
	_spawn_points = get_tree().get_nodes_in_group("spawn_points")
	if _spawn_points.is_empty():
		push_warning("[SpawnRing] no spawn_points group members found")
	if auto_start and not waves.is_empty():
		start_next_wave()

func refresh_spawn_points() -> void:
	_spawn_points = get_tree().get_nodes_in_group("spawn_points")
	_last_spawn_index = -1
	print("[SpawnRing] refreshed spawn_points=%d" % _spawn_points.size())

func start_next_wave() -> void:
	_current_wave_index += 1
	if _current_wave_index >= waves.size():
		EventBus.run_ended.emit({"victory": true, "rounds": waves.size()})
		return
	var wd = waves[_current_wave_index]
	if wd is WaveData:
		_start_wave(wd)
	else:
		push_warning("[SpawnRing] wave at index %d is not WaveData" % _current_wave_index)

func has_next_wave() -> bool:
	return _current_wave_index + 1 < waves.size()

func get_current_wave() -> WaveData:
	return _current_wave

func _start_wave(wd: WaveData) -> void:
	if wd == null or wd.composition.is_empty():
		return
	_current_wave = wd
	_spawn_queue.clear()
	_active_count = 0
	_pending_count = 0
	# Run modifier — doubles enemy counts per wave.
	var mult: int = 2 if GameState.has_modifier(&"double_spawn") else 1
	for i in wd.composition.size():
		var enemy = wd.composition[i]
		var count: int = (wd.counts[i] if i < wd.counts.size() else 0) * mult
		for _j in count:
			_spawn_queue.append(enemy)
	_spawn_queue.shuffle()
	_total_to_spawn = _spawn_queue.size()
	_spawn_interval = max(0.4, wd.spawn_window_seconds / float(max(1, _total_to_spawn)))
	_spawn_timer = 1.0
	_wave_active = true
	GameState.current_round = wd.round_number
	EventBus.wave_started.emit(wd.round_number, wd.composition)
	print("[SpawnRing] wave %d: %d zombies, interval=%.2fs" % [wd.round_number, _total_to_spawn, _spawn_interval])

func _process(delta: float) -> void:
	if not _wave_active:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0 and not _spawn_queue.is_empty() and (_active_count + _pending_count) < _current_wave.simultaneous_active_cap:
		_telegraph_and_schedule_spawn()
		_spawn_timer = _spawn_interval

# Player feedback: 0.9s before a zombie pops in, the spawn point flashes red and
# plays a directional sting so the player can spin toward the threat.
func _telegraph_and_schedule_spawn() -> void:
	if _spawn_queue.is_empty() or _spawn_points.is_empty():
		return
	var enemy: EnemyData = _spawn_queue.pop_front()
	if enemy == null or enemy.scene == null:
		push_warning("[SpawnRing] enemy data has no scene assigned")
		return
	var idx := _pick_spawn_index()
	var sp: Node3D = _spawn_points[idx]
	_pending_count += 1
	_play_telegraph_at(sp.global_position)
	# Defer the actual spawn — timer survives pause for consistency with menu pausing.
	var t := get_tree().create_timer(TELEGRAPH_LEAD)
	t.timeout.connect(_finalize_spawn.bind(enemy, sp))

func _play_telegraph_at(world_pos: Vector3) -> void:
	# Visual-only telegraph for now — the synth beep stacked with other 3D sources
	# and read as background gunfire in playtest. Re-add as a single 2D beep later.
	# AudioMan.play_sfx("spawn_telegraph", world_pos)
	pass
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.25, 0.15, 1)
	light.light_energy = 5.0
	light.omni_range = 5.5
	light.shadow_enabled = false
	get_tree().current_scene.add_child(light)
	light.global_position = world_pos + Vector3(0, 1.0, 0)
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, TELEGRAPH_LEAD)
	tw.tween_callback(light.queue_free)

func _finalize_spawn(enemy: EnemyData, sp: Node3D) -> void:
	_pending_count = max(0, _pending_count - 1)
	if not _wave_active:
		return
	if not is_instance_valid(sp):
		# Spawn point freed (e.g. arena swapped mid-telegraph) — drop this spawn.
		return
	var inst: Node = enemy.scene.instantiate()
	if "data" in inst:
		inst.data = enemy
	get_tree().current_scene.add_child(inst)
	if inst is Node3D:
		(inst as Node3D).global_position = sp.global_position
	_active_count += 1

func _pick_spawn_index() -> int:
	var idx := _rng.randi_range(0, _spawn_points.size() - 1)
	if idx == _last_spawn_index and _spawn_points.size() > 1:
		idx = (idx + 1) % _spawn_points.size()
	_last_spawn_index = idx
	return idx

func _on_enemy_killed(_enemy: Node, _src: Node, _hs: bool, _pos: Vector3) -> void:
	if not _wave_active:
		return
	_active_count = max(0, _active_count - 1)
	# Wave only ends when queue drained AND nothing live AND nothing pending in the telegraph window.
	if _spawn_queue.is_empty() and _active_count == 0 and _pending_count == 0:
		_wave_active = false
		EventBus.wave_ended.emit(_current_wave.round_number)
