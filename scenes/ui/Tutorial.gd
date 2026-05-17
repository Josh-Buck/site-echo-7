extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var hint_label: Label = $Panel/Margin/HintLabel

const FADE_AFTER_KILLS: int = 5
const FADE_AFTER_SECONDS: float = 25.0

var _kills: int = 0
var _elapsed: float = 0.0
var _dismissing: bool = false

func _ready() -> void:
	if MetaProgress.get_setting("tutorial_done", false):
		queue_free()
		return
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.6)
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _process(delta: float) -> void:
	if _dismissing:
		return
	_elapsed += delta
	if _elapsed >= FADE_AFTER_SECONDS:
		_dismiss()

func _on_enemy_killed(_enemy: Node, _src: Node, _hs: bool, _pos: Vector3) -> void:
	_kills += 1
	if _kills >= FADE_AFTER_KILLS:
		_dismiss()

func _dismiss() -> void:
	if _dismissing:
		return
	_dismissing = true
	MetaProgress.set_setting("tutorial_done", true)
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)
