# Production gaps — Site Echo 7

A prioritized punch list of everything still standing between the current build and a fully-fleshed v1.0. Snapshot date: 2026-05-17. Reorder as priorities shift.

Tiers:
- **P0 — Blocker for v1.0 launch.** A reviewer would call the game obviously incomplete without these.
- **P1 — Strongly expected.** Players won't refund without them, but their absence reads as low-budget.
- **P2 — Polish and depth.** What separates "shipped" from "loved."
- **P3 — Nice-to-have / post-launch.** Worth listing so they don't get reinvented later.

---

## P0 — Blockers for v1.0

### Audio
- [ ] **Music.** Soundtrack is entirely absent. Need at least: main-menu loop, ambient combat bed, escalation layer for waves 10+, boss theme variant, run-end stinger. Procedural / CC0 sourced (Kevin MacLeod, ccMixter, Sonniss).
- [x] **Route remaining AudioStreamPlayers to SFX/Music buses.** ✓ done — all 3D positional + ambient now route to SFX.
- [x] **Browser audio gesture-gating.** ✓ first-click gesture pattern works; cold-boot bus volumes applied via AudioMan.
- [x] **Barrier-impact SFX no longer reads as constant gunfire.** ✓ throttled to 160ms cooldown and volume dropped 6-10 dB. Was the user-reported "shots all over the background."
- [x] **Brass casing audio.** ✓ each casing emits a quiet metal tink on first floor-bounce (cooldown-debounced so a bouncing casing doesn't clink twice).

### Visuals
- [x] **Real 3D models for the six weapons** ✓ shipped — Quaternius Ultimate Gun Pack (CC0). Pistol, Sidearm, AR, Shotgun, SMG, Bolt-Action all use real low-poly GLBs with baked textures. Rigged firing animations are the next ask (no rig yet on Quaternius pack — would need Mixamo retarget).
- [ ] **Real 3D models for zombies.** Five enemy archetypes are currently capsules with tints. At least one rigged humanoid mesh with palette/scale variants per archetype (Walker/Runner/Tank/Spitter/Exploder) and one distinct mesh per boss (Subject, Director). PARTIAL: 2026-05-21 — zombies now have humanoid silhouette (hunched torso, shoulders, head, jaw, two forward-reaching arms, two legs) built from primitives. Limbs tint with the archetype color. Still primitives, but reads as a creature rather than a capsule.
- [ ] **Arena dressing.** Containment Lab + Cooling Tower are geometric blockouts. Need: console banks, broken vents, equipment crates, signage, hanging cables, a few "destroyed lab" set-pieces near spawn corridors. CC0 sci-fi kit from Quaternius / Kenney is the fastest path.

### Build / deploy
- [x] **Verify Initial Memory = 256 MB** ✓ added `application/run/initial_size_mb=256` under preset.0.options.custom_features in export_presets.cfg.
- [ ] **Cross-browser smoke test** — Chrome, Firefox, Safari on macOS. Currently unverified after this session's churn.
- [ ] **DevTools heap watch.** Peak wave 20 with full audio + PBR; confirm < 256 MB.
- [ ] **Frame-time budget.** Profile at peak horde with all VFX on; 16.6ms 95th percentile target.

### Onboarding
- [x] **First-run tutorial polish.** ✓ rewritten — explains the spin-to-aim loop, card→shop cadence, sidearm fallback, alarm-at-25%-HP cue, 20-wave structure / boss on wave 20.
- [ ] **Title-screen Continue button** — requires a mid-run save format that doesn't currently exist. Parked: needs `GameState`-to-disk + arena/zombie state snapshot which is a much bigger lift than the rest of v1.0. Deferred to post-1.0.

---

## P1 — Strongly expected

### Content depth
- [x] **5th weapon: SMG** ✓ shipped — high RPM, low damage, 35 mag, slot 5 / key 5, 550 RD unlock.
- [x] **6th weapon: Bolt-Action Rifle** ✓ shipped — 0.7 rps, 60 dmg, HS×3, slot 6 / key 6, 700 RD unlock.
- [x] **Spitter + Exploder** ✓ shipped (M3d earlier).
- [x] **Elite / armored variants** ✓ shipped — Armored Walker (60 HP, armor, +14 dmg, blue-grey palette, glowing blue eyes). Appears in waves 5 and 8.
- [x] **Curse cards** ✓ shipped — Glass Cannon, Field Trauma, Gambler (tradeoff cards).
- [x] **Synergy cards** ✓ shipped — Pyromaniac (fire ≥3), Surgical Precision (precision ≥2), Munitions Specialist (ammo ≥2). Tag map in CardSystem.CARD_TAGS.
- [x] **More boss phases** ✓ shipped — Director phase-2 rage at HP < 50% (speed +50%, damage +25%, body recolor). Subject mid-boss still single-phase.

### UI / UX
- [x] **Challenges browser** ✓ shipped — ChallengesScreen.tscn, reachable from Meta Progression. Lists all 26 challenges by tier with counter progress.
- [x] **Lifetime stats screen** ✓ shipped — LifetimeStatsScreen.tscn, reachable from title. Career / Combat / Per-weapon / Challenges sections.
- [x] **Spawn telegraph** ✓ shipped — 0.9s warning red light pulse + descending sting at each spawn point before zombies pop in.
- [x] **Damage numbers** ✓ shipped (M3a).
- [x] **Card hover preview** ✓ shipped — projects stat deltas on the active weapon when hovering a draft card.
- [x] **Reload hint flash** ✓ shipped (M3-polish).
- [x] **Wave intro banner with composition** ✓ shipped (M3-polish). Also now includes "Deck:" reminder line.
- [ ] **Resume-run flow** on title screen — parked, same blocker as P0 Continue button.

### Accessibility
- [x] **Colorblind palette mode** ✓ shipped — Settings toggle. When on, eye glow swaps to high-contrast hues per archetype (white/blue/yellow/purple/orange/teal/lavender/gold) chosen for deuteranopia + protanopia legibility.
- [x] **Subtitle / caption layer** ✓ shipped — Main.gd's between-wave intercom system is text-only and renders as captions in the lower-left. No voice-over yet so this is effectively the entire caption layer.
- [-] **Key/mouse remap UI** — **deferred post-v1.0**. Sensitivity + FOV + mouse smoothing + crosshair customization already cover the most-requested input ergonomics. A full remap UI is a moderate-effort feature (each action needs a re-bind widget that consumes the next input event) with most of its value going to non-standard layouts. Re-add when external playtesters ask for it.
- [x] **Mouse sensitivity range expanded.** ✓ max bumped 0.006 -> 0.020 after user maxed the old slider.
- [x] **Hold-to-confirm** ✓ shipped — PauseMenu "Return to Title" now requires a second press inside 2.5s. Button text flips to "CONFIRM: ABANDON RUN" while armed.

### Polish
- [ ] **Weapon reload animations** on the viewmodel (mag drop, slide rack, pump for shotgun). Requires rigged GLBs; current Quaternius models aren't rigged.
- [x] **Zombie hit-reaction** ✓ shipped — brief scale-pop on every hit (bigger on headshot) + white critical-hit flash on headshot.
- [x] **Bullet hole decals** ✓ shipped — `BulletHolePool` (48 slots, ~6s lifetime + last-30% fade). Stamps a small dark quad oriented to the hit normal on world impacts (barrier/floor).
- [x] **Brass casing audio** ✓ shipped.
- [x] **Punchier weapon SFX.** ✓ Pistol/AR/Shotgun synths rewritten as crack-body-tail; previously read as a hiss, now reads as a distinct shot.
- [x] **Arena lunar atmosphere.** ✓ Sky+fog crushed to near-black, ambient + sun energies dropped, glow turned on, floor texture roughened. Both arenas. Player flashlight covers the dim.
- [x] **Spawn-point distance.** ✓ Pushed radius 12 -> 19; ~67% more run-up time.
- [x] **FOV punch on fire.** ✓ subtler version after user feedback (coefficient halved, cap halved).

---

## P2 — Polish and depth

### Game feel
- [x] **Hit-pause variants** ✓ shipped — three tiers: body kill (0.6 scale × 20ms), headshot (0.35 × 45ms), boss kill (0.2 × 180ms).
- [x] **Camera weapon sway** ✓ shipped (idle sway in Player.gd).
- [x] **Idle viewmodel animation** ✓ shipped — gentle figure-8 bob on the WeaponHolder while cursor is captured and shake is low. Sells "alive in hand."
- [x] **Weapon-swap animation** ✓ shipped — `begin_swap_in` springs the new weapon up from below on activate.
- [x] **Crosshair customization** ✓ shipped — Settings has style (plus/x/dot), size (12-48), and color (white/green/yellow/red/cyan). Visible immediately. Persisted via MetaProgress.
- [x] **Critical-hit flash** ✓ shipped — headshot tints the zombie body to white for 60ms, scale-pops 18%.
- [x] **Boss arena variants** ✓ shipped — fluorescent lights (Arena) and vent light (CoolingTower) shift to red + dim energy on wave 10 and 20 start, recover after the wave ends.
- [x] **Score popup chains** ✓ shipped — kill streak scores at ×1/×2/×3/×5/×10 tiers (matching the streak-label thresholds). A floating "×N" pops above the killed enemy.
- [x] **Combo-break sound** ✓ shipped — short 440->370 Hz minor-third tsk-tsk fires when a streak of 3+ resets via barrier damage.

### Content extras
- [x] **Daily seeded challenge** ✓ shipped — DailyChallenge autoload picks today's goal deterministically by UTC date hash from a 10-template pool (kills, headshots, round-reached, tokens-earned, deck-size, clean-round). Displayed on title screen above lifetime stats. Awards bonus RD (80-200) once per day on completion.
- [x] **Run modifiers / mutators** ✓ shipped — `RUN MODIFIERS` screen reachable from title. Four toggles persist between runs: No Shop, No Cards, Locked Weapon (pistol only), Double Spawn. GameState.has_modifier() gates each system.
- [x] **Cosmetic titles** ✓ shipped — derived from highest milestone (Director's Bane > Site Cleared > Subject Hunter > Containment Officer > Field Operator > Untouched > Veteran > Recruit). Shown on the title screen above lifetime stats.
- [-] **Weapon skins** — **deferred post-v1.0**. Real GLBs already vary visually; cosmetic tint variants would need a per-weapon material override chain we'd want to design once Mixamo-rigged models land (so skins can include alternate camos, not just hue shifts).
- [x] **More cards** ✓ partial — pool now at 38 cards. Added Field Sights, Quickdraw, Heavy Slugs, Suppressing Fire, Tactical Reload. Push to 45+ with more conditional effects (Hollow Points anti-armor, Knockback Loads, etc.) — needs CardSystem effect_id support.

### Fiction / atmosphere
- [x] **Intercom flavor lines** ✓ shipped — Main.gd maintains an `INTERCOM_LINES` dict keyed by round_number. Fades the line in/out on the lower-left after the matching wave_ended. 13 lines covering wave 1, 2, 3, 5, 7, 9, 10, 11, 14, 16, 18, 19.
- [x] **Story intro** ✓ shipped — `StoryIntro.tscn` overlays Main on first run, 4 lines × ~2.4s each, click/space/ESC to skip. Fades out and queue_frees.
- [x] **Death-screen flavor text** ✓ shipped — randomized victory and defeat lines on the DeathScreen subtitle.

### Engineering
- [x] **AudioMan pool size** ✓ bumped 16 -> 24 (both 2D and 3D pools).
- [x] **BloodBurst pooling** ✓ shipped — BloodBurstPool with 6 ring-buffer slots + restart(). Was the per-kill stutter source.
- [x] **Backup save** ✓ shipped — rotating 3-slot backup chain. load_meta falls through to bak.1 -> bak.2 -> bak.3 if the primary is corrupt.
- [x] **BloodBurst pooling** ✓ shipped (v0.6.2). Pre-allocates 6 emitters, recycles via restart(). Was the per-kill stutter.
- [x] **`SaveSystem.rename_absolute` web warning** ✓ workaround in place — `_try_load_from` falls through to the rotating backups when the rename fails, and `save_meta` has a direct-write fallback path. The warning still appears in console but it's cosmetic (saves succeed).
- [x] **Spitter acid AOE vs clean-round challenge** ✓ decided — acid pools that damage the barrier count toward `clean_round` tracking (it's still barrier damage). Players who want clean-round challenges must shoot down spit projectiles in flight before they hit. Matches "no barrier damage" literally.
- [-] **Multi-slot save** — **deferred post-v1.0**. Single-player browser game with one IndexedDB origin per browser/profile; shared-machine use case is rare and `save export/import` (via clipboard, shipped) already lets a household move progress between profiles.
- [x] **Save export / import** ✓ shipped — Settings has EXPORT and IMPORT buttons. EXPORT base64-encodes MetaProgress to the clipboard; IMPORT reads the clipboard, parses, and overwrites the meta save (then writes primary + rotates backups).

---

## P3 — Nice-to-have / post-launch

- [x] **FPS counter** ✓ shipped — toggle in Settings; shows in top-right of HUD when on.
- [x] **Dev console** ✓ shipped — `~` (or ESC to close) opens a bottom-bar console. Commands: `tokens N`, `rd N`, `hp N`, `skip N` (jump to wave), `kill` (clear all zombies), `god` (+9000 max HP), `unlock <id>`, `help`.
- [-] **Photo mode** — **deferred post-v1.0**. The game's player camera is locked-position by design (per non-negotiables); a true free-fly mode would require detaching the camera from the player rig and gating gameplay. Useful for marketing screenshots but not core.
- [-] **Replay / kill-cam** on final death. **Deferred post-v1.0** — would require recording input streams and snapshotting world state, which is the same lift as the parked mid-run save. Re-evaluate then.
- [-] **Localization scaffolding** — **out of scope for v1.0** per `docs/non-negotiables.md` ("Localization (English only in v1)"). Re-evaluate post-launch.
- [x] **Credits screen** ✓ shipped — CreditsScreen.tscn reachable from title. Lists Godot engine, Quaternius weapon pack, AmbientCG/Poly Haven PBR maps, audio sources, design + code credit.
- [x] **Content-warning splash** ✓ shipped — ContentWarning.tscn appears once on first launch (gated by content_warning_acked in MetaProgress.settings). Title screen redirects to it if the flag is unset. ACK persists.
- [x] **README polish** ✓ done — rewritten for the live build (controls, weapons, enemies, shop, meta, tech, layout, build, status). A 5-second loop GIF is the remaining nice-to-have.
- [ ] **Twitter / itch.io launch art** — title key-art, three gameplay screenshots, a short trailer.
- [x] **Procedural arena seed** ✓ shipped — Arena now spawns 6 random crates between the barrier and the perimeter wall, different placement each run.
- [x] **Boss telegraph audio** ✓ shipped — distinct 2.2s descending double-tone synth on wave 10 and 20 start, replaces the regular tension stinger on boss waves.
- [x] **Weapon inspect animation** ✓ shipped — Hold I to inspect. WeaponHolder lerps toward an offset (left, up, forward) + rotates ~20deg toward the lens. Bob auto-disables while inspecting.
- [x] **Mouse-smoothing toggle** ✓ shipped — Settings checkbox. When on, mouse motion lerps toward target at ~18/s instead of applying instantly.
- [x] **Gamepad rumble** ✓ shipped — Input.start_joy_vibration on weapon_fired with weak/strong magnitudes scaled by recoil_vertical. Best-effort on web (browsers limit this); pistol is subtle, bolt-action is heavy.
- [x] **Tutorial replay** ✓ shipped — Settings button clears intro_seen + tutorial_done flags so next run re-shows both.
- [x] **Backup save** ✓ shipped — rotating 3-slot chain.
- [-] **Run analytics opt-in** — **deferred post-v1.0**. Needs a backend endpoint to receive the data + a consent flow + privacy-policy text. Not worth the infra cost until v1.0 has external playtesters.

---

## Known follow-ups parked by sub-agents this session

- **`MetaScreen` needs a Challenges tab.** Game-designer agent flagged it. Listed in P1 under "Challenges browser."
- **Player.gd FOV hook** — done this session.
- **Zombie gore gate** — done this session.
- **SFX-bus routing for Weapon + Zombie** — done this session; remaining routing in P0 audio.
- **ChallengeTracker DirAccess web risk** — fixed to static manifest this session.
- **Casing PBR mag-vs-polymer heuristic** in `Weapon._apply_pbr_materials()` — Magazine is currently classified as polymer; game-designer should sanity-check the look.

---

## How to use this list

1. Pick the highest-priority unchecked item that fits the next building session.
2. Route to the right sub-agent (`.claude/agents/` — see CLAUDE.md "Agent team" table).
3. Tick the box, commit, push.
4. When P0 + P1 are all green, tag `v1.0.0`.

## Symbols

- `[ ]` — unchecked, still on the v1.0 path.
- `[x]` — done.
- `[-]` — **deferred post-v1.0** (intentionally — see explanation on the line).

## What's left for v1.0

The remaining `[ ]` items all require user / asset intervention I can't do autonomously. **See `docs/asset-pipeline.md` for step-by-step walkthroughs of each.**

- **Music** — needs a curated CC0 soundtrack source decision (Kevin MacLeod, ccMixter, Sonniss) and a few hours of triage + import.
- **Rigged zombie meshes** — Mixamo requires an Adobe login. Walkthrough: `docs/asset-pipeline.md` § 1.
- **Arena dressing** — additional CC0 sci-fi prop kit. Walkthrough: `docs/asset-pipeline.md` § 2.
- **Cross-browser smoke / DevTools heap / frame budget** — manual browser testing. Walkthrough: `docs/asset-pipeline.md` § 3.
- **Continue / Resume-run + weapon reload animations** — bigger system designs that need product decisions on scope (mid-run save format, rigged-weapon retarget pipeline).
- **Twitter / itch.io launch art** — manual asset production (key art, screenshots, trailer).

## Parked / acknowledged

- **Turret model** — current Turret.tscn (cylinder base + box barrel) looks under-polished. Acknowledged by user 2026-05-22; parked until a real CC0 emplacement model lands (Quaternius Sci-Fi Essentials has a few).
