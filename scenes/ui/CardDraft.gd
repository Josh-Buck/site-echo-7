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

func _ready() -> void:
	panel.visible = false
	EventBus.card_offered.connect(_on_card_offered)
	skip_button.pressed.connect(_on_skip_pressed)

func _on_card_offered(cards: Array) -> void:
	if cards.is_empty():
		# No cards to offer — fire card_drafted with null so WaveComplete advances.
		EventBus.card_drafted.emit(null)
		return
	_populate(cards)
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _populate(cards: Array) -> void:
	# Clear existing children
	for c in card_row.get_children():
		c.queue_free()
	for i in cards.size():
		var card: CardData = cards[i]
		var card_button := _make_card_button(card, i)
		card_row.add_child(card_button)

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
	return btn

func _on_card_picked(idx: int) -> void:
	AudioMan.play_sfx("ui_click")
	panel.visible = false
	CardSystem.pick_card(idx)

func _on_skip_pressed() -> void:
	AudioMan.play_sfx("ui_click")
	panel.visible = false
	CardSystem.skip_draft()
