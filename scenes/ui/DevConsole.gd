extends CanvasLayer

# Lightweight dev console. Tilde (~) opens a textbox that accepts a few
# debug commands so we can test mid-game without grinding through waves.
# Not gated to dev builds — players can use it, but no in-game economy
# tracks know about it (challenges still earn normally).

@onready var panel: PanelContainer = $Panel
@onready var input: LineEdit = $Panel/V/Input
@onready var log_label: Label = $Panel/V/Log

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 60
	panel.visible = false
	input.text_submitted.connect(_on_submit)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_ASCIITILDE:
			_toggle()
			get_viewport().set_input_as_handled()
		elif panel.visible and event.keycode == KEY_ESCAPE:
			_hide()
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	if panel.visible:
		_hide()
	else:
		_show()

func _show() -> void:
	panel.visible = true
	input.clear()
	input.grab_focus()

func _hide() -> void:
	panel.visible = false
	input.release_focus()

func _on_submit(text: String) -> void:
	var trimmed: String = text.strip_edges()
	if trimmed.is_empty():
		return
	log_label.text = "> " + trimmed
	input.clear()
	_exec(trimmed)

func _exec(cmd: String) -> void:
	var parts: PackedStringArray = cmd.split(" ", false)
	if parts.is_empty():
		return
	var op: String = parts[0].to_lower()
	match op:
		"help":
			log_label.text = "tokens N | rd N | hp N | skip N | wave N | kill | god | unlock <id> | quit | help"
		"tokens":
			var n: int = int(parts[1]) if parts.size() > 1 else 100
			GameState.tokens += n
			EventBus.tokens_changed.emit(GameState.tokens, n)
			log_label.text = "+%d tokens (total %d)" % [n, GameState.tokens]
		"rd":
			var n: int = int(parts[1]) if parts.size() > 1 else 100
			MetaProgress.research_data += n
			SaveSystem.save_meta()
			log_label.text = "+%d RD (total %d)" % [n, MetaProgress.research_data]
		"hp":
			var n: float = float(parts[1]) if parts.size() > 1 else 100.0
			var b := get_tree().get_first_node_in_group("barriers")
			if b and b.has_method("repair"):
				b.repair(n)
				log_label.text = "barrier +%.0f hp" % n
		"kill":
			var killed: int = 0
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.has_method("take_damage"):
					z.take_damage(99999.0, null, false, z.global_position)
					killed += 1
			log_label.text = "killed %d zombies" % killed
		"god":
			var b2 := get_tree().get_first_node_in_group("barriers")
			if b2 and b2.has_method("bump_max_hp"):
				b2.bump_max_hp(9000.0)
				log_label.text = "barrier +9000 max hp (god mode)"
		"unlock":
			if parts.size() < 2:
				log_label.text = "usage: unlock <id>"
				return
			MetaProgress.unlocks[StringName(parts[1])] = true
			SaveSystem.save_meta()
			log_label.text = "unlocked %s" % parts[1]
		"wave", "skip":
			var n: int = int(parts[1]) if parts.size() > 1 else GameState.current_round + 1
			# End the current wave so the between-wave UI advances. Then fast-forward
			# the SpawnRing's index. Skipping forward only — going backward not supported.
			var ring := get_tree().current_scene.find_child("SpawnRing", true, false)
			if ring == null:
				log_label.text = "no spawn ring"
				return
			ring.set("_current_wave_index", clamp(n - 2, -1, 19))
			# Kill all zombies + emit wave_ended.
			for z in get_tree().get_nodes_in_group("zombies"):
				if z.has_method("queue_free"):
					z.queue_free()
			EventBus.wave_ended.emit(GameState.current_round)
			log_label.text = "next wave will be %d" % n
		"quit":
			_hide()
		_:
			log_label.text = "unknown: %s. type 'help'." % op
