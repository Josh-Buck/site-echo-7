extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var next_wave_button: Button = $Panel/VBox/NextWaveButton
@onready var retry_button: Button = $Panel/VBox/RetryButton

var _is_game_over: bool = false

func _ready() -> void:
	panel.visible = false
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed)
	EventBus.run_ended.connect(_on_run_ended)
	next_wave_button.pressed.connect(_on_next_wave_pressed)
	retry_button.pressed.connect(_on_retry_pressed)

func _on_wave_ended(round_n: int) -> void:
	_is_game_over = false
	title_label.text = "WAVE %d COMPLETE" % round_n
	stats_label.text = "Kills: %d    Tokens: %d    Lifetime: %d" % [GameState.current_score, GameState.tokens, MetaProgress.lifetime_kills]
	next_wave_button.visible = true
	next_wave_button.text = "NEXT WAVE"
	retry_button.visible = true
	retry_button.text = "RESTART"
	_show()

func _on_barrier_destroyed() -> void:
	_is_game_over = true
	title_label.text = "BARRIER BREACHED"
	stats_label.text = "Survived %d waves    Kills: %d    Tokens: %d" % [GameState.current_round, GameState.current_score, GameState.tokens]
	next_wave_button.visible = false
	retry_button.visible = true
	retry_button.text = "RETRY"
	_show()

func _on_run_ended(stats: Dictionary) -> void:
	_is_game_over = true
	if stats.get("victory", false):
		title_label.text = "ALL WAVES SURVIVED"
		stats_label.text = "Kills: %d    Tokens: %d    Lifetime: %d" % [GameState.current_score, GameState.tokens, MetaProgress.lifetime_kills]
	else:
		return  # barrier_destroyed already handled
	next_wave_button.visible = false
	retry_button.visible = true
	retry_button.text = "PLAY AGAIN"
	_show()

func _show() -> void:
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveSystem.save_meta()

func _on_next_wave_pressed() -> void:
	var spawn_ring := get_tree().current_scene.find_child("SpawnRing", true, false)
	if spawn_ring != null and spawn_ring.has_method("start_next_wave"):
		panel.visible = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		spawn_ring.start_next_wave()
	else:
		push_warning("[WaveComplete] SpawnRing not found")

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
