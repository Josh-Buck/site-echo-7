extends Control

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var start_button: Button = $VBox/StartButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	start_button.pressed.connect(_on_start_pressed)
	_refresh_stats()
	version_label.text = "v0.2.0 — Site Echo 7"

func _refresh_stats() -> void:
	var lines: Array[String] = []
	lines.append("Lifetime stats")
	lines.append("")
	lines.append("Kills:           %d" % MetaProgress.lifetime_kills)
	lines.append("Best Wave:       %d" % MetaProgress.best_round)
	lines.append("Research Data:   %d" % MetaProgress.research_data)
	stats_label.text = "\n".join(lines)

func _on_start_pressed() -> void:
	# The first interaction is a click — register it for audio gating now.
	AudioMan.register_first_gesture()
	GameState.start_run()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
