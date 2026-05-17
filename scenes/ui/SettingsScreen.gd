extends Control

@onready var sens_slider: HSlider = $VBox/SensRow/SensSlider
@onready var sens_value_label: Label = $VBox/SensRow/SensValueLabel
@onready var vol_slider: HSlider = $VBox/VolRow/VolSlider
@onready var vol_value_label: Label = $VBox/VolRow/VolValueLabel
@onready var back_button: Button = $VBox/BackButton

const DEFAULT_SENS: float = 0.002
const SENS_MIN: float = 0.0005
const SENS_MAX: float = 0.006

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	sens_slider.min_value = SENS_MIN
	sens_slider.max_value = SENS_MAX
	sens_slider.step = 0.0001
	sens_slider.value = float(MetaProgress.get_setting("mouse_sensitivity", DEFAULT_SENS))
	_update_sens_label()
	vol_slider.min_value = 0.0
	vol_slider.max_value = 1.0
	vol_slider.step = 0.05
	vol_slider.value = float(MetaProgress.get_setting("master_volume", 1.0))
	_update_vol_label()
	sens_slider.value_changed.connect(_on_sens_changed)
	vol_slider.value_changed.connect(_on_vol_changed)
	back_button.pressed.connect(_on_back_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _on_sens_changed(v: float) -> void:
	MetaProgress.set_setting("mouse_sensitivity", v)
	_update_sens_label()

func _on_vol_changed(v: float) -> void:
	MetaProgress.set_setting("master_volume", v)
	AudioMan.set_master_volume(v)
	_update_vol_label()

func _update_sens_label() -> void:
	sens_value_label.text = "%.4f" % sens_slider.value

func _update_vol_label() -> void:
	vol_value_label.text = "%d%%" % int(round(vol_slider.value * 100.0))

func _on_back_pressed() -> void:
	AudioMan.play_sfx("ui_click")
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
