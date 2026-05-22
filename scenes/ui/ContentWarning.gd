extends Control

# Brief content-warning splash shown once on first launch. Lists what the
# game contains (mild horror imagery, zombie violence, no gore by default
# since Gore Effects defaults on with a toggle in Settings) and offers a
# single ACKNOWLEDGE button to dismiss + persist.

@onready var ack_button: Button = $VBox/AckButton

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	ack_button.pressed.connect(_on_ack)
	ack_button.mouse_entered.connect(AudioMan.play_ui_hover)

func _on_ack() -> void:
	MetaProgress.set_setting("content_warning_acked", true)
	AudioMan.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
