# Design plan — godot-shooter

> **Status (live, v0.7.x).** Game is feature-complete for v1.0 except for music + rigged zombie meshes. M0 / M1 / M2 / M3 all shipped end-to-end.
>
> **In the build:** 6 weapons (real CC0 GLBs from Quaternius), 6 enemy archetypes including the Armored Walker, 2 bosses (Subject + Director with phase-2 rage), 38 cards including 3 synergies + 3 curses, 26 challenges across 4 tiers, daily seeded challenge, 4 run modifiers, token shop with 9 offers including auto-turret emplacement, card draft + shop + wave-complete chain, lifetime stats + challenges browser + credits screens, content-warning splash, story intro, intercom flavor lines, two arenas (Containment Lab + Cooling Tower) with boss-wave red lighting variants, procedural audio + lunar atmospheric pass, full settings (sensitivity, FOV, volumes, gore, fullscreen, crosshair style/size/color, FPS counter, mouse smoothing, tutorial replay, colorblind mode, save export/import), HUD with crosshair + FPS counter + streak labels + score popups + intercom subtitles, dev console (~ key), pooled VFX (TracerPool/BulletHolePool/BloodBurstPool/CasingPool), 3-slot rotating save backups, hold-to-confirm destructive UI actions, weapon inspect animation, gamepad rumble.
>
> See **`docs/production-gaps.md`** for the live punch list of what still blocks v1.0.

The locked, milestone-by-milestone plan. Companion to `CLAUDE.md` (the rules) and `docs/non-negotiables.md` (the constraints). Open questions at the bottom.

## Fiction & framing (one paragraph)

**Site Echo-7** is a black-budget research facility studying an unstable biological agent. Containment failed two hours ago. You are the on-shift research lead, holed up inside the central observation ring — a circular containment barrier built to study subjects from all angles. The barrier is the only thing keeping the infected out. The lab's intercom keeps spitting up encrypted research notes from your colleagues — short text fragments that, somehow, hot-modify your weapons when you read them. ("Field-modified the M4's gas port — recoil down, fire rate up. — Halverson, 03:14.") You don't survive. You learn. You bank what the lab teaches you. You go again.

Cards = research notes. Meta tokens = "data salvaged." Bosses = test subjects.

## Core loop

### Per round (~45–90s)
1. **Spawn warning** — audio sting + radial compass markers light up
2. **Wave begins** — zombies spawn from a ring of breach points around the barrier, walk inward, attack the barrier on contact
3. **Combat** — player spins, shoots, reloads, watches all 4 quadrants
4. **Wave ends** when all spawned zombies are down
5. **Lull (~15s)** — barrier auto-repairs +25%, ammo restocks, **card draft UI: pick 1 of 3** (cards are weighted by current deck + meta unlocks)
6. **Optional shop wall** — spend research tokens for a bigger weapon swap (every 5 rounds, or always — TBD in M2 playtest)
7. **Next round** — composition escalates

### Per run (~10–20 min)
- Rounds 1–5: tutorial-by-osmosis. 1 enemy type. Player learns the spin, the reload, the cards.
- Rounds 6–10: 2nd and 3rd enemy types introduced. Cards start synergizing.
- **Round 10:** mini-boss (The Subject).
- Rounds 11–20: scaling difficulty, mixed comps, occasional elite waves.
- **Round 20:** boss (Site Director). "Victory" message. Run continues if you want.
- Rounds 21+: endless, asymptotic difficulty curve, no new content but kill counts feed leaderboard… err, just the local score.

### Per session (multi-run)
- Run ends → death screen shows: kills, rounds survived, tokens earned, top 3 favorite cards this run
- Tokens bank to meta progression
- Pick next unlock (or save up)
- New run inherits unlocked cards/weapons/perks

## Strategic systems

### Card system (the hook)

**Effect resolution pipeline:**
1. Weapon fires → `Weapon.gd` emits `weapon_fired` with payload (damage, ammo cost, recoil delta, etc.)
2. `CardSystem` intercepts the payload, walks the active deck in registration order, each card's `Card.gd` can mutate the payload
3. Final payload applied to hit targets
4. Post-hit cards (e.g. "headshots refund ammo") fire on `enemy_killed` signal

**Why pipeline:** lets us add cards in M2 without ever touching weapon code. New card = new `.tres` + new `Card.gd` subclass. Stays additive.

**Draft logic:**
- 1 of 3 cards offered after each round
- Pool weighted by: rarity tier, current deck composition (more synergies as deck grows), meta-unlocked cards (locked cards don't roll until unlocked)
- Re-roll cost: 25 tokens (cheap early, expensive late as token economy inflates)
- Start simple — M2 ships ~10 boring/intermediate cards. Synergy and curse cards arrive in M3 once balance is observable.

### Two-currency economy

**Tokens (in-run, lost on death)** — earned per kill, spent in-run only.
- Walker: 1. Runner: 2. Exploder: 3. Spitter: 4. Tank: 5. Mini-boss: 50. Boss: 200.
- Spend on the shop wall: weapon swap, ammo top-up, barrier repair, card re-roll.

**Research Data (RD) — persistent, slow.** The permanent-unlock currency. Earned three ways:
1. **Run-end banking:** `floor(tokens_earned / 10)` RD, with a small multiplier per round survived (e.g. ×1.0 at round 5, ×1.5 at round 15, ×2.5 at round 30+).
2. **Challenge completion:** discrete RD payouts for achievement-style goals (see Challenges below).
3. **First-time round milestones:** one-time RD bonuses for first time reaching round 5/10/15/20/30/50/100. Larger as rounds escalate.

**Slowness tuning (target):** A typical early run (dying ~round 8) banks ~25 RD. Mid-tier unlocks cost 200–500 RD. Top-tier unlocks cost 1500+. Casual players need 5–10 runs per meaningful unlock; skilled players accelerate via challenges and deep-round milestones. **This slowness is the retention mechanic. Do not balance against it.**

### Challenge system

Persistent achievement-style goals that grant RD on completion. Drives "what should I try next" between runs without prescribing a specific build.

- **Survival:** "Reach round 10 / 20 / 30 / 50 / 100"
- **Marksmanship:** "Headshot 50 / 250 / 1000 / 5000 zombies (lifetime)"
- **Weapon mastery:** "Kill 100 zombies with each weapon" (per-weapon)
- **No-damage:** "Survive a round without barrier damage" → "5 rounds in a row" → "an entire run"
- **Card collector:** "Have a deck of 8+ / 12+ / 15+ cards in one run"
- **Card synergist:** "Trigger every synergy card at least once"
- **Specialist runs:** "Reach round 10 using only the pistol" (and equivalents for each weapon)
- **Speedrunner:** "Clear round X in under Y seconds"

Tiered payouts: bronze ~10 RD, silver ~30 RD, gold ~75 RD, platinum ~200 RD. Full challenge list lives in `docs/ideas.md` and gets drafted into the M3 pool.

### Round-milestone bonuses

Two layers — repeatable in-run rewards AND one-time permanent unlocks.

**In-run (every run, repeatable):**
- Round 5: bonus token bundle (+50)
- Round 10: free weapon swap from shop
- Round 15: pick 2 cards instead of 1 (this round only)
- Round 20: barrier full repair + ammo refill
- Round 25, 30, 40, 50: escalating bonuses (e.g. round 30 = guaranteed rare card; round 50 = pick from 5 cards)

**First-time-only (permanent, one-shot RD payouts that gate unlocks):**
- First time round 10: +50 RD, unlocks "Veteran" starter-perk slot
- First time round 15: +100 RD, unlocks a new weapon in the starting pool
- First time round 20: +250 RD, unlocks the elite card pool (rares appear in drafts)
- First time round 30: +500 RD, unlocks a second starter-perk slot
- First time round 50/75/100: progressively bigger RD payouts + cosmetic title

### Meta progression catalog (initial shape)

What you spend RD on. Tuned to be slow.

- **Weapons** in the starter pool: 250–1000 RD each (4 unlockable weapons past the M1 pistol)
- **Cards** added to the draft pool: 50–200 RD each (~20 unlockable cards)
- **Starter perks** (passive run-start buffs): 300–800 RD each (e.g. "start with +50 tokens", "barrier starts at +20% HP", "first card draft is from 5 cards", "carry +1 max card-deck size")
- **Barrier upgrades** (permanent base-stat improvements): 500–1500 RD per tier
- **Cosmetics** (titles, weapon skins): nice-to-have in v1, primary in v2

### Difficulty curve

Each round, total zombie HP scales as `base * 1.15^round`. Spawn rate scales separately. Composition shifts toward elites over time. Hard caps on simultaneous active zombies (start: 8 alive, grows to 25 by round 20, 40 by round 50) to keep the web build under heap pressure. Curve is asymptotic past round 50 — survivable indefinitely with a good build, but RD-per-round growth slows so players are nudged to start a new run rather than grind a single run forever.

### Save / persistence

- `user://run.save` — current run state (round, deck, weapon, barrier HP, tokens). Wiped on death.
- `user://meta.save` — persistent unlocks, lifetime kills, best round, total tokens, settings.
- Saves are versioned. Both files write atomically (write to `.tmp`, rename).
- On web, these land in IndexedDB. Browser tab close = no data loss as long as the last save fired.

## Architecture (matches CLAUDE.md, expanded)

### Signal vocabulary on `EventBus`

```
signal enemy_killed(enemy, source_weapon, headshot, position)
signal enemy_damaged(enemy, amount, source_weapon)
signal wave_started(round_number, composition)
signal wave_ended(round_number)
signal card_drafted(card_data)
signal card_offered(choices: Array)
signal weapon_fired(weapon, payload: Dictionary)
signal weapon_reloaded(weapon)
signal weapon_swapped(old, new)
signal barrier_damaged(amount, attacker)
signal barrier_destroyed()
signal tokens_changed(new_total, delta)
signal run_started()
signal run_ended(stats: Dictionary)
```

### Data flow (run-time)

```
Player input ─→ Player.gd ─→ WeaponManager.gd ─→ Weapon.gd
                                                      │
                                                      ▼
                                              EventBus.weapon_fired
                                                      │
                                                      ▼
                                              CardSystem.gd ←─ active deck
                                              (mutate payload)
                                                      │
                                                      ▼
                                              Zombie.gd.take_damage()
                                                      │
                                                      ▼
                                              EventBus.enemy_killed / _damaged
                                                      │
                                       ┌──────────────┴──────────────┐
                                       ▼                              ▼
                                  GameState.gd                    HUD.tscn
                                  (tokens, score)               (numbers, FX)
                                       │
                                       ▼
                                  SaveSystem.gd (on wave end)
```

## Milestone ladder

No hard timeline. Each milestone has a definition-of-done; it ships when it's done. Every milestone ends with a GH Pages deploy.

### M0 — Scaffold

**Done = a cube in the browser, save/load works, the deploy pipeline is real.**

- [ ] `git init`, push to `Josh-Buck/<repo-name>`
- [ ] Godot 4.6 project, `.gitignore` (Godot's recommended)
- [ ] Autoloads stubbed: `GameState`, `MetaProgress`, `EventBus`, `AudioMan`, `SaveSystem`, `CardSystem` (each a single file with `func _ready(): print("autoload ready: ", name)`)
- [ ] Test scene: capsule player (no model), one cube enemy, click to "kill" the cube, score increments
- [ ] `SaveSystem` writes a JSON file to `user://meta.save` with the score, reads it on next launch
- [ ] Web export preset: `Web`, single-threaded, Initial Memory 256, PWA off
- [ ] `.github/workflows/deploy.yml` — headless Godot 4.6 export → `peaceiris/actions-gh-pages` → gh-pages branch
- [ ] `.nojekyll` lands at gh-pages root
- [ ] Verify in browser: page loads, score persists across page reload
- [ ] Tag `v0.0.1`

### M1 — Core mechanics

**Done = one weapon, one enemy, one wave, dies on barrier loss. Playable but minimal.**

- [ ] First-person camera, mouse-look spin only (no movement), gamepad right-stick alt input
- [ ] Pointer lock on web (`Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)`)
- [ ] `Weapon.tscn` with one weapon (M1 Pistol): fire, reload, recoil pattern (vertical kick + horizontal drift), ammo, mag size
- [ ] Weapon viewmodel placeholder (textured cube + barrel cylinder is fine — art comes later)
- [ ] `Zombie.tscn` with one type (Walker): NavMesh path toward barrier center, attack barrier on contact, HP, hit reaction
- [ ] `Barrier.tscn`: cylindrical mesh, HP bar, takes damage on zombie touch, dies → game over screen
- [ ] `Arena.tscn`: flat circular floor, sky/ceiling, baked light, spawn ring of 8 spawn points
- [ ] `SpawnRing.gd`: spawns zombies on a timer, single wave of 10
- [ ] HUD: HP (barrier), ammo (current/reserve), wave counter, score
- [ ] One round end → "Wave complete" screen → retry button
- [ ] Wire `EventBus` signals end-to-end (no direct cross-system refs)
- [ ] Deploy. Verify on GH Pages. Tag `v0.1.0`.

### M2 — MVP

**Done = the game loop is real. 3 weapons, 3 enemies, rounds escalate, cards work, save mid-run, audio in.**

- [ ] 3 weapons: Pistol, Combat Shotgun, AR. Each as a `WeaponData.tres`. Distinct fire/reload/recoil feel.
- [ ] WeaponManager: hold 2 weapons, swap with key/button, viewmodel swap animation
- [ ] 3 enemies: Walker, Runner (fast/low-HP), Tank (slow/armored). `EnemyData.tres` each.
- [ ] Wave system: 10+ rounds, scaling composition + count from `WaveData.tres` definitions
- [ ] **Card draft UI** between rounds: 3 cards shown, click to pick, picked card joins active deck
- [ ] **~10 starter cards** working through the effect pipeline:
  - Fire Rate Up, Damage Up, Mag Size Up, Reload Speed Up, Recoil Down (stat boring 5)
  - Marksman, Last Round, Stuffed Shells, Ricochet Rounds, Glass Cannon (interesting 5)
- [ ] Shop wall (every round): spend tokens for ammo top-up, barrier repair, weapon swap (3 random offers)
- [ ] Token economy live, HUD shows count
- [ ] Mid-run save: writes after each `wave_ended`. Reload page → resume.
- [ ] Audio: weapon SFX (3 weapons × shoot/reload), zombie groans + footsteps (3D positional), barrier hit, UI clicks, ambient lab hum
- [ ] First-gesture audio unlock on title screen
- [ ] Title screen: "Start Run" / "Continue Run" (if save exists) / "Settings" / "Quit"
- [ ] Deploy. Verify on GH Pages. Playable end-to-end. Tag `v0.2.0`.

### M3 — v1.0

**Done = a real game. Polish, content depth, meta progression, two arenas.**

- [ ] **Full card pool: 30 cards** — fill out from `docs/ideas.md`. Balance pass.
- [ ] **5 weapons total**: Pistol, Shotgun, AR, SMG, Bolt-Action Rifle
- [ ] **5 enemy types**: Walker, Runner, Tank, Spitter, Exploder
- [ ] **1–2 bosses**: round 10 mini-boss (The Subject), round 20 boss (Site Director)
- [ ] **Meta progression screen**: spend Research Data to unlock 10+ cards, 3 starter perks, 2 barrier upgrades, 2 weapon unlocks
- [ ] **Challenge system**: 20+ challenges across survival / marksmanship / weapon mastery / no-damage / specialist tiers. Persistent tracker with notification on completion.
- [ ] **Round-milestone bonuses live**: in-run (every 5 rounds) + first-time permanent RD payouts
- [ ] **2 arenas**: Containment Lab (M2 holdover) + Cooling Tower (M3 new build)
- [ ] **Game feel polish**:
  - Screen shake (tuned per weapon)
  - Hit pause on crits (3–6 frames)
  - Hit markers + damage numbers
  - Recoil animation on viewmodel
  - Kill streak combo UI (3, 5, 10, 20 kills without barrier damage)
  - Muzzle flash, brass casings, particle blood (toggleable in settings)
  - Footstep audio variance (concrete vs metal grate per arena)
- [ ] **Settings menu**: sensitivity, audio buses, gore toggle, FOV, fullscreen toggle (web)
- [ ] **Death screen** with stats + bank tokens UI
- [ ] **Tutorial prompts** first run only (control hints fade after first interaction)
- [ ] Performance pass: profile on web, target 60fps at peak horde, 256MB heap not breached
- [ ] Final art pass: PBR materials reviewed; if behind, swap to low-PBR fallback (non-blocking)
- [ ] Deploy. Tag `v1.0.0`. Write a short itch.io / blog post style README pointing to the GH Pages URL.

## Content sensitivity guardrails

Modern military + zombies is well-trodden ground; the sensitivity surface is smaller than the 2D project's WWII content. But:

- **No real-world military units, real wars, real geographies as antagonists.** Site Echo-7 is a fictional black-budget research site, deliberately ungeographied. Zombies are "test subjects," not soldiers of any flag.
- **No real-name pharmaceutical / defense contractors.** Even satirically. (Especially given your day job.)
- **Gore toggle in settings.** Default to on; player can disable particles/blood for streaming, accessibility, or preference.
- **No civilian-target framing.** Test subjects are explicitly fictional, infected, hostile. No "this used to be a kid" beats.
- **Audio doesn't include real human screams.** Synthesized / processed only. (Procedural fallback rule pays off here too.)
- **Settings page disclaimer / content note** linkable from the title screen.

## Verification plan

Per milestone, before declaring done:

1. **Browser smoke test** on Chrome + Firefox + Safari on macOS, latest. (Mobile out of scope.)
2. **Heap watch**: open DevTools Memory, peak horde for 30s, confirm < 256 MB.
3. **Save resilience**: start a run, mid-wave hard-refresh, verify resume from last wave end.
4. **Audio gesture**: load page with mute-tab default, verify no AudioContext warnings before click.
5. **Deploy diff**: confirm `.nojekyll` present at gh-pages root, `index.html` is the Godot one, no stray `_includes`.
6. **Performance budget**: peak round profiled with monitor enabled, frame time under 16.6ms 95th percentile.
7. **Save schema**: confirm `version: int` exists, write a quick migration test even if no migration needed yet.

## Open questions (lock these before each milestone they block)

**Blocks M0:**
- [x] Repo name → `site-echo-7` (revisit at v1.0 if a better name surfaces)
- [x] Deploy action → `actions/deploy-pages` (GitHub-official, artifact-based — chosen to learn the cleaner pattern; quality > evening savings)
- [x] Tactical feel → tactical-arcade hybrid (committed for the player)
- [x] Art → full PBR from day 1 (user override; ambition accepted)
- [x] Timeline → no hard deadline (quality > speed)

**Blocks M1:**
- [ ] Sensitivity setting on the gore toggle default — on or off?
- [ ] Gamepad support in M1 (more work in week 2) or M3 (polish phase)?

**Blocks M2:**
- [ ] Card draft: pick-from-3 only, or "skip for X tokens" / "re-roll for Y tokens" UX from day 1?
- [ ] Shop wall: every round, or every 5 rounds?
- [ ] Cards in M2 pool — confirm the 10 above, or swap any?
- [ ] Two-currency UX: do we surface Research Data live during a run, or only at run-end banking?

**Blocks M3:**
- [ ] Boss design: do bosses break out of the spawn-ring-walk pattern (e.g. The Subject leaps onto the barrier itself)? Affects barrier collision design.
- [ ] Challenge UI: notification toast on completion, or a quiet log + dedicated screen? Probably both.
- [ ] How many challenges in v1? Target 20 minimum, 40 ideal.

**Nice to lock when you have a minute:**
- [ ] Working title (also unblocks repo name)
- [ ] Curse cards in v1 or v2?
