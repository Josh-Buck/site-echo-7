extends Control

# Run modifier toggle screen. Toggles persist in MetaProgress.settings.active_modifiers
# and are read by GameState.start_run() on each new run.

@onready var no_shop_button: CheckButton = $VBox/NoShopRow/NoShopButton
@onready var no_cards_button: CheckButton = $VBox/NoCardsRow/NoCardsButton
@onready var locked_weapon_button: CheckButton = $VBox/LockedWeaponRow/LockedWeaponButton
@onready var double_spawn_button: CheckButton = $VBox/DoubleSpawnRow/DoubleSpawnButton
@onready var back_button: Button = $VBox/BackButton

const ROWS := {
	&"no_shop":        "no_shop_button",
	&"no_cards":       "no_cards_button",
	&"locked_weapon":  "locked_weapon_button",
	&"double_spawn":   "double_spawn_button",
}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var active := _load_active()
	for mod_id in ROWS.keys():
		var btn: CheckButton = get(ROWS[mod_id])
		if btn == null:
			continue
		btn.button_pressed = mod_id in active
		btn.text = "ON" if btn.button_pressed else "OFF"
		btn.toggled.connect(_make_toggle_handler(mod_id, btn))
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(AudioMan.play_ui_hover)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _load_active() -> Array:
	var saved: Variant = MetaProgress.get_setting("active_modifiers", [])
	if saved is Array:
		var out: Array = []
		for m in saved:
			out.append(StringName(m))
		return out
	return []

func _save_active(active: Array) -> void:
	var out: Array = []
	for m in active:
		out.append(String(m))
	MetaProgress.set_setting("active_modifiers", out)

func _make_toggle_handler(mod_id: StringName, btn: CheckButton) -> Callable:
	return func(pressed: bool):
		var active := _load_active()
		if pressed and not (mod_id in active):
			active.append(mod_id)
		elif not pressed and (mod_id in active):
			active.erase(mod_id)
		_save_active(active)
		btn.text = "ON" if pressed else "OFF"

func _on_back_pressed() -> void:
	AudioMan.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
