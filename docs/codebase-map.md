# Codebase map — Site Echo 7

Quick-reference for "where does X live." Skim before changing anything; update when adding new systems.

Counts current as of latest audit: ~40 .gd files, ~5,500 LOC, ~115 .tres data files, ~10 .glb 3D models.

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
3. If `content_warning_acked` is unset in MetaProgress.settings, TitleScreen redirects to ContentWarning.tscn on first launch.
4. TitleScreen.tscn → user clicks START RUN → `Main.tscn` loads → Arena loads → SpawnRing starts wave 1
5. On first run only (intro_seen unset): StoryIntro overlay pauses the tree for ~10s of 4-line fade text. Click/space/ESC skips. After dismiss, tree unpauses and wave 1 spawns kick in.

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
| `DailyChallenge.gd` | One UTC-date-seeded goal per day. | `today_goal()`, `today_completed()`, signal `daily_completed_today`. Persists `daily_completed_date` in MetaProgress.settings. |

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
[Boot]
  └─ ContentWarning (first launch only) → TitleScreen
TitleScreen
  ├─ START RUN → Main.tscn
  ├─ META PROGRESSION → MetaScreen → ChallengesScreen
  ├─ SETTINGS → SettingsScreen
  ├─ LIFETIME STATS → LifetimeStatsScreen
  ├─ RUN MODIFIERS → ModifiersScreen
  ├─ CREDITS → CreditsScreen
  └─ all back via ESC/back button

Main.tscn (root: Node3D)
├─ Arena (Arena.tscn OR CoolingTower.tscn)
│   ├─ Floor, walls, lighting, NavigationRegion3D, random Debris crates
│   ├─ Barrier (Barrier.tscn instance)
│   └─ SpawnPoint0..7 (Marker3D, group "spawn_points", radius 19)
├─ Player (Player.tscn instance, transform 0,1.6,0)
│   └─ CameraPivot/Camera3D/WeaponHolder (WeaponManager.gd)
│       ├─ Pistol / Sidearm / AR / Shotgun / SMG / BoltAction (Quaternius GLBs)
│       └─ Slots 1-6 hot-swappable via keys 1-6 or Q to cycle
├─ SpawnRing — wave queue, 0.9s spawn telegraph (visual only)
├─ HUD — wave/HP/ammo/score/tokens/crosshair/FPS/streak/intercom subtitles
├─ CardDraft — between-wave overlay #1 (buffer + draft)
├─ Shop — between-wave overlay #2 (token spend, gated by no_shop modifier)
├─ WaveComplete — between-wave overlay #3 (NEXT WAVE button)
├─ PauseMenu — ESC overlay, hold-to-confirm Return to Title
├─ Tutorial — first-run hints (5 kills or 25s self-dismiss)
├─ DeathScreen — run end, victory/defeat flavor text
├─ DevConsole — ~ key debug commands
└─ StoryIntro — first-run only, pauses tree until dismissed
```

Between-wave flow: `wave_ended` → CardDraft (buffer + draft) → CardSystem.pick_card → `card_drafted` → Shop → `shop_done` → WaveComplete → NEXT WAVE → SpawnRing.start_next_wave.

---

## Per-domain file index

### Weapons (`scenes/weapons/`)

| File | Purpose |
|---|---|
| `Weapon.gd` | Base weapon. Fire/reload/recoil/payload pipeline. Muzzle flash, tracer, sparks, kick, casings, PBR. |
| `Weapon.tscn` | Placeholder base mesh. Inherited by Pistol/Shotgun/AR/Sidearm/SMG/BoltAction. |
| `Pistol.tscn` / `Shotgun.tscn` / `AR.tscn` / `Sidearm.tscn` / `SMG.tscn` / `BoltAction.tscn` | Per-weapon viewmodel + assigned `WeaponData` resource. |
| `WeaponManager.gd` | 6-slot weapon swap (keys 1-6, Q to cycle). RD-gates slots via `MetaProgress.has_weapon`. |
| `data/weapon_data.gd` | `WeaponData` Resource class. |
| `data/*.tres` | `pistol_m1`, `ar`, `shotgun`, `sidearm`, `smg`, `bolt_action` — stat resources. |
| `data/attachments/*.tres` | Schema stub. Not yet wired into gameplay. |
| `vfx/BulletTracer.gd/tscn` | Per-shot tracer line (legacy, unused — superseded by pool). |
| `vfx/TracerPool.gd/tscn` | Pre-allocated tracer ring (32 slots, shared material). Used by Weapon._spawn_tracer. |
| `vfx/ImpactSparks.gd/tscn` | Spark burst at non-enemy hit point. |
| `vfx/BulletHolePool.gd/tscn` | 48-slot decal pool. Stamps a dark quad on world impacts, fades after 6s. |

### Enemies (`scenes/enemies/`)

| File | Purpose |
|---|---|
| `Zombie.gd` | All enemy behavior. State machine (Idle/Chase/Attack/Stagger/Die). Direct steering (no navmesh). Per-archetype tinting + size from EnemyData. Director enters phase-2 rage at HP<50%. White-flash + scale-pop on hit. Dissolve = single scale tween (no per-mesh allocations). |
| `Zombie.tscn` | Humanoid silhouette built from primitives — hunched torso, shoulders, head, jaw, two forward-reaching arms, two legs. |
| `data/enemy_data.gd` | `EnemyData` Resource class. |
| `data/*.tres` | walker, walker_elite, runner, tank, exploder, spitter, subject (mini-boss), director (final boss). |
| `AcidSpit.gd/tscn` | Spitter projectile. Area3D, hits barrier. |
| `vfx/BloodBurst.gd/tscn` | Gore particle on hit (gated by Settings → Gore). |
| `vfx/BloodBurstPool.gd/tscn` | 6-slot pre-allocated emitter pool. Recycles via restart(). |

### Arena (`scenes/arena/`)

| File | Purpose |
|---|---|
| `Arena.gd/tscn` | Containment Lab (waves 1–10 default arena). Floor, walls, lights, spawn points. |
| `CoolingTower.gd/tscn` | Second arena (waves 11+). |
| `SpawnRing.gd` | Wave queue runner. Hands out enemies from shuffled queue, respects active cap, fires wave_started / wave_ended. 0.9s spawn telegraph (light pulse + sting) precedes each zombie pop-in. |
| `data/wave_data.gd` + `wave_1..wave_20.tres` | Per-wave composition + counts. |

### Turret (`scenes/turret/`)

| File | Purpose |
|---|---|
| `Turret.gd/tscn` | Auto-emplacement bought from Shop. 8 dmg / 1.6s fire interval, 14m range. Stacks to 4. No SFX (visual tracer only). |

### UI (`scenes/ui/`)

| File | Purpose |
|---|---|
| `HUD.gd/tscn` | In-game HUD: HP, ammo, weapon name, wave, score, tokens, deck, hit marker, damage numbers, streak, vignette, damage arrow, boss banner, wave intro banner. Also: dynamic crosshair (settings-driven), FPS counter toggle, ×N score popups on streak kills. |
| `TitleScreen.gd/tscn` | Boot screen. Start / Meta / Settings / Lifetime Stats / Run Modifiers / Credits. Daily challenge + cosmetic title shown above lifetime stats. |
| `MetaScreen.gd/tscn` | Spend RD on perks, barrier upgrades, weapon unlocks. Includes VIEW CHALLENGES button → ChallengesScreen. |
| `SettingsScreen.gd/tscn` | Sensitivity, FOV, fullscreen, gore toggle, Master/SFX/Music volumes, crosshair (style/size/color), FPS counter, mouse smoothing, tutorial replay, colorblind mode, save export/import. |
| `ChallengesScreen.gd/tscn` | Browser for all 26 challenges with tier-coloured rows, progress counters, completion state. Reachable from MetaScreen. |
| `LifetimeStatsScreen.gd/tscn` | Career / Combat / Per-weapon / Challenges totals. Reachable from TitleScreen. |
| `ModifiersScreen.gd/tscn` | 4 run modifiers (No Shop, No Cards, Locked Weapon, Double Spawn). Persists active set. Read by GameState.start_run. |
| `CreditsScreen.gd/tscn` | Engine + asset sources + code credit. Reachable from TitleScreen. |
| `ContentWarning.gd/tscn` | First-launch splash. Persists ack flag. Title redirects to it if unset. |
| `StoryIntro.gd/tscn` | 4-line first-run intro. Pauses tree while shown so wave 1 doesn't tick under the overlay. Skippable. Persists intro_seen. |
| `DevConsole.gd/tscn` | ~ key opens a bottom bar with debug commands (tokens, rd, hp, skip, kill, god, unlock). |
| `CardDraft.gd/tscn` | Between-wave card pick. Buffer → awaiting-gate → interactive state machine. Live hover preview projects card's stat deltas onto the active weapon. |
| `Shop.gd/tscn` | Between-wave token spending. Skipped if `no_shop` modifier active. |
| `WaveComplete.gd/tscn` | Wave summary + NEXT WAVE / RESTART. Also handles game-over (barrier breached) and victory (all waves cleared). |
| `PauseMenu.gd/tscn` | ESC pause overlay. Hold-to-confirm "Return to Title" (second press inside 2.5s). |
| `Tutorial.gd/tscn` | First-run hint panel. Dismisses after 5 kills or 25s. |
| `ChallengeToast.gd/tscn` | Slide-in toast when a challenge completes. |
| `DeathScreen.gd/tscn` | Run-end screen with stats + randomized victory/defeat flavor text. |

### Player (`scenes/player/`)

| File | Purpose |
|---|---|
| `Player.gd/tscn` | Camera rig (yaw/pitch), recoil decay, shake, idle sway, mouse capture, settings sync, viewmodel bob, inspect mode (hold I), gamepad rumble on fire, mouse smoothing toggle, FOV punch on fire. |
| `CasingPool.gd` | Reusable brass casings ejected from weapons. Pool node lives in Player.tscn. |
| `HitPause.gd` | Tiered Engine.time_scale dip on kills — body (0.6/20ms), headshot (0.35/45ms), boss (0.2/180ms). |

### Art / Audio assets (`art/`, `audio/`)

- `art/materials/<name>/material.tres + textures` — Trim-sheet PBR materials reused across geometry (concrete, lab_tile, metal_panel, rusty_steel, weapon_metal, weapon_polymer).
- `audio/sfx/ui/` — 5 .ogg UI sounds (click, hover, confirm, card_flip, draft_appear).
- `audio/sfx/weapons/` — Per-weapon fire + reload .ogg.
- `audio/sfx/zombies/` — Groans, attacks, deaths.
- `audio/sfx/footsteps/` — Concrete + metal grate variants.
- `audio/sfx/barrier/` — Hit + heavy hit + alarm.

### Cards (`scenes/cards/data/`)

38 card .tres files + `card_data.gd` (schema). 26 challenge .tres files in `challenges/` + `challenge_data.gd`. Both lists are *manifested* in their respective autoload (`CardSystem.STARTER_CARDS`, `ChallengeTracker.CHALLENGE_PATHS`) — adding a new .tres requires editing the manifest, otherwise it won't load. This is a deliberate trade for web-PCK reliability (DirAccess on `res://` returns empty in shipped builds).

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

**Adding a new weapon:** Create `data/<id>.tres` + `<Name>.tscn` (inheriting Weapon.tscn). Add slot binding in `WeaponManager.SLOT_BY_ID` and bump `SLOT_COUNT` if needed. Add the input action (`swap_X`) in `project.godot` AND handler in `WeaponManager._unhandled_input`. Instance the new weapon in `Player.tscn` under `WeaponHolder` (visible=false). If RD-locked: add an UNLOCKS entry in `MetaScreen.UNLOCKS` (`kind="weapon"`). Starter loadout lives in `MetaProgress.unlocked_weapons`.

**Adding a new enemy:** Create `data/<id>.tres`. EnemyData.scene = `Zombie.tscn`. Tint/size in the .tres. Reference it in some `wave_N.tres`.

**Adding a new card:** Create `data/cards/<id>.tres`. **Append to `CardSystem.STARTER_CARDS` manifest** (CRITICAL — won't load otherwise). If the card belongs to a synergy cluster, add its id → tag(s) entry in `CardSystem.CARD_TAGS`. If it's a SYNERGY card itself (only activates when N+ of a tag exist), set `requires_tag` + `requires_count` on the .tres.

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
