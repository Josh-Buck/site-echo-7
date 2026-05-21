# Codebase map — Site Echo 7

Quick-reference for "where does X live." Skim before changing anything; update when adding new systems.

Counts current as of latest audit: ~30 .gd files, ~4,400 LOC, ~110 .tres data files.

---

## Boot flow

1. Browser loads → `project.godot` main scene = `res://scenes/ui/TitleScreen.tscn`
2. Autoloads init (order from project.godot):
   1. `GameState` — current-run state (round, score, tokens)
   2. `MetaProgress` — persistent unlocks, lifetime stats, settings
   3. `EventBus` — signal hub (declare all signals here)
   4. `AudioMan` — synth + sample SFX, bus routing
   5. `SaveSystem` — `user://meta.save` (IndexedDB on web)
   6. `CardSystem` — active deck, draft pool, effect mutation
   7. `ChallengeTracker` — achievement progress + RD payouts
3. TitleScreen.tscn → user clicks START RUN → `Main.tscn` loads → Arena loads → SpawnRing starts wave 1

---

## Autoloads (`autoload/`)

| File | Role | Key API |
|---|---|---|
| `GameState.gd` | Per-run state. Reset on death. | `start_run()`, `end_run()`, vars: `current_round`, `current_score`, `tokens` |
| `MetaProgress.gd` | Persistent. Saves to user://. | `has_unlock(id)`, `buy_unlock(id, cost)`, `has_weapon(id)`, `get_fov()`, `get_setting/set_setting`, `gore_enabled()`, `record_run_end()` |
| `EventBus.gd` | All cross-system signals declared here. | See signal vocabulary below |
| `AudioMan.gd` | Procedural synth + loaded streams. SFX bus. | `play_sfx(id, pos?)`, `play_2d`, `play_3d_at`, `play_ui_click/hover/confirm`, `set_master_volume`, gesture gate |
| `SaveSystem.gd` | Versioned JSON to user://meta.save. | `save_meta()`, `load_meta()`, `wipe_meta()` |
| `CardSystem.gd` | Draft + active deck + payload mutation. | `offer_cards(n)`, `pick_card(idx)`, `skip_draft()`, `get_modifier(stat)`, `mutate_payload(p)` |
| `ChallengeTracker.gd` | Tracks 26 challenges, awards RD. | listens to EventBus, persists via `MetaProgress.settings` |

## EventBus signal vocabulary

Producers and primary consumers. Add a row when you add a signal.

| Signal | Producer | Consumers |
|---|---|---|
| `weapon_fired(weapon, payload)` | `Weapon._fire` | `CardSystem.mutate_payload`, `AudioMan`, `Player` (recoil/shake), `HUD` (ammo), `ChallengeTracker` (weapon-use tracking) |
| `weapon_reloaded(weapon)` | `Weapon._finish_reload`, `CardSystem` (marksman refund hack) | `AudioMan`, `HUD` |
| `weapon_swapped(old, new)` | `WeaponManager._activate` | `HUD` (ammo display refresh) |
| `enemy_damaged(enemy, amount, src, hit_position, is_headshot)` | `Zombie.take_damage` | `HUD` (damage numbers, hit marker) |
| `enemy_killed(enemy, src, is_headshot, position)` | `Zombie.take_damage` (HP ≤ 0) | `GameState` (tokens), `HUD` (score/streak), `MetaProgress` (lifetime kills), `CardSystem` (lifesteal/marksman), `ChallengeTracker`, `AudioMan` (death SFX) |
| `barrier_damaged(amount, attacker)` | `Barrier.take_damage` | `HUD` (HP, vignette, damage arrow), `Player` (shake), `ChallengeTracker` (clean-round bookkeeping) |
| `barrier_destroyed()` | `Barrier.take_damage` (HP ≤ 0) | `WaveComplete` (game over), `Player` (big shake), `AudioMan` |
| `wave_started(round_n, composition)` | `SpawnRing._start_wave` | `HUD` (wave label, intro banner, boss banner), `AudioMan` (sting), `CardDraft` (reset per-wave stats), `ChallengeTracker` |
| `wave_ended(round_n)` | `SpawnRing._on_enemy_killed` (last kill) | `CardSystem.offer_cards`, `ChallengeTracker` (clean-round eval) |
| `card_offered(choices)` | `CardSystem.offer_cards` | `CardDraft` (panel show + buffer), `HUD` (offered deck preview — questionable, see HUD audit below) |
| `card_drafted(card)` | `CardSystem.pick_card/skip_draft` | `Shop` (next panel in chain), `WaveComplete` (legacy listener), `HUD` (deck preview), `ChallengeTracker` (deck-size), `AudioMan` |
| `shop_opened()` | `Shop._on_card_drafted` | `AudioMan` |
| `shop_done()` | `Shop._on_continue_pressed` | `WaveComplete._on_shop_done` |
| `tokens_changed(new_total, delta)` | `Zombie.take_damage` (on kill), `Shop._on_buy` | `HUD` (token counter), `CardDraft` (per-wave token accumulator) |
| `research_data_changed(new_total, delta)` | `ChallengeTracker._mark_complete` | (currently no listener — RD shows on TitleScreen next load) |
| `run_started()` | `GameState.start_run` | `CardSystem` (clear deck), `ChallengeTracker` (reset run counters) |
| `run_ended(stats)` | `GameState.end_run`, `SpawnRing` (victory), `Barrier` (defeat via destroyed→WaveComplete) | `WaveComplete`, `ChallengeTracker`, `MetaProgress.record_run_end` |
| `settings_changed(key, value)` | `SettingsScreen` various handlers | `Player` (FOV apply) |
| `challenge_completed(id, rd_payout)` | `ChallengeTracker._mark_complete` | `ChallengeToast` |

---

## Scene flow (gameplay)

```
TitleScreen
  ├─ START RUN → Main.tscn
  ├─ META PROGRESSION → MetaScreen.tscn → ESC/back → TitleScreen
  └─ SETTINGS → SettingsScreen.tscn → ESC/back → TitleScreen

Main.tscn (root: Node3D)
├─ Arena (Arena.tscn OR CoolingTower.tscn)
│   ├─ Floor, walls, lighting, NavigationRegion3D
│   ├─ Barrier (Barrier.tscn instance)
│   └─ SpawnPoint0..N (Marker3D, group "spawn_points")
├─ Player (Player.tscn instance, transform 0,1.6,0)
│   └─ CameraPivot/Camera3D/WeaponHolder (WeaponManager.gd)
│       ├─ Pistol (Pistol.tscn) — slot 0
│       ├─ AR (AR.tscn)         — slot 1 (RD-locked until unlocked)
│       ├─ Shotgun (Shotgun.tscn) — slot 2 (RD-locked)
│       └─ Sidearm (Sidearm.tscn) — slot 3 (infinite ammo)
├─ SpawnRing (SpawnRing.gd) — drives wave queue
├─ HUD (HUD.tscn) — CanvasLayer
├─ CardDraft (CardDraft.tscn) — between-wave overlay #1
├─ Shop (Shop.tscn) — between-wave overlay #2
├─ WaveComplete (WaveComplete.tscn) — between-wave overlay #3
├─ PauseMenu (PauseMenu.tscn) — ESC overlay
└─ Tutorial (Tutorial.tscn) — first-run hints, dismisses self
```

Between-wave flow: `wave_ended` → CardDraft (buffer + draft) → CardSystem.pick_card → `card_drafted` → Shop → `shop_done` → WaveComplete → NEXT WAVE → SpawnRing.start_next_wave.

---

## Per-domain file index

### Weapons (`scenes/weapons/`)

| File | Purpose |
|---|---|
| `Weapon.gd` | Base weapon. Fire/reload/recoil/payload pipeline. Muzzle flash, tracer, sparks, kick, casings, PBR. |
| `Weapon.tscn` | Placeholder base mesh. Inherited by Pistol/Shotgun/AR/Sidearm. |
| `Pistol.tscn` / `Shotgun.tscn` / `AR.tscn` / `Sidearm.tscn` | Per-weapon viewmodel + assigned `WeaponData` resource. |
| `WeaponManager.gd` | 4-slot weapon swap. RD-gates slots via `MetaProgress.has_weapon`. |
| `data/weapon_data.gd` | `WeaponData` Resource class. |
| `data/*.tres` | `pistol_m1`, `ar`, `shotgun`, `sidearm` — stat resources. |
| `data/attachments/*.tres` | Schema stub. Not yet wired into gameplay. |
| `vfx/BulletTracer.gd/tscn` | Per-shot tracer line. |
| `vfx/ImpactSparks.gd/tscn` | Spark burst at non-enemy hit point. |

### Enemies (`scenes/enemies/`)

| File | Purpose |
|---|---|
| `Zombie.gd` | All enemy behavior. State machine (Idle/Chase/Attack/Stagger/Die). Direct steering (no navmesh). Per-archetype tinting + size from EnemyData. |
| `Zombie.tscn` | Body + head + eyes capsule rig. Used by every archetype. |
| `data/enemy_data.gd` | `EnemyData` Resource class. |
| `data/*.tres` | walker, runner, tank, exploder, spitter, subject (mini-boss), director (final boss). |
| `AcidSpit.gd/tscn` | Spitter projectile. Area3D, hits barrier. |
| `vfx/BloodBurst.gd/tscn` | Gore particle on hit (gated by Settings → Gore). |

### Arena (`scenes/arena/`)

| File | Purpose |
|---|---|
| `Arena.gd/tscn` | Containment Lab (waves 1–10 default arena). Floor, walls, lights, spawn points. |
| `CoolingTower.gd/tscn` | Second arena (waves 11+). |
| `SpawnRing.gd` | Wave queue runner. Hands out enemies from shuffled queue, respects active cap, fires wave_started / wave_ended. |
| `data/wave_data.gd` + `wave_1..wave_20.tres` | Per-wave composition + counts. |

### UI (`scenes/ui/`)

| File | Purpose |
|---|---|
| `HUD.gd/tscn` | In-game HUD: HP, ammo, weapon name, wave, score, tokens, deck, hit marker, damage numbers, streak, vignette, damage arrow, boss banner, wave intro banner. |
| `TitleScreen.gd/tscn` | Boot screen. Start / Meta / Settings. |
| `MetaScreen.gd/tscn` | Spend RD on perks, barrier upgrades, weapon unlocks. |
| `SettingsScreen.gd/tscn` | Sensitivity, FOV, fullscreen, gore toggle, Master/SFX/Music volumes. |
| `CardDraft.gd/tscn` | Between-wave card pick. Buffer → awaiting-gate → interactive state machine. |
| `Shop.gd/tscn` | Between-wave token spending. |
| `WaveComplete.gd/tscn` | Wave summary + NEXT WAVE / RESTART. Also handles game-over (barrier breached) and victory (all waves cleared). |
| `PauseMenu.gd/tscn` | ESC pause overlay. process_mode ALWAYS so it works during get_tree().paused. |
| `Tutorial.gd/tscn` | First-run hint panel. Dismisses after 5 kills or 25s. |
| `ChallengeToast.gd/tscn` | Slide-in toast when a challenge completes. |
| `DeathScreen.gd/tscn` | Run-end screen with stats (alt path to WaveComplete? — see audit below). |

### Player (`scenes/player/`)

| File | Purpose |
|---|---|
| `Player.gd/tscn` | Camera rig (yaw/pitch), recoil decay, shake, idle sway, mouse capture, settings sync. |
| `CasingPool.gd` | Reusable brass casings ejected from weapons. Pool node lives in Player.tscn. |
| `HitPause.gd` | Helper for brief Engine.time_scale dip on crits. |

### Art / Audio assets (`art/`, `audio/`)

- `art/materials/<name>/material.tres + textures` — Trim-sheet PBR materials reused across geometry (concrete, lab_tile, metal_panel, rusty_steel, weapon_metal, weapon_polymer).
- `audio/sfx/ui/` — 5 .ogg UI sounds (click, hover, confirm, card_flip, draft_appear).
- `audio/sfx/weapons/` — Per-weapon fire + reload .ogg.
- `audio/sfx/zombies/` — Groans, attacks, deaths.
- `audio/sfx/footsteps/` — Concrete + metal grate variants.
- `audio/sfx/barrier/` — Hit + heavy hit + alarm.

### Cards (`scenes/cards/data/`)

30 card .tres files + `card_data.gd` (schema). 26 challenge .tres files in `challenges/` + `challenge_data.gd`. Both lists are *manifested* in their respective autoload (`CardSystem.STARTER_CARDS`, `ChallengeTracker.CHALLENGE_PATHS`) — adding a new .tres requires editing the manifest, otherwise it won't load. This is a deliberate trade for web-PCK reliability (DirAccess on `res://` returns empty in shipped builds).

---

## Naming + style conventions (project.godot enforces)

- `class_name` GDScript files use PascalCase: `Weapon`, `Zombie`, `WeaponData`, etc.
- Filenames: PascalCase for scenes (`Pistol.tscn`), snake_case for data (`pistol_m1.tres`).
- Variable names: snake_case. Private prefix `_`.
- Signals: snake_case verbs (`weapon_fired`, `card_drafted`).
- Renderer: Compatibility (web requirement). No Forward+-only features.
- All saves to `user://` (IndexedDB on web).
- Single-threaded build — no `Thread`, `Mutex`, etc.

---

## When growing the codebase

**Adding a new weapon:** Create `data/<id>.tres` + `<Name>.tscn` (inheriting Weapon.tscn). Add to `MetaProgress.STARTER_WEAPONS` (or RD-unlock list). Add slot binding in `WeaponManager.SLOT_BY_ID`. Add input action in `project.godot`.

**Adding a new enemy:** Create `data/<id>.tres`. EnemyData.scene = `Zombie.tscn`. Tint/size in the .tres. Reference it in some `wave_N.tres`.

**Adding a new card:** Create `data/cards/<id>.tres`. **Append to `CardSystem.STARTER_CARDS` manifest** (CRITICAL — won't load otherwise).

**Adding a new challenge:** Create `data/challenges/<id>.tres`. Append to `ChallengeTracker.CHALLENGE_PATHS`. Add tracking logic in ChallengeTracker if a new `tracking_kind`.

**Adding a new arena:** Create `<Arena>.tscn` + `<Arena>.gd`. Must include spawn points in group `spawn_points` and a Barrier instance. Wire into `Main.gd` arena rotation (see Main.gd code).

**Adding a new EventBus signal:** Declare in `EventBus.gd`. Document above. Connect in `_ready` of the consumer.

**Adding a new autoload:** Add to `project.godot` [autoload]. Set process_mode if it should run during pause. Document above.

---

## Known TODO / Tech debt

See `docs/production-gaps.md` for the prioritized punch list. Also:

- `MetaProgress.get_fov()`, `MetaProgress.has_weapon()`, `MetaProgress.gore_enabled()` are convenience accessors; consider unifying the getter API.
- `HUD._on_card_offered` overwrites the deck label with "OFFERED DECK: …" during the buffer. Cosmetic; could change the label or split into two.
- `CardSystem.mutate_payload` doesn't apply mag_size / reload_time mods (those are read at use-time via `Weapon.get_effective_*` directly). Consistent but easy to miss.
- `WaveComplete.gd` still has a card_drafted listener that's now stale (Shop owns that step). Double-trigger possible if Shop is bypassed.
- `Weapon.gd:_apply_pbr_materials` overrides surface materials on every mesh by name hint — fragile if a future mesh is named outside the hint list.
