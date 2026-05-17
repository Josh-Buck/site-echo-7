extends GPUParticles3D

func _ready() -> void:
	one_shot = true
	emitting = true
	# Auto-free after particles finish.
	await get_tree().create_timer(lifetime + 0.2).timeout
	queue_free()
