extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var subtitle_label: Label = $Panel/VBox/SubtitleLabel
@onready var card_row: HBoxContainer = $Panel/VBox/CardRow
@onready var skip_button: Button = $Panel/VBox/SkipButton

const RARITY_COLORS: Array[Color] = [
	Color(0.75, 0.78, 0.85),  # Common — neutral
	Color(0.4, 0.7, 1.0),     # Rare — blue
	Color(1.0, 0.7, 0.2),     # Legendary — gold
	Color(0.85, 0.3, 0.85),   # Curse — purple
]

const RARITY_NAMES: Array[String] = ["COMMON", "RARE", "LEGENDARY", "CURSE"]

# Wave-end buffer: a 1.5s non-interactive beat fires after wave_ended so a
# mid-shoot click can't accidentally skip the draft. After the beat the player
# must explicitly click/press to enable card selection.
const BUFFER_SECONDS: float = 1.5

enum State { HIDDEN, BUFFER, AWAITING_GATE, INTERACTIVE }
var _state: int = State.HIDDEN

# Per-wave accumulators. Reset on wave_started, frozen for display on wave_ended.
var _wave_kills: int = 0
var _wave_headshots: int = 0
var _wave_tokens: int = 0
var _buffer_remaining: float = 0.0

func _ready() -> void:
	panel.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # tick during paused tree
	EventBus.card_offered.connect(_on_card_offered)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.tokens_changed.connect(_on_tokens_changed)
	skip_button.pressed.connect(_on_skip_pressed)
	skip_button.mouse_entered.connect(AudioMan.play_ui_hover)

func _on_wave_started(_round_n: int, _composition: Array) -> void:
	_wave_kills = 0
	_wave_headshots = 0
	_wave_tokens = 0

func _on_wave_ended(_round_n: int) -> void:
	# No-op: _wave_* accumulators stay frozen until the next wave_started,
	# and GameState.current_round still holds the round that just ended.
	pass

func _on_enemy_killed(_enemy: Node, _src: Node, headshot: bool, _pos: Vector3) -> void:
	_wave_kills += 1
	if headshot:
		_wave_headshots += 1

func _on_tokens_changed(_new_total: int, delta: int) -> void:
	if delta > 0:
		_wave_tokens += delta

func _on_card_offered(cards: Array) -> void:
	if cards.is_empty():
		# No cards to offer — fire card_drafted with null so the flow advances.
		EventBus.card_drafted.emit(null)
		return
	_populate(cards)
	_disable_card_buttons()
	_enter_buffer()

func _enter_buffer() -> void:
	_state = State.BUFFER
	_buffer_remaining = BUFFER_SECONDS
	title_label.text = "WAVE %d COMPLETE" % GameState.current_round
	var stats := "Kills %d   Headshots %d   Tokens +%d" % [_wave_kills, _wave_headshots, _wave_tokens]
	subtitle_label.text = stats
	skip_button.visible = false
	skip_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	AudioMan.play_draft_appear()

func _process(delta: float) -> void:
	if _state == State.BUFFER:
		_buffer_remaining -= delta
		if _buffer_remaining <= 0.0:
			_enter_awaiting_gate()

func _enter_awaiting_gate() -> void:
	_state = State.AWAITING_GATE
	subtitle_label.text = "Kills %d   Headshots %d   Tokens +%d\n\nClick or press SPACE to choose a card" % [_wave_kills, _wave_headshots, _wave_tokens]

func _enter_interactive() -> void:
	_state = State.INTERACTIVE
	title_label.text = "RESEARCH NOTES RECOVERED"
	subtitle_label.text = "Pick one to permanently modify your loadout for this run."
	_enable_card_buttons()
	skip_button.visible = true
	skip_button.mouse_filter = Control.MOUSE_FILTER_STOP

func _input(event: InputEvent) -> void:
	if _state != State.AWAITING_GATE:
		return
	var consumed := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		consumed = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			consumed = true
	if consumed:
		get_viewport().set_input_as_handled()
		_enter_interactive()

func _populate(cards: Array) -> void:
	# Clear existing children
	for c in card_row.get_children():
		c.queue_free()
	for i in cards.size():
		var card: CardData = cards[i]
		var card_button := _make_card_button(card, i)
		card_row.add_child(card_button)
		# Stagger flip sounds so multi-card draft has a satisfying cascade.
		var delay := 0.08 * float(i)
		get_tree().create_timer(delay, true, false, true).timeout.connect(AudioMan.play_card_flip)

func _disable_card_buttons() -> void:
	for c in card_row.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
			(c as Control).focus_mode = Control.FOCUS_NONE
			(c as Control).modulate = Color(1, 1, 1, 0.35)

func _enable_card_buttons() -> void:
	for c in card_row.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_STOP
			(c as Control).focus_mode = Control.FOCUS_ALL
			(c as Control).modulate = Color(1, 1, 1, 1)

func _make_card_button(card: CardData, index: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(280, 360)
	btn.theme_override_font_sizes = {}
	btn.clip_text = false
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var name_text := card.display_name
	var rarity_text := RARITY_NAMES[card.rarity] if card.rarity >= 0 and card.rarity < RARITY_NAMES.size() else ""
	var effect_text := card.format_effect_text()
	var lines: Array[String] = []
	lines.append("[" + rarity_text + "]")
	lines.append("")
	lines.append(name_text)
	lines.append("")
	lines.append(card.description)
	if effect_text != "":
		lines.append("")
		lines.append(effect_text)
	btn.text = "\n".join(lines)
	btn.add_theme_font_size_override("font_size", 18)
	var color := RARITY_COLORS[card.rarity] if card.rarity >= 0 and card.rarity < RARITY_COLORS.size() else Color.WHITE
	btn.add_theme_color_override("font_color", color)
	btn.pressed.connect(_on_card_picked.bind(index))
	btn.mouse_entered.connect(AudioMan.play_ui_hover)
	btn.focus_entered.connect(AudioMan.play_ui_hover)
	return btn

func _on_card_picked(idx: int) -> void:
	if _state != State.INTERACTIVE:
		return
	AudioMan.play_ui_confirm()
	_state = State.HIDDEN
	panel.visible = false
	CardSystem.pick_card(idx)

func _on_skip_pressed() -> void:
	if _state != State.INTERACTIVE:
		return
	AudioMan.play_ui_click()
	_state = State.HIDDEN
	panel.visible = false
	CardSystem.skip_draft()
