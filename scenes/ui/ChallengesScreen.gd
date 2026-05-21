extends Control

const TIER_COLOR := {
	0: Color(0.85, 0.6, 0.4),     # Bronze
	1: Color(0.75, 0.85, 1.0),    # Silver
	2: Color(1.0, 0.85, 0.35),    # Gold
	3: Color(0.6, 0.95, 1.0),     # Platinum
}

@onready var rd_label: Label = $VBox/RDLabel
@onready var list_box: VBoxContainer = $VBox/ScrollContainer/ChallengeList
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(AudioMan.play_ui_hover)
	_refresh()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	rd_label.text = "Research Data: %d    Completed: %d / %d" % [MetaProgress.research_data, ChallengeTracker.completion_count(), ChallengeTracker.all_challenges().size()]
	for c in list_box.get_children():
		c.queue_free()
	# Sort by tier ascending, then by id for stability.
	var sorted := ChallengeTracker.all_challenges().duplicate()
	sorted.sort_custom(func(a, b):
		if a.tier != b.tier:
			return a.tier < b.tier
		return String(a.id) < String(b.id)
	)
	var current_tier: int = -1
	for cd in sorted:
		if cd.tier != current_tier:
			current_tier = cd.tier
			_add_tier_header(cd.tier)
		_add_challenge_row(cd)

func _add_tier_header(tier: int) -> void:
	var lbl := Label.new()
	lbl.text = "\n— %s tier —" % cd_tier_name(tier).to_upper()
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", TIER_COLOR.get(tier, Color.WHITE))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_box.add_child(lbl)

func cd_tier_name(tier: int) -> String:
	return ["Bronze", "Silver", "Gold", "Platinum"][tier]

func _add_challenge_row(cd: ChallengeData) -> void:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(820, 70)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.09, 0.95)
	sb.border_color = TIER_COLOR.get(cd.tier, Color.WHITE) * 0.7
	sb.border_width_left = 4
	sb.corner_radius_top_left = 3
	sb.corner_radius_bottom_left = 3
	box.add_theme_stylebox_override("panel", sb)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 2)
	box.add_child(inner)

	var top := HBoxContainer.new()
	inner.add_child(top)
	var name_lbl := Label.new()
	name_lbl.text = cd.display_name
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", TIER_COLOR.get(cd.tier, Color.WHITE))
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_lbl)
	var status := Label.new()
	status.text = _status_text(cd)
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", Color(0.7, 0.95, 0.7) if ChallengeTracker.is_completed(cd.id) else Color(0.85, 0.85, 0.85))
	top.add_child(status)

	var desc := Label.new()
	desc.text = cd.description
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(desc)

	list_box.add_child(box)

func _status_text(cd: ChallengeData) -> String:
	if ChallengeTracker.is_completed(cd.id):
		return "✓ COMPLETE   +%d RD" % cd.rd_payout
	# Counter-based challenges show progress.
	var counter_key := _counter_key_for(cd)
	if counter_key != "":
		var cur := ChallengeTracker.get_counter(counter_key)
		return "%d / %d   →  +%d RD" % [cur, cd.target_value, cd.rd_payout]
	# Event-based: just show payout target.
	return "Reward: +%d RD" % cd.rd_payout

func _counter_key_for(cd: ChallengeData) -> String:
	# Mirrors the increments in ChallengeTracker so we can show live counts.
	match String(cd.tracking_kind):
		"kills_total": return "kills_total"
		"headshots_total": return "headshots_total"
		"weapon_kills":
			if cd.weapon_filter != &"":
				return "kills_" + String(cd.weapon_filter)
			return ""
	return ""

func _on_back_pressed() -> void:
	AudioMan.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui/MetaScreen.tscn")
