extends Control

@onready var back_button: Button = $VBox/BackButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(AudioMan.play_ui_hover)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _on_back_pressed() -> void:
	AudioMan.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
