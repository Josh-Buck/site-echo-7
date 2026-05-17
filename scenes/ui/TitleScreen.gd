extends Control

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var stats_label: Label = $VBox/StatsLabel
@onready var start_button: Button = $VBox/StartButton
@onready var meta_button: Button = $VBox/MetaButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	start_button.pressed.connect(_on_start_pressed)
	meta_button.pressed.connect(_on_meta_pressed)
	_refresh_stats()
	version_label.text = "v0.2.0 — Site Echo 7"
	print("[TitleScreen] ready, start_button=", start_button)

func _on_meta_pressed() -> void:
	AudioMan.register_first_gesture()
	AudioMan.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/ui/MetaScreen.tscn")

func _refresh_stats() -> void:
	var lines: Array[String] = []
	lines.append("Lifetime stats")
	lines.append("")
	lines.append("Kills:           %d" % MetaProgress.lifetime_kills)
	lines.append("Best Wave:       %d" % MetaProgress.best_round)
	lines.append("Research Data:   %d" % MetaProgress.research_data)
	stats_label.text = "\n".join(lines)

var _starting: bool = false

func _on_start_pressed() -> void:
	if _starting:
		return
	_starting = true
	print("[TitleScreen] start pressed, loading Main.tscn")
	AudioMan.register_first_gesture()
	AudioMan.play_sfx("ui_click")
	GameState.start_run()
	var err := get_tree().change_scene_to_file("res://scenes/Main.tscn")
	if err != OK:
		push_error("[TitleScreen] scene change failed: %d" % err)
		_starting = false
