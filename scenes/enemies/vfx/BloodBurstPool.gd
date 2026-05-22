extends Node

# Pooled BloodBurst emitters. Each zombie kill previously instantiated a fresh
# GPUParticles3D + ParticleProcessMaterial — the GPU upload + scene-tree work
# on every kill is the most likely culprit for the per-kill stutter the user
# reported. Pool keeps a small ring of pre-built emitters and restart()s them.

const BLOOD_BURST_SCENE := preload("res://scenes/enemies/vfx/BloodBurst.tscn")
const POOL_SIZE: int = 6

class Slot:
	var burst: Node3D
	var available: bool = true

var _pool: Array[Slot] = []
var _next: int = 0

func _ready() -> void:
	add_to_group("bloodburst_pool")
	for i in POOL_SIZE:
		var s := Slot.new()
		var b := BLOOD_BURST_SCENE.instantiate() as Node3D
		# Suppress the auto-queue_free in BloodBurst._ready by stripping the script
		# behavior; we control lifetime via the pool. Easiest: add_to_group so the
		# burst script can detect pool ownership and skip queue_free.
		b.add_to_group("pooled_burst")
		# Stop emitting until we explicitly call burst().
		if b is GPUParticles3D:
			(b as GPUParticles3D).emitting = false
		add_child(b)
		s.burst = b
		s.available = true
		_pool.append(s)

func burst(at: Vector3, headshot: bool) -> void:
	var s := _acquire()
	if s == null:
		return
	var b := s.burst
	if b is GPUParticles3D:
		var gp: GPUParticles3D = b
		gp.global_position = at
		# Apply headshot tweak — bigger spray.
		if b.has_method("setup"):
			b.call("setup", headshot)
		gp.emitting = true
		gp.restart()
	s.available = false
	# Free up the slot after the particle lifetime + small buffer.
	var lt: float = 1.2
	if b is GPUParticles3D:
		lt = (b as GPUParticles3D).lifetime + 0.2
	get_tree().create_timer(lt, true, false, true).timeout.connect(func(): s.available = true)

func _acquire() -> Slot:
	for i in POOL_SIZE:
		var idx := (_next + i) % POOL_SIZE
		var s := _pool[idx]
		if s.available:
			_next = (idx + 1) % POOL_SIZE
			return s
	# All in use — recycle the oldest by triggering anyway.
	_next = 1 % POOL_SIZE
	return _pool[0]
