class_name Turret extends Node3D

# Cheap auto-turret. Picks the nearest live zombie within range every cooldown and
# applies a small damage tick. Deliberately weak — meant as an alternative token sink,
# not a replacement for the player's gun.

const RANGE: float = 14.0
const FIRE_INTERVAL: float = 1.6
const DAMAGE: float = 8.0
const TRACER_SCENE := preload("res://scenes/weapons/vfx/BulletTracer.tscn")

var _cooldown: float = 0.0

@onready var _base: MeshInstance3D = $Base
@onready var _barrel: MeshInstance3D = $Barrel
@onready var _muzzle: Marker3D = $Barrel/Muzzle

func _ready() -> void:
	# Start with a small random offset so multiple turrets don't fire in lockstep.
	_cooldown = randf_range(0.0, FIRE_INTERVAL)

func _process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	var target := _pick_target()
	if target == null:
		_cooldown = 0.3  # short retry while waiting for a target
		return
	_aim_at(target.global_position)
	_fire(target)
	_cooldown = FIRE_INTERVAL

func _pick_target() -> Node3D:
	var closest: Node3D = null
	var closest_d2: float = RANGE * RANGE
	for z in get_tree().get_nodes_in_group("zombies"):
		if not (z is Node3D):
			continue
		var nz := z as Node3D
		# Skip already-dying zombies (state DIE or layer 0).
		if "state" in nz and nz.state == 5:  # AIState.DIE = 5 (not 4)... safety: skip below
			continue
		var d2: float = nz.global_position.distance_squared_to(global_position)
		if d2 < closest_d2:
			closest_d2 = d2
			closest = nz
	return closest

func _aim_at(target_pos: Vector3) -> void:
	var p := target_pos
	p.y = global_position.y + 0.4
	look_at(p, Vector3.UP)
	# Look_at points -Z at the target; the barrel mesh is along +Z, so flip the visual.

func _fire(target: Node3D) -> void:
	if target == null or not is_instance_valid(target):
		return
	var from: Vector3 = _muzzle.global_position if _muzzle else global_position + Vector3(0, 0.5, 0)
	var to: Vector3 = target.global_position + Vector3(0, 1.0, 0)
	# Spawn a tracer.
	var t := TRACER_SCENE.instantiate()
	get_tree().current_scene.add_child(t)
	if t.has_method("setup"):
		t.setup(from, to)
	# Turrets used to play the AR-fire synth, which made it sound like extra
	# gunshots were going off when the player wasn't firing. Visual tracer
	# is enough feedback for an automated emplacement.
	if target.has_method("take_damage"):
		# Pass self as the source — turret kills aren't credited to a weapon.
		target.take_damage(DAMAGE, self, false, to)
