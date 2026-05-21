extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var menu_button: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	resume_button.mouse_entered.connect(AudioMan.play_ui_hover)
	menu_button.mouse_entered.connect(AudioMan.play_ui_hover)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if panel.visible:
			_resume()
		elif _other_overlay_visible():
			# Another between-wave UI (card draft / shop / wave complete / death) owns
			# the pause state. Don't double-pause + don't grab mouse from them.
			get_viewport().set_input_as_handled()
			return
		else:
			_show()
		get_viewport().set_input_as_handled()

func _other_overlay_visible() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	for name in ["CardDraft", "Shop", "WaveComplete", "DeathScreen"]:
		var ui := scene.get_node_or_null(name)
		if ui == null:
			continue
		var p := ui.get_node_or_null("Panel")
		if p is CanvasItem and (p as CanvasItem).visible:
			return true
	return false

func _show() -> void:
	panel.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	AudioMan.play_ui_click()

func _resume() -> void:
	panel.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	AudioMan.play_ui_click()

func _on_resume_pressed() -> void:
	_resume()

func _on_menu_pressed() -> void:
	AudioMan.play_ui_click()
	get_tree().paused = false
	SaveSystem.save_meta()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
