extends Control

@onready var stats_box: VBoxContainer = $VBox/ScrollContainer/StatsBox
@onready var back_button: Button = $VBox/BackButton

const WEAPON_LABELS := {
	"pistol_m1": "M1 Pistol",
	"ar_standard": "Assault Rifle",
	"shotgun_combat": "Combat Shotgun",
	"sidearm_backup": "Sidearm",
	"smg_compact": "Compact SMG",
	"bolt_action": "Bolt-Action Rifle",
}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(AudioMan.play_ui_hover)
	_populate()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _populate() -> void:
	for c in stats_box.get_children():
		c.queue_free()

	_add_section("Career")
	_add_row("Runs played", str(MetaProgress.total_runs))
	_add_row("Runs won (cleared the Director)", str(MetaProgress.total_victories))
	_add_row("Best wave reached", str(MetaProgress.best_round))
	_add_row("Research Data — banked", str(MetaProgress.total_rd_earned))
	_add_row("Research Data — current", str(MetaProgress.research_data))

	_add_section("Combat")
	_add_row("Total kills", str(MetaProgress.lifetime_kills))
	_add_row("Lifetime headshots", str(ChallengeTracker.get_counter("headshots_total")))

	_add_section("Per-weapon kills")
	for wid in WEAPON_LABELS.keys():
		var key := "kills_" + wid
		var count := ChallengeTracker.get_counter(key)
		_add_row(WEAPON_LABELS[wid], str(count))

	_add_section("Challenges")
	_add_row("Completed", "%d / %d" % [ChallengeTracker.completion_count(), ChallengeTracker.all_challenges().size()])

func _add_section(title: String) -> void:
	var s := Label.new()
	s.text = "\n— %s —" % title
	s.add_theme_font_size_override("font_size", 22)
	s.add_theme_color_override("font_color", Color(1, 0.85, 0.4, 1))
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_box.add_child(s)

func _add_row(label: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(640, 26)
	var k := Label.new()
	k.text = label
	k.add_theme_font_size_override("font_size", 17)
	k.add_theme_color_override("font_color", Color(0.82, 0.82, 0.86))
	k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(k)
	var v := Label.new()
	v.text = value
	v.add_theme_font_size_override("font_size", 17)
	v.add_theme_color_override("font_color", Color(1, 0.96, 0.7))
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.custom_minimum_size = Vector2(180, 0)
	row.add_child(v)
	stats_box.add_child(row)

func _on_back_pressed() -> void:
	AudioMan.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
