extends Control

@onready var sens_slider: HSlider = $VBox/SensRow/SensSlider
@onready var sens_value_label: Label = $VBox/SensRow/SensValueLabel
@onready var fov_slider: HSlider = $VBox/FovRow/FovSlider
@onready var fov_value_label: Label = $VBox/FovRow/FovValueLabel
@onready var vol_slider: HSlider = $VBox/MasterRow/VolSlider
@onready var vol_value_label: Label = $VBox/MasterRow/VolValueLabel
@onready var sfx_slider: HSlider = $VBox/SfxRow/SfxSlider
@onready var sfx_value_label: Label = $VBox/SfxRow/SfxValueLabel
@onready var music_slider: HSlider = $VBox/MusicRow/MusicSlider
@onready var music_value_label: Label = $VBox/MusicRow/MusicValueLabel
@onready var gore_button: CheckButton = $VBox/GoreRow/GoreButton
@onready var fullscreen_button: CheckButton = $VBox/FullscreenRow/FullscreenButton
@onready var back_button: Button = $VBox/BackButton

const DEFAULT_SENS: float = 0.002
const SENS_MIN: float = 0.0005
const SENS_MAX: float = 0.006
const DEFAULT_FOV: float = 75.0
const FOV_MIN: float = 60.0
const FOV_MAX: float = 110.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	sens_slider.min_value = SENS_MIN
	sens_slider.max_value = SENS_MAX
	sens_slider.step = 0.0001
	sens_slider.value = float(MetaProgress.get_setting("mouse_sensitivity", DEFAULT_SENS))
	_update_sens_label()

	fov_slider.min_value = FOV_MIN
	fov_slider.max_value = FOV_MAX
	fov_slider.step = 1.0
	fov_slider.value = float(MetaProgress.get_setting("fov", DEFAULT_FOV))
	_update_fov_label()

	_init_volume_slider(vol_slider, vol_value_label, "master_volume", 1.0)
	_init_volume_slider(sfx_slider, sfx_value_label, "sfx_volume", 1.0)
	_init_volume_slider(music_slider, music_value_label, "music_volume", 1.0)

	gore_button.button_pressed = bool(MetaProgress.get_setting("gore_enabled", true))
	gore_button.text = "ON" if gore_button.button_pressed else "OFF"

	fullscreen_button.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_button.text = "ON" if fullscreen_button.button_pressed else "OFF"

	sens_slider.value_changed.connect(_on_sens_changed)
	fov_slider.value_changed.connect(_on_fov_changed)
	vol_slider.value_changed.connect(_on_master_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	music_slider.value_changed.connect(_on_music_changed)
	gore_button.toggled.connect(_on_gore_toggled)
	fullscreen_button.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(AudioMan.play_ui_hover)

	# Apply audio bus volumes from persisted settings on entry.
	_apply_bus_volume("SFX", float(MetaProgress.get_setting("sfx_volume", 1.0)))
	_apply_bus_volume("Music", float(MetaProgress.get_setting("music_volume", 1.0)))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()

func _init_volume_slider(slider: HSlider, label: Label, key: String, default_value: float) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = float(MetaProgress.get_setting(key, default_value))
	label.text = "%d%%" % int(round(slider.value * 100.0))

func _on_sens_changed(v: float) -> void:
	MetaProgress.set_setting("mouse_sensitivity", v)
	_update_sens_label()

func _on_fov_changed(v: float) -> void:
	MetaProgress.set_setting("fov", v)
	_update_fov_label()
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		cam.fov = v

func _on_master_changed(v: float) -> void:
	MetaProgress.set_setting("master_volume", v)
	AudioMan.set_master_volume(v)
	vol_value_label.text = "%d%%" % int(round(v * 100.0))

func _on_sfx_changed(v: float) -> void:
	MetaProgress.set_setting("sfx_volume", v)
	_apply_bus_volume("SFX", v)
	sfx_value_label.text = "%d%%" % int(round(v * 100.0))

func _on_music_changed(v: float) -> void:
	MetaProgress.set_setting("music_volume", v)
	_apply_bus_volume("Music", v)
	music_value_label.text = "%d%%" % int(round(v * 100.0))

func _apply_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	linear = clamp(linear, 0.0, 1.0)
	if linear <= 0.0001:
		AudioServer.set_bus_mute(idx, true)
		return
	AudioServer.set_bus_mute(idx, false)
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))

func _on_gore_toggled(pressed: bool) -> void:
	MetaProgress.set_setting("gore_enabled", pressed)
	gore_button.text = "ON" if pressed else "OFF"

func _on_fullscreen_toggled(pressed: bool) -> void:
	# The click itself is a user gesture — required on the web for fullscreen.
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	fullscreen_button.text = "ON" if pressed else "OFF"

func _update_sens_label() -> void:
	sens_value_label.text = "%.4f" % sens_slider.value

func _update_fov_label() -> void:
	fov_value_label.text = "%d" % int(round(fov_slider.value))

func _on_back_pressed() -> void:
	AudioMan.play_ui_click()
	get_tree().change_scene_to_file("res://scenes/ui/TitleScreen.tscn")
