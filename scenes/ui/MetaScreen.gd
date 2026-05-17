extends Control

const UNLOCKS: Array[Dictionary] = [
	{"id": &"perk_combat_veteran", "name": "Combat Veteran", "desc": "Start each run with +20 tokens.", "cost": 100, "category": "Starter Perks"},
	{"id": &"perk_quick_draft", "name": "Quick Draft", "desc": "First card draft of every run offers 5 cards instead of 3.", "cost": 200, "category": "Starter Perks"},
	{"id": &"perk_quartermaster", "name": "Quartermaster", "desc": "Start each run with 1 random card already drafted.", "cost": 250, "category": "Starter Perks"},
	{"id": &"perk_reinforced_barrier", "name": "Reinforced Barrier", "desc": "Barrier max HP +20% (multiplicative).", "cost": 300, "category": "Starter Perks"},
	{"id": &"barrier_hp_1", "name": "Barrier Plating I", "desc": "Permanent +10 max HP.", "cost": 150, "category": "Barrier Upgrades"},
	{"id": &"barrier_hp_2", "name": "Barrier Plating II", "desc": "Permanent +20 max HP. Stacks with I.", "cost": 400, "category": "Barrier Upgrades"},
	{"id": &"barrier_hp_3", "name": "Barrier Plating III", "desc": "Permanent +30 max HP. Stacks with prior.", "cost": 800, "category": "Barrier Upgrades"},
]

@onready var rd_label: Label = $VBox/RDLabel
@onready var unlock_list: VBoxContainer = $VBox/ScrollContainer/UnlockList
@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	back_button.pressed.connect(_on_back_pressed)
	_refresh()

func _refresh() -> void:
	rd_label.text = "Research Data: %d" % MetaProgress.research_data
	for c in unlock_list.get_children():
		c.queue_free()
	var current_category := ""
	for u in UNLOCKS:
		if u["category"] != current_category:
			current_category = u["category"]
			var header := Label.new()
			header.text = "\n— " + current_category + " —"
			header.add_theme_font_size_override("font_size", 20)
			header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			unlock_list.add_child(header)
		var btn := _make_unlock_button(u)
		unlock_list.add_child(btn)

func _make_unlock_button(u: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(720, 70)
	btn.clip_text = false
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var owned: bool = MetaProgress.has_unlock(u["id"])
	var affordable: bool = MetaProgress.research_data >= int(u["cost"])
	var status := "UNLOCKED" if owned else ("%d RD" % int(u["cost"]))
	btn.text = "%s    [%s]\n%s" % [u["name"], status, u["desc"]]
	btn.add_theme_font_size_override("font_size", 16)
	if owned:
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	elif not affordable:
		btn.disabled = true
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	btn.pressed.connect(_on_unlock_pressed.bind(u))
	return btn

func _on_unlock_pressed(u: Dictionary) -> void:
	if MetaProgress.buy_unlock(u["id"], int(u["cost"])):
		AudioMan.play_sfx("card_pick")
		_refresh()

func _on_back_pressed() -> void:
	AudioMan.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
