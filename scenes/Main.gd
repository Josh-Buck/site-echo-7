extends Node3D

const COOLING_TOWER := preload("res://scenes/arena/CoolingTower.tscn")
const TENSION_STINGER := preload("res://audio/ambient/tension_stinger.ogg")
const ARENA_SWAP_ROUND := 11
const STINGER_FIRST_ROUND := 5

var _swapped: bool = false

func _ready() -> void:
	GameState.start_run()
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.wave_started.connect(_on_wave_started)
	print("[Main] M1 ready, lifetime_score=%d" % MetaProgress.lifetime_score)

func _on_wave_started(round_number: int, _composition: Array) -> void:
	if round_number >= STINGER_FIRST_ROUND:
		AudioMan.play_2d(TENSION_STINGER, -6.0, 0.0)

func _on_wave_ended(round_number: int) -> void:
	if _swapped:
		return
	if round_number + 1 < ARENA_SWAP_ROUND:
		return
	_swap_to_cooling_tower()

func _swap_to_cooling_tower() -> void:
	_swapped = true
	var old_arena: Node = get_node_or_null("Arena")
	if old_arena == null:
		push_warning("[Main] no Arena child to swap")
		return
	# Rename the outgoing arena first — otherwise add_child auto-renames the new
	# one to "@Arena@2" because the old node still occupies the name until
	# queue_free runs at end-of-frame, and then `get_node("Arena")` returns null.
	var old_index := old_arena.get_index()
	old_arena.name = "ArenaOld"
	var new_arena: Node = COOLING_TOWER.instantiate()
	new_arena.name = "Arena"
	add_child(new_arena)
	move_child(new_arena, old_index)
	old_arena.queue_free()
	var ring: Node = get_node_or_null("SpawnRing")
	if ring and ring.has_method("refresh_spawn_points"):
		# Wait one frame so old arena's spawn_points are out of the group.
		await get_tree().process_frame
		ring.refresh_spawn_points()
	print("[Main] swapped arena to CoolingTower")
