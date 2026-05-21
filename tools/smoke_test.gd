extends Node

# Headless smoke test. Loads Main, then drives the game through the wave-end flow
# without WebGL / mouse input. Verifies the UI signals and pause-state machine
# in code instead of asking the user to click through it.

var _step: int = 0
var _failures: Array[String] = []

var _main_root: Node = null

func _ready() -> void:
	print("[smoke] starting smoke test")
	# Re-parent ourselves to root so we survive scene changes.
	# Instead of change_scene_to_file (which would free us), instantiate Main
	# as a child so both stay alive.
	var main_scene := load("res://scenes/Main.tscn") as PackedScene
	if main_scene == null:
		_fail("could not load Main.tscn")
		_done()
		return
	_main_root = main_scene.instantiate()
	get_tree().root.add_child.call_deferred(_main_root)
	# Make our Main pretend to be the current_scene for find_child / get_tree().current_scene.
	# Without this, signal handlers that key off current_scene won't find the Main subtree.
	await get_tree().process_frame
	await get_tree().process_frame
	await _wait(0.8)
	_run()

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout

func _fail(msg: String) -> void:
	_failures.append(msg)
	push_error("[smoke FAIL] " + msg)

func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("[smoke PASS] " + msg)
	else:
		_fail(msg)

func _run() -> void:
	# Step 1: Main loaded? Autoloads ready?
	_expect(GameState.run_active, "GameState.run_active after Main loads")
	_expect(GameState.current_round == 1, "GameState.current_round == 1")
	_expect(CardSystem.available_pool.size() >= 30, "CardSystem starter pool >= 30 cards (got %d)" % CardSystem.available_pool.size())
	_expect(ChallengeTracker.all_challenges().size() >= 25, "ChallengeTracker challenges >= 25 (got %d)" % ChallengeTracker.all_challenges().size())

	# Step 2: Find the UI overlays in the main scene (the Main subtree we added).
	var scene: Node = _main_root
	_expect(scene != null, "Main subtree is not null")
	if scene == null:
		_done()
		return
	var card_draft := scene.get_node_or_null("CardDraft")
	var shop := scene.get_node_or_null("Shop")
	var wave_complete := scene.get_node_or_null("WaveComplete")
	var pause_menu := scene.get_node_or_null("PauseMenu")
	var hud := scene.get_node_or_null("HUD")
	var death := scene.get_node_or_null("DeathScreen")
	_expect(card_draft != null, "CardDraft overlay exists")
	_expect(shop != null, "Shop overlay exists")
	_expect(wave_complete != null, "WaveComplete overlay exists")
	_expect(pause_menu != null, "PauseMenu overlay exists")
	_expect(hud != null, "HUD overlay exists")
	_expect(death != null, "DeathScreen overlay exists")
	# Step 3: Player and barrier and weapons exist.
	var player := scene.find_child("Player", true, false)
	var barriers := get_tree().get_nodes_in_group("barriers")
	_expect(player != null, "Player node exists in scene")
	_expect(barriers.size() == 1, "Exactly one barrier in barriers group (got %d)" % barriers.size())
	var wm := scene.find_child("WeaponHolder", true, false)
	_expect(wm is WeaponManager, "WeaponHolder is a WeaponManager")
	var active_weapon: Weapon = null
	if wm is WeaponManager:
		active_weapon = (wm as WeaponManager).get_active_weapon()
	_expect(active_weapon != null, "Player has an active weapon at start")
	if active_weapon != null:
		_expect(active_weapon.data != null, "Active weapon has data assigned")
		_expect(active_weapon.current_ammo > 0, "Active weapon has ammo loaded (got %d)" % active_weapon.current_ammo)

	# Step 4: Verify Shop is NOT open at run start (Quartermaster perk bug regression test).
	if shop != null:
		var shop_panel := shop.get_node_or_null("Panel")
		if shop_panel is CanvasItem:
			_expect(not (shop_panel as CanvasItem).visible, "Shop panel NOT visible at run start (Quartermaster bug regression)")

	# Step 5: Drive the wave-end flow. Force wave_ended → CardDraft should appear.
	print("[smoke] forcing wave_ended for round 1")
	EventBus.wave_ended.emit(1)
	await _wait(0.2)
	if card_draft != null:
		var cd_panel := card_draft.get_node_or_null("Panel")
		_expect(cd_panel is CanvasItem and (cd_panel as CanvasItem).visible, "CardDraft panel visible after wave_ended")

	# Step 6: Skip the draft → Shop should open.
	print("[smoke] skipping draft")
	CardSystem.skip_draft()
	await _wait(0.2)
	if shop != null:
		var shop_panel2 := shop.get_node_or_null("Panel")
		_expect(shop_panel2 is CanvasItem and (shop_panel2 as CanvasItem).visible, "Shop panel visible after card draft skipped")
		_expect(get_tree().paused, "Tree is paused while Shop is open")

	# Step 7: Close shop → WaveComplete should appear.
	print("[smoke] emitting shop_done")
	# Reset shop's _allow_open by directly hiding its panel and firing shop_done.
	if shop != null:
		var sp := shop.get_node_or_null("Panel")
		if sp is CanvasItem:
			(sp as CanvasItem).visible = false
	EventBus.shop_done.emit()
	await _wait(0.2)
	if wave_complete != null:
		var wc_panel := wave_complete.get_node_or_null("Panel")
		_expect(wc_panel is CanvasItem and (wc_panel as CanvasItem).visible, "WaveComplete panel visible after shop_done")

	# Step 8: Synth-test a few audio paths.
	_expect(AudioServer.get_bus_index("Master") >= 0, "Master audio bus exists")
	_expect(AudioServer.get_bus_index("SFX") >= 0, "SFX audio bus exists")
	_expect(AudioServer.get_bus_index("Music") >= 0, "Music audio bus exists")

	# Step 9: Verify boss waves reference boss enemies.
	var ring := scene.find_child("SpawnRing", true, false)
	if ring != null and "waves" in ring:
		var waves: Array = ring.waves
		_expect(waves.size() >= 20, "SpawnRing has at least 20 waves (got %d)" % waves.size())
		if waves.size() >= 20:
			var w10: WaveData = waves[9]
			var w20: WaveData = waves[19]
			var has_subject := false
			var has_director := false
			for e in w10.composition:
				if e is EnemyData and (e as EnemyData).id == &"subject":
					has_subject = true
					break
			for e in w20.composition:
				if e is EnemyData and (e as EnemyData).id == &"director":
					has_director = true
					break
			_expect(has_subject, "Wave 10 contains Subject boss")
			_expect(has_director, "Wave 20 contains Director boss")

	_done()

func _done() -> void:
	print("[smoke] -------- RESULTS --------")
	if _failures.is_empty():
		print("[smoke] ALL CHECKS PASSED")
	else:
		print("[smoke] %d FAILURES:" % _failures.size())
		for f in _failures:
			print("  ✗ " + f)
	get_tree().quit(0 if _failures.is_empty() else 1)
