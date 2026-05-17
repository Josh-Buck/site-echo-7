extends Node3D

func _ready() -> void:
	GameState.start_run()
	print("[Main] M1 ready, lifetime_score=%d" % MetaProgress.lifetime_score)
