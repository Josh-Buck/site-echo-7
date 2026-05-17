class_name WeaponManager extends Node3D

signal weapon_changed(weapon: Weapon)

# Fixed slot layout — index = slot - 1. Locked / unowned weapons leave a null slot
# so the keyboard binding (1/2/3/4) stays consistent regardless of unlock state.
const SLOT_BY_ID := {
	&"pistol_m1": 0,
	&"ar_standard": 1,
	&"shotgun_combat": 2,
	&"sidearm_backup": 3,
}
const SLOT_COUNT := 4

var _slots: Array[Weapon] = []
var _active_index: int = -1

func _ready() -> void:
	_slots.resize(SLOT_COUNT)
	# Place each child weapon into its assigned slot if the player owns it.
	# Locked weapons are freed so the WeaponHolder doesn't carry the cost.
	for child in get_children():
		if child is Weapon:
			var w := child as Weapon
			var id: StringName = w.data.id if w.data != null else &""
			if not SLOT_BY_ID.has(id):
				continue
			if not MetaProgress.has_weapon(String(id)):
				w.queue_free()
				continue
			_slots[SLOT_BY_ID[id]] = w
	# Activate the first non-null slot (Pistol if unlocked, else next available).
	for i in SLOT_COUNT:
		if _slots[i] != null:
			_activate(i)
			return
	push_warning("[WeaponManager] no unlocked weapons in the player kit")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("swap_primary"):
		swap_to(0)
	elif event.is_action_pressed("swap_secondary"):
		swap_to(1)
	elif event.is_action_pressed("swap_tertiary"):
		swap_to(2)
	elif event.is_action_pressed("swap_quaternary"):
		swap_to(3)
	elif event.is_action_pressed("swap_next"):
		swap_next()

func swap_to(index: int) -> void:
	if index < 0 or index >= SLOT_COUNT or index == _active_index:
		return
	if _slots[index] == null:
		return
	_activate(index)

func swap_next() -> void:
	if _owned_count() < 2:
		return
	var i := _active_index
	for _step in SLOT_COUNT:
		i = (i + 1) % SLOT_COUNT
		if _slots[i] != null:
			swap_to(i)
			return

func get_active_weapon() -> Weapon:
	if _active_index >= 0 and _active_index < SLOT_COUNT:
		return _slots[_active_index]
	return null

func _activate(index: int) -> void:
	var old: Weapon = null
	if _active_index >= 0 and _active_index < SLOT_COUNT:
		old = _slots[_active_index]
	_active_index = index
	for i in SLOT_COUNT:
		var w := _slots[i]
		if w == null:
			continue
		w.visible = (i == index)
		w.process_mode = Node.PROCESS_MODE_INHERIT if i == index else Node.PROCESS_MODE_DISABLED
	var new_weapon: Weapon = _slots[index]
	weapon_changed.emit(new_weapon)
	EventBus.weapon_swapped.emit(old, new_weapon)

func _owned_count() -> int:
	var n := 0
	for w in _slots:
		if w != null:
			n += 1
	return n
