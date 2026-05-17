extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var next_wave_button: Button = $Panel/VBox/NextWaveButton
@onready var retry_button: Button = $Panel/VBox/RetryButton

var _is_game_over: bool = false

func _ready() -> void:
	panel.visible = false
	# WaveComplete is the last step in the between-waves flow:
	# wave_ended → card draft → shop → WaveComplete → NEXT WAVE
	EventBus.shop_done.connect(_on_shop_done)
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed)
	next_wave_button.pressed.connect(_on_next_wave_pressed)
	retry_button.pressed.connect(_on_retry_pressed)

func _on_shop_done() -> void:
	if _is_game_over:
		return
	_is_game_over = false
	var round_n := GameState.current_round
	title_label.text = "WAVE %d COMPLETE" % round_n
	stats_label.text = "Kills: %d    Tokens: %d    Lifetime: %d" % [GameState.current_score, GameState.tokens, MetaProgress.lifetime_kills]
	next_wave_button.visible = true
	next_wave_button.text = "NEXT WAVE"
	retry_button.visible = true
	retry_button.text = "RESTART"
	_show()

func _on_barrier_destroyed() -> void:
	# DeathScreen owns the run-over UX. WaveComplete just suppresses itself.
	_is_game_over = true
	panel.visible = false

func _show() -> void:
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	SaveSystem.save_meta()

func _on_next_wave_pressed() -> void:
	AudioMan.play_sfx("ui_click")
	var spawn_ring := get_tree().current_scene.find_child("SpawnRing", true, false)
	if spawn_ring != null and spawn_ring.has_method("start_next_wave"):
		panel.visible = false
		get_tree().paused = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		spawn_ring.start_next_wave()
	else:
		push_warning("[WaveComplete] SpawnRing not found")

func _on_retry_pressed() -> void:
	AudioMan.play_sfx("ui_click")
	get_tree().paused = false
	SaveSystem.save_meta()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
