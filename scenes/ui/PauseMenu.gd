extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var menu_button: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if panel.visible:
			_resume()
		else:
			_show()
		get_viewport().set_input_as_handled()

func _show() -> void:
	panel.visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	AudioMan.play_sfx("ui_click")

func _resume() -> void:
	panel.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	AudioMan.play_sfx("ui_click")

func _on_resume_pressed() -> void:
	_resume()

func _on_menu_pressed() -> void:
	AudioMan.play_sfx("ui_click")
	get_tree().paused = false
	SaveSystem.save_meta()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
