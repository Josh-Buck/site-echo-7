extends Node3D

const COOLING_TOWER := preload("res://scenes/arena/CoolingTower.tscn")
const TENSION_STINGER := preload("res://audio/ambient/tension_stinger.ogg")
const STORY_INTRO_SCENE := preload("res://scenes/ui/StoryIntro.tscn")
const ARENA_SWAP_ROUND := 11
const STINGER_FIRST_ROUND := 5

# Between-wave fiction beats. Indexed by round_number (the round that just ended).
const INTERCOM_LINES := {
	1:  "Subject 23 is moving through the lab. Tap power's holding.",
	2:  "More signatures than expected. Recalibrate your draft picks.",
	3:  "Lab door pressure dropping. Containment shifting east.",
	5:  "Tension stinger picked up your last shot. Sound off — we're not alone.",
	7:  "Cooling tower coolant signature spiking. Director may be in there.",
	9:  "Final warning before the cooling tower. Pick a strong card.",
	10: "Subject 23 down. Cooling tower hot. We're moving you in.",
	11: "Lights are dimmer here. Watch the floor grates.",
	14: "Director's HP is now visible to recon. He's getting nervous.",
	16: "Director's biorhythm spiking. Phase change incoming below 50%.",
	18: "Two waves to clear. Drink water. Save your magnum loads.",
	19: "Final approach. The Director is on the move.",
}

var _swapped: bool = false
var _intercom_label: Label = null

func _ready() -> void:
	GameState.start_run()
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.wave_started.connect(_on_wave_started)
	# Show the story intro only on the player's very first run. Subsequent runs
	# skip it — they've seen it. Persisted in MetaProgress.settings.
	if not bool(MetaProgress.get_setting("intro_seen", false)):
		add_child(STORY_INTRO_SCENE.instantiate())
	_build_intercom_label()
	print("[Main] M1 ready, lifetime_score=%d" % MetaProgress.lifetime_score)

func _build_intercom_label() -> void:
	# Floating intercom transcript in the lower-left, off-screen until a wave ends.
	var canvas := CanvasLayer.new()
	canvas.name = "IntercomCanvas"
	canvas.layer = 30
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	_intercom_label = Label.new()
	_intercom_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_intercom_label.position = Vector2(24, -120)
	_intercom_label.size = Vector2(640, 60)
	_intercom_label.add_theme_font_size_override("font_size", 16)
	_intercom_label.add_theme_color_override("font_color", Color(0.85, 0.95, 1.0, 1.0))
	_intercom_label.modulate.a = 0.0
	canvas.add_child(_intercom_label)

func _on_wave_started(_round_number: int, _composition: Array) -> void:
	# Wave-start audio disabled in the v0.9 audio restart. The tension stinger
	# OGG kept getting reported as part of the "constant gunshots" backdrop.
	# Visual wave-intro banner + boss banner are still there for cuing.
	pass

func _on_wave_ended(round_number: int) -> void:
	_play_intercom_line(round_number)
	if _swapped:
		return
	if round_number + 1 < ARENA_SWAP_ROUND:
		return
	_swap_to_cooling_tower()

func _play_intercom_line(round_number: int) -> void:
	if _intercom_label == null:
		return
	if not INTERCOM_LINES.has(round_number):
		return
	_intercom_label.text = "▶ INTERCOM:  " + INTERCOM_LINES[round_number]
	# Cancel any running tween on this label so back-to-back lines don't fight.
	var tw := create_tween()
	tw.tween_property(_intercom_label, "modulate:a", 1.0, 0.35)
	tw.tween_interval(7.0)
	tw.tween_property(_intercom_label, "modulate:a", 0.0, 0.6)

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
