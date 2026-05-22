extends CanvasLayer

# 10-second skippable opening shown on first wave of a new run.
# Sells the Site Echo-7 fiction in a few sentence beats.

@onready var panel: ColorRect = $Background
@onready var line_label: Label = $VBox/LineLabel
@onready var skip_hint: Label = $VBox/SkipHint

const LINES := [
	"  Two hours after containment failure...",
	"      Subject 23 made it to the cooling tower.",
	"   The Director is somewhere in the dark with him.",
	"  Observation ring secured. Stand. Spin. Survive.",
]

const FADE_IN: float = 0.35
const PER_LINE: float = 2.4
const FADE_OUT: float = 0.45

var _done: bool = false
var _t: float = 0.0
var _line_idx: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # survive any incidental pause
	layer = 50
	panel.color = Color(0, 0, 0, 1)
	line_label.modulate.a = 0.0
	skip_hint.modulate.a = 0.0
	skip_hint.text = "click / space to skip"
	_show_next_line()
	var hint_tw := create_tween()
	hint_tw.tween_property(skip_hint, "modulate:a", 0.7, 0.8)

func _input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_ESCAPE:
			_finish()

func _show_next_line() -> void:
	if _line_idx >= LINES.size():
		_finish()
		return
	line_label.text = LINES[_line_idx]
	_line_idx += 1
	var tw := create_tween()
	tw.tween_property(line_label, "modulate:a", 1.0, FADE_IN)
	tw.tween_interval(PER_LINE)
	tw.tween_property(line_label, "modulate:a", 0.0, FADE_OUT)
	tw.tween_callback(_show_next_line)

func _finish() -> void:
	if _done:
		return
	_done = true
	var tw := create_tween()
	tw.tween_property(panel, "color:a", 0.0, 0.35)
	tw.tween_property(line_label, "modulate:a", 0.0, 0.05)
	tw.tween_property(skip_hint, "modulate:a", 0.0, 0.05)
	tw.tween_callback(queue_free)
