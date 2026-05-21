extends CanvasLayer

# Slide-in toast for challenge completions. Listens on ChallengeTracker.completed,
# queues entries, plays them one at a time so a back-to-back batch doesn't overlap.

const VISIBLE_X: float = 0.0
const OFFSCREEN_X: float = 360.0
const SLIDE_TIME: float = 0.35
const HOLD_TIME: float = 3.0
const FADE_TIME: float = 0.45

@onready var _panel: PanelContainer = $Panel
@onready var _title: Label = $Panel/V/Title
@onready var _name_label: Label = $Panel/V/Name
@onready var _payout: Label = $Panel/V/Payout

var _queue: Array[ChallengeData] = []
var _busy: bool = false

func _ready() -> void:
	# Toast should slide even while card draft / shop / pause have the tree paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_panel.modulate.a = 0.0
	_panel.position.x = OFFSCREEN_X
	ChallengeTracker.completed.connect(_on_completed)

func _on_completed(challenge: ChallengeData) -> void:
	_queue.append(challenge)
	if not _busy:
		_drain()

func _drain() -> void:
	if _queue.is_empty():
		_busy = false
		return
	_busy = true
	var cd: ChallengeData = _queue.pop_front()
	_show_toast(cd)

func _show_toast(cd: ChallengeData) -> void:
	_title.text = "%s CHALLENGE" % cd.tier_name().to_upper()
	_name_label.text = cd.display_name
	_payout.text = "+%d RD" % cd.rd_payout
	_panel.position.x = OFFSCREEN_X
	_panel.modulate.a = 1.0
	AudioMan.play_ui_confirm()

	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_panel, "position:x", VISIBLE_X, SLIDE_TIME)
	tw.tween_interval(HOLD_TIME)
	tw.tween_property(_panel, "modulate:a", 0.0, FADE_TIME)
	tw.tween_callback(_drain)
