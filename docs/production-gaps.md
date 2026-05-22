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
- [ ] **Real 3D models** for the four weapons. Today they're CSG / primitive viewmodels. Source CC0 GLB/GLTF or commission. Each needs basic firing animation rig + ejection-port socket for casing spawn.
- [ ] **Real 3D models for zombies.** Five enemy archetypes are currently capsules with tints. At least one rigged humanoid mesh with palette/scale variants per archetype (Walker/Runner/Tank/Spitter/Exploder) and one distinct mesh per boss (Subject, Director). PARTIAL: 2026-05-21 — zombies now have humanoid silhouette (hunched torso, shoulders, head, jaw, two forward-reaching arms, two legs) built from primitives. Limbs tint with the archetype color. Still primitives, but reads as a creature rather than a capsule.
- [ ] **Arena dressing.** Containment Lab + Cooling Tower are geometric blockouts. Need: console banks, broken vents, equipment crates, signage, hanging cables, a few "destroyed lab" set-pieces near spawn corridors. CC0 sci-fi kit from Quaternius / Kenney is the fastest path.

### Build / deploy
- [ ] **Verify Initial Memory = 256 MB** in the Godot editor Web export preset. The web doctor flagged it doesn't appear in `export_presets.cfg` if at default. OOM crashes silently mid-horde otherwise.
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
- [ ] **Colorblind palette mode.** Eye glow + enemy tint differentiation is core to the read; colorblind players need a switch.
- [ ] **Subtitle / caption layer** for the intercom flavor text and boss callouts.
- [ ] **Key/mouse remap UI.** Sensitivity exists; full remap doesn't.
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
- [ ] **Idle viewmodel animation** between shots.
- [x] **Weapon-swap animation** ✓ shipped — `begin_swap_in` springs the new weapon up from below on activate.
- [ ] **Crosshair customization** (size, color, shape, dot/cross).
- [x] **Critical-hit flash** ✓ shipped — headshot tints the zombie body to white for 60ms, scale-pops 18%.
- [x] **Boss arena variants** ✓ shipped — fluorescent lights (Arena) and vent light (CoolingTower) shift to red + dim energy on wave 10 and 20 start, recover after the wave ends.
- [ ] **Score popup chains** — combo multiplier feedback on rapid kills.
- [ ] **Combo-break sound** when the streak resets.

### Content extras
- [ ] **Daily seeded challenge** — fixed RNG per UTC date, leaderboard-less but lets the player compare runs against their previous self.
- [ ] **Run modifiers / mutators** unlock-able post-v1.0 (one-life, no-shop, locked-weapon, double-spawn).
- [ ] **Cosmetic titles** earned through challenges, displayed on title screen.
- [ ] **Weapon skins** as RD spend tier (low priority but matches the meta-progression catalog in design-plan.md).
- [ ] **More cards** — design-plan.md M3 says "30 cards." Confirmed at 30. Push to 40–50 once curse + synergy categories land.

### Fiction / atmosphere
- [x] **Intercom flavor lines** ✓ shipped — Main.gd maintains an `INTERCOM_LINES` dict keyed by round_number. Fades the line in/out on the lower-left after the matching wave_ended. 13 lines covering wave 1, 2, 3, 5, 7, 9, 10, 11, 14, 16, 18, 19.
- [x] **Story intro** ✓ shipped — `StoryIntro.tscn` overlays Main on first run, 4 lines × ~2.4s each, click/space/ESC to skip. Fades out and queue_frees.
- [x] **Death-screen flavor text** ✓ shipped — randomized victory and defeat lines on the DeathScreen subtitle.

### Engineering
- [x] **AudioMan pool size** ✓ bumped 16 -> 24 (both 2D and 3D pools).
- [ ] **BloodBurst pooling** — currently instantiate + queue_free per hit (flagged by AI architect). Pool if perf regresses.
- [ ] **`SaveSystem.rename_absolute` web warning** — refactor to write-then-overwrite without rename when `user://` resolves to IndexedDB. Cosmetic; saves still work via fallback.
- [ ] **Spitter acid AOE vs clean-round challenge** — confirm whether acid puddle damage on barrier should disqualify the "clean round" challenges, or be exempt. Open question from challenge agent.
- [ ] **Multi-slot save** — currently one run + one meta file. Add 3 save slots for shared-machine households.
- [ ] **Save export / import** — base64 blob so the user can move progress between browsers / devices.

---

## P3 — Nice-to-have / post-launch

- [ ] **FPS counter** (toggle in dev/settings).
- [ ] **Dev console** (`~` key) for cheat / debug commands during testing.
- [ ] **Photo mode** — pause + free-fly camera + filter toggles for screenshots.
- [ ] **Replay / kill-cam** on final death.
- [ ] **Localization scaffolding** — extract every UI string to a translation file even if v1.0 ships English-only.
- [x] **Credits screen** ✓ shipped — CreditsScreen.tscn reachable from title. Lists Godot engine, Quaternius weapon pack, AmbientCG/Poly Haven PBR maps, audio sources, design + code credit.
- [ ] **Content-warning splash** linkable from title screen per CLAUDE.md sensitivity guardrails.
- [ ] **README polish** — short itch-style write-up at the GH Pages root + a 5-second loop GIF for the README.
- [ ] **Twitter / itch.io launch art** — title key-art, three gameplay screenshots, a short trailer.
- [ ] **Procedural arena seed** — even within the same arena scene, randomize prop placement per run for visual variety.
- [ ] **Boss telegraph audio** — distinct warning sting on boss wave start, longer than the regular tension stinger.
- [ ] **Weapon inspect animation** (hold a key to look at the viewmodel) — pure flavor.
- [ ] **Mouse-smoothing toggle.**
- [ ] **Gamepad rumble** (where supported — web limited).
- [ ] **Tutorial replay** — let returning players re-trigger the first-run hints from the settings menu.
- [ ] **Backup save** — keep last-N saves in case of corruption.
- [ ] **Run analytics opt-in** — anonymous round-reached histogram, only with player consent. Aids balance.

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
