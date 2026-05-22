extends CanvasLayer

# Targeted upgrade shop. Lists every card not already in the active deck with a
# token cost based on rarity. Player saves tokens across waves and spends them
# here for guaranteed picks — more expensive than the random draft, but you get
# what you want.

const COSTS_BY_RARITY := [100, 175, 280, 80]  # Common / Rare / Legendary / Curse
const RARITY_NAMES := ["COMMON", "RARE", "LEGENDARY", "CURSE"]
const RARITY_COLORS := [
	Color(0.75, 0.78, 0.85),
	Color(0.4, 0.7, 1.0),
	Color(1.0, 0.7, 0.2),
	Color(0.85, 0.3, 0.85),
]

@onready var panel: PanelContainer = $Panel
@onready var tokens_label: Label = $Panel/V/Header/TokensLabel
@onready var card_list: VBoxContainer = $Panel/V/Scroll/CardList
@onready var close_button: Button = $Panel/V/Footer/CloseButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	panel.visible = false
	close_button.pressed.connect(_on_close)
	close_button.mouse_entered.connect(AudioMan.play_ui_hover)
	EventBus.tokens_changed.connect(_on_tokens_changed)

func open() -> void:
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	_refresh()

func _input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if event.is_action_pressed("pause"):
		_on_close()
		get_viewport().set_input_as_handled()

func _on_tokens_changed(_new_total: int, _delta: int) -> void:
	if not panel.visible:
		return
	_refresh()

func _refresh() -> void:
	tokens_label.text = "Tokens Available: %d" % GameState.tokens
	for c in card_list.get_children():
		c.queue_free()
	# Sort the pool by rarity then name.
	var pool: Array[CardData] = []
	for card in CardSystem.available_pool:
		if card in CardSystem.active_deck:
			continue
		pool.append(card)
	pool.sort_custom(func(a, b):
		if a.rarity != b.rarity:
			return a.rarity < b.rarity
		return String(a.display_name) < String(b.display_name)
	)
	for card in pool:
		card_list.add_child(_make_row(card))

func _cost(card: CardData) -> int:
	var idx: int = clamp(card.rarity, 0, COSTS_BY_RARITY.size() - 1)
	return COSTS_BY_RARITY[idx]

func _make_row(card: CardData) -> Control:
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(0, 90)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.1, 0.94)
	sb.border_color = RARITY_COLORS[clamp(card.rarity, 0, 3)] * 0.7
	sb.border_width_left = 4
	row.add_theme_stylebox_override("panel", sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	row.add_child(hb)
	# Left side: name + description.
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(vb)
	var name_lbl := Label.new()
	name_lbl.text = "%s  ·  %s" % [RARITY_NAMES[clamp(card.rarity, 0, 3)], card.display_name]
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", RARITY_COLORS[clamp(card.rarity, 0, 3)])
	vb.add_child(name_lbl)
	var desc_lbl := Label.new()
	desc_lbl.text = card.description
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.78, 0.82))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.custom_minimum_size = Vector2(420, 0)
	vb.add_child(desc_lbl)
	var effect_text := card.format_effect_text()
	if effect_text != "":
		var fx := Label.new()
		fx.text = effect_text
		fx.add_theme_font_size_override("font_size", 12)
		fx.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
		vb.add_child(fx)
	# Right side: buy button + cost.
	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(180, 60)
	var cost := _cost(card)
	buy_btn.text = "BUY  ·  %d tokens" % cost
	buy_btn.add_theme_font_size_override("font_size", 16)
	buy_btn.disabled = GameState.tokens < cost
	buy_btn.pressed.connect(_on_buy.bind(card, cost, buy_btn))
	buy_btn.mouse_entered.connect(AudioMan.play_ui_hover)
	hb.add_child(buy_btn)
	return row

func _on_buy(card: CardData, cost: int, btn: Button) -> void:
	if GameState.tokens < cost:
		return
	AudioMan.play_ui_confirm()
	GameState.tokens -= cost
	EventBus.tokens_changed.emit(GameState.tokens, -cost)
	CardSystem.active_deck.append(card)
	CardSystem.card_added_local.emit(card)
	EventBus.card_drafted.emit(card)
	btn.disabled = true
	btn.text = "OWNED"
	_refresh()

func _on_close() -> void:
	AudioMan.play_ui_click()
	panel.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
