extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var retry_button: Button = $Panel/VBox/RetryButton

func _ready() -> void:
	panel.visible = false
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed)
	retry_button.pressed.connect(_on_retry_pressed)

func _on_wave_ended(round_n: int) -> void:
	title_label.text = "WAVE %d COMPLETE" % round_n
	stats_label.text = "Kills: %d    Lifetime: %d" % [GameState.current_score, MetaProgress.lifetime_kills]
	_show()

func _on_barrier_destroyed() -> void:
	title_label.text = "BARRIER BREACHED"
	stats_label.text = "Kills: %d    Lifetime: %d" % [GameState.current_score, MetaProgress.lifetime_kills]
	_show()

func _show() -> void:
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	SaveSystem.save_meta()

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
