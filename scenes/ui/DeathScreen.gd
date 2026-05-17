extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var subtitle_label: Label = $Panel/Margin/VBox/SubtitleLabel
@onready var stats_grid: GridContainer = $Panel/Margin/VBox/StatsGrid
@onready var kills_label: Label = $Panel/Margin/VBox/KillsLabel
@onready var cards_label: Label = $Panel/Margin/VBox/CardsLabel
@onready var rd_label: Label = $Panel/Margin/VBox/RDLabel
@onready var bank_button: Button = $Panel/Margin/VBox/BankButton

var _shown: bool = false

func _ready() -> void:
	panel.visible = false
	EventBus.barrier_destroyed.connect(_on_barrier_destroyed)
	EventBus.run_ended.connect(_on_run_ended)
	bank_button.pressed.connect(_on_bank_pressed)
	bank_button.mouse_entered.connect(AudioMan.play_ui_hover)

func _on_barrier_destroyed() -> void:
	_present(false)

func _on_run_ended(stats: Dictionary) -> void:
	# Victory path uses the same screen.
	if stats.get("victory", false):
		_present(true)

func _present(victory: bool) -> void:
	if _shown:
		return
	_shown = true
	var rounds := GameState.current_round
	var kills := GameState.current_score
	var tokens_left := GameState.tokens
	var tokens_earned := GameState.tokens_earned_this_run
	var rd_earned := GameState.compute_rd_payout()

	if victory:
		title_label.text = "SITE ECHO 7 CONTAINED"
		subtitle_label.text = "All waves survived. The Director is down."
	else:
		title_label.text = "BARRIER BREACHED"
		subtitle_label.text = "Site Echo 7 lost containment."

	_populate_stats_grid(rounds, kills, tokens_earned, tokens_left)
	kills_label.text = _format_kills_by_type()
	cards_label.text = _format_top_cards()
	rd_label.text = "Banking +%d RD into archive..." % rd_earned

	bank_button.text = "BANK & RETURN TO TITLE"
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true

	# Bank RD now so the value shown matches what's persisted.
	MetaProgress.record_run_end()
	SaveSystem.save_meta()
	_animate_in(rd_earned)

func _populate_stats_grid(rounds: int, kills: int, earned: int, leftover: int) -> void:
	for child in stats_grid.get_children():
		child.queue_free()
	_add_stat_row("Rounds Survived", str(rounds))
	_add_stat_row("Total Kills", str(kills))
	_add_stat_row("Tokens Earned", str(earned))
	_add_stat_row("Tokens Unspent", str(leftover))

func _add_stat_row(label_text: String, value_text: String) -> void:
	var k := Label.new()
	k.text = label_text
	k.add_theme_font_size_override("font_size", 20)
	k.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
	stats_grid.add_child(k)
	var v := Label.new()
	v.text = value_text
	v.add_theme_font_size_override("font_size", 22)
	v.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_grid.add_child(v)

func _format_kills_by_type() -> String:
	var entries: Array = []
	for k in GameState.kills_by_type.keys():
		entries.append({"name": String(k), "count": int(GameState.kills_by_type[k])})
	if entries.is_empty():
		return "Kills by type:  (none)"
	entries.sort_custom(func(a, b): return a["count"] > b["count"])
	var parts: Array[String] = []
	for e in entries:
		parts.append("%s ×%d" % [e["name"], e["count"]])
	return "Kills by type:  " + "    ".join(parts)

func _format_top_cards() -> String:
	var top: Array = GameState.get_top_cards(3)
	if top.is_empty():
		return "Top cards:  (no cards drafted)"
	var parts: Array[String] = []
	for e in top:
		parts.append("%s" % e["name"])
	return "Top cards:  " + "  ·  ".join(parts)

func _animate_in(rd_earned: int) -> void:
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "modulate:a", 1.0, 0.45)
	# RD count-up flourish.
	var count_tw := create_tween()
	count_tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	count_tw.tween_interval(0.5)
	var step_count := 24
	for i in range(1, step_count + 1):
		var v := int(round(float(rd_earned) * float(i) / float(step_count)))
		count_tw.tween_callback(func(): rd_label.text = "Research Data banked:  +%d RD" % v)
		count_tw.tween_interval(0.025)

func _on_bank_pressed() -> void:
	AudioMan.play_ui_click()
	get_tree().paused = false
	SaveSystem.save_meta()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
