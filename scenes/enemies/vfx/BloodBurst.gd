extends GPUParticles3D

func setup(headshot: bool) -> void:
	if headshot:
		amount = 28
		var pm := process_material as ParticleProcessMaterial
		if pm:
			pm.initial_velocity_min = 3.5
			pm.initial_velocity_max = 7.0

func _ready() -> void:
	one_shot = true
	# When pool-owned, the pool drives emit/restart and we shouldn't queue_free.
	if is_in_group("pooled_burst"):
		return
	emitting = true
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()
