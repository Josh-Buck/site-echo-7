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
- [ ] **First-run tutorial polish.** Current Tutorial panel exists but is barebones. Needs: spin-to-aim hint, reload hint, card-system explainer (one card draft walkthrough), shop explainer, sidearm fallback hint.
- [ ] **Title-screen Continue button** — confirm mid-run save reload works end-to-end (design-plan.md M2 line; needs verification).

---

## P1 — Strongly expected

### Content depth
- [x] **5th weapon: SMG** ✓ shipped — high RPM, low damage, 35 mag, slot 5 / key 5, 550 RD unlock.
- [x] **6th weapon: Bolt-Action Rifle** ✓ shipped — 0.7 rps, 60 dmg, HS×3, slot 6 / key 6, 700 RD unlock.
- [x] **Spitter + Exploder** ✓ shipped (M3d earlier).
- [ ] **Elite / armored variants** of basic enemies for mid-round spice.
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
- [ ] **Resume-run flow** on title screen — Continue / New Run buttons, confirm-dialog if New overrides save.

### Accessibility
- [ ] **Colorblind palette mode.** Eye glow + enemy tint differentiation is core to the read; colorblind players need a switch.
- [ ] **Subtitle / caption layer** for the intercom flavor text and boss callouts.
- [ ] **Key/mouse remap UI.** Sensitivity exists; full remap doesn't.
- [x] **Mouse sensitivity range expanded.** ✓ max bumped 0.006 -> 0.020 after user maxed the old slider.
- [ ] **Hold-to-confirm** option for destructive UI actions (return-to-title mid-run).

### Polish
- [ ] **Weapon reload animations** on the viewmodel (mag drop, slide rack, pump for shotgun). Currently audio-only.
- [ ] **Zombie hit-reaction animations** — directional stagger on hit, not just blood burst.
- [ ] **Bullet hole decals** on floor / barrier where shots impact (with a pool cap).
- [x] **Brass casing audio** ✓ shipped.
- [x] **Punchier weapon SFX.** ✓ Pistol/AR/Shotgun synths rewritten as crack-body-tail; previously read as a hiss, now reads as a distinct shot.
- [x] **Arena lunar atmosphere.** ✓ Sky+fog crushed to near-black, ambient + sun energies dropped, glow turned on, floor texture roughened. Both arenas. Player flashlight covers the dim.
- [x] **Spawn-point distance.** ✓ Pushed radius 12 -> 19; ~67% more run-up time.
- [x] **FOV punch on fire.** ✓ subtler version after user feedback (coefficient halved, cap halved).

---

## P2 — Polish and depth

### Game feel
- [ ] **Hit-pause variants** — currently only on headshot kills. Add a smaller pause on regular kill, a longer one on boss-phase transition.
- [ ] **Camera weapon sway** when idle (gentle breathing).
- [ ] **Idle viewmodel animation** between shots.
- [ ] **Weapon-swap animation** (lower / raise) when cycling slots.
- [ ] **Crosshair customization** (size, color, shape, dot/cross).
- [ ] **Critical-hit flash** — enemy briefly tints white on headshot before blood spawns.
- [ ] **Boss arena variants** — lights dim red during boss waves; ambient hum drops out.
- [ ] **Score popup chains** — combo multiplier feedback on rapid kills.
- [ ] **Combo-break sound** when the streak resets.

### Content extras
- [ ] **Daily seeded challenge** — fixed RNG per UTC date, leaderboard-less but lets the player compare runs against their previous self.
- [ ] **Run modifiers / mutators** unlock-able post-v1.0 (one-life, no-shop, locked-weapon, double-spawn).
- [ ] **Cosmetic titles** earned through challenges, displayed on title screen.
- [ ] **Weapon skins** as RD spend tier (low priority but matches the meta-progression catalog in design-plan.md).
- [ ] **More cards** — design-plan.md M3 says "30 cards." Confirmed at 30. Push to 40–50 once curse + synergy categories land.

### Fiction / atmosphere
- [ ] **Intercom flavor lines** — short procedural / written research-note fragments that play between waves to sell the Site Echo-7 fiction. Synthesized voice or text-only.
- [ ] **Story intro** — 10-second opening on a new run: "Two hours after containment failure. Site Echo-7. Observation ring secured." Brief, skippable.
- [ ] **Death-screen flavor text** — randomized end-of-run "research note" tying the run to the fiction.

### Engineering
- [ ] **AudioMan pool size** — bump from 16+16 to 24+24 if peak-wave SFX truncation is observed.
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
- [ ] **Credits screen** — assets + libraries + sources from `audio/CREDITS.md` and `art/CREDITS.md`.
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
