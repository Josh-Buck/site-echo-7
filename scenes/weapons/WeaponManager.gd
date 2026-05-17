class_name WeaponManager extends Node3D

signal weapon_changed(weapon: Weapon)

var _weapons: Array[Weapon] = []
var _active_index: int = 0

func _ready() -> void:
	for child in get_children():
		if child is Weapon:
			_weapons.append(child)
	if _weapons.is_empty():
		push_warning("[WeaponManager] no weapons found as children")
		return
	_activate(0)

func _unhandled_input(event: InputEvent) -> void:
	if _weapons.size() < 2:
		return
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
	if index < 0 or index >= _weapons.size() or index == _active_index:
		return
	_activate(index)

func swap_next() -> void:
	if _weapons.size() < 2:
		return
	swap_to((_active_index + 1) % _weapons.size())

func get_active_weapon() -> Weapon:
	if _active_index >= 0 and _active_index < _weapons.size():
		return _weapons[_active_index]
	return null

func _activate(index: int) -> void:
	var old: Weapon = _weapons[_active_index] if _active_index < _weapons.size() else null
	_active_index = index
	for i in _weapons.size():
		var w := _weapons[i]
		w.visible = (i == index)
		w.process_mode = Node.PROCESS_MODE_INHERIT if i == index else Node.PROCESS_MODE_DISABLED
	var new_weapon: Weapon = _weapons[index]
	weapon_changed.emit(new_weapon)
	EventBus.weapon_swapped.emit(old, new_weapon)
