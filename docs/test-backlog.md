# Test backlog

Live URL: **https://josh-buck.github.io/site-echo-7/**

Big push just landed — game is now 20 waves long with two bosses, 30 cards, 4 weapons. Delete lines as you verify or message me with broken items.

---

## 🧟 NEW: Zombie footsteps + PBR + perf audit

### Footsteps
- [ ] Walkers produce footsteps roughly every 0.45s while chasing (no steps in IDLE/ATTACK/STAGGER/DIE)
- [ ] Runners are noticeably quicker (~0.22s cadence)
- [ ] Tanks/Directors are slower (~0.6s cadence)
- [ ] Containment Lab (Arena 1) uses concrete samples (a_1..a_4); audibly different from grates
- [ ] Cooling Tower (round 11+) uses metal grate samples (grate_1..grate_4)
- [ ] At peak horde (20+ zombies), the mix is clean — only the closest ~6 zombies emit footsteps; far ones stay silent
- [ ] Footsteps are positional (left/right pan correctly as zombies arc around the barrier)
- [ ] No footsteps from dying zombies during dissolve

### Zombie PBR bodies
- [ ] Walker/Runner/Spitter/Exploder bodies show polymer (matte dark) PBR detail at close range while still reading as their team tint
- [ ] Tank + Director bodies show rusty_steel PBR detail while still reading as their team tint
- [ ] Eye glow (red emissive) is preserved on all archetypes
- [ ] No magenta/missing material warnings at spawn

### Perf audit notes (FYI)
- Per-frame `get_nodes_in_group` audit: only fires inside `_try_play_footstep`, throttled by the footstep interval (≥0.22s), bounded by FOOTSTEP_AUDIBLE_CAP early-out. Acceptable.
- Removed dormant `NavigationAgent3D` from Zombie.tscn — direct steering only, the agent was never used.
- BloodBurst still instances + queue_free per hit. At 25 zombies under sustained fire this is the next perf hotspot — pool candidate if frame time regresses, not refactoring now.
- No AudioStreamPlayer churn; both groan and footstep players are persistent children.

---

## 🔊 NEW: Barrier/arena audio + PBR materials

### Barrier audio
- [ ] Zombie melee on barrier plays a real metallic impact (hit_01/hit_02), positional from attacker direction
- [ ] Heavy hits (Tank, Subject, Director — damage ≥ 12) play the deeper hit_heavy sample
- [ ] At ≤ 25% barrier HP, a quiet looping critical_alarm starts and persists while low
- [ ] Repairing the barrier above 30% HP stops the alarm loop (hysteresis — no chatter at the threshold)
- [ ] Barrier destruction stops the alarm (no orphaned loop after death screen)

### Ambient hum
- [ ] Arena 1 has a low lab_hum_loop ambient at ~-18 dB (audible but not intrusive)
- [ ] CoolingTower (round 11+) has a slightly deeper, slightly louder industrial hum
- [ ] Hum starts on its own once the first user gesture lands (no need to refresh)

### Wave start stinger
- [ ] Rounds 1–4: no stinger (only the existing wave_start chime)
- [ ] Round 5+: tension_stinger.ogg plays at -6 dB at wave start
- [ ] Stinger doesn't clip or distort against the chime

### PBR materials
- [ ] Arena 1 floor shows visible concrete tiling (not stretched, not single-color)
- [ ] Arena 1 perimeter walls show lab_tile detail at close range
- [ ] CoolingTower floor shows concrete; shell shows metal_panel; pipes + girders show rusty_steel
- [ ] No magenta/missing material warnings in console at arena load

---

## 🏅 NEW: Challenge system (M3 first pass)

### Bronze tier
- [ ] Reach round 5 → "First Steps" toast slides in from right, +10 RD
- [ ] First clean round → "Untouched" toast (+10 RD)
- [ ] Land 50 lifetime headshots → "Steady Hand" toast (+10 RD)
- [ ] Hit 100 kills with the M1 Pistol → "Pistol Drills" toast (+10 RD)
- [ ] Hit 100 kills with the Shotgun / AR / Sidearm → respective bronze toast each
- [ ] Hold 8 cards in one run → "Field Library" toast (+10 RD)

### Silver tier
- [ ] Reach round 10 → "Halfway Out" toast (+30 RD)
- [ ] 5 consecutive clean rounds → "Iron Perimeter" toast (+30 RD)
- [ ] 10 headshots in a single round → "On Tap" toast (+30 RD)
- [ ] 250 lifetime headshots → "Marksman" toast
- [ ] Defeat The Subject mini-boss → "Containment Breach" toast
- [ ] Hold 12 cards in one run → "Annotated" toast
- [ ] Hit 500 kills with the Pistol → "Pistol Mastery" toast

### Gold tier
- [ ] Reach round 15 → "Deep Containment" (+75 RD)
- [ ] Reach round 20 → "Site Cleared" (+75 RD)
- [ ] 1000 lifetime headshots → "Headhunter"
- [ ] Reach round 10 without ever taking barrier damage → "Flawless Defense"
- [ ] Hold 15 cards in one run → "Full Dossier"
- [ ] Pistol-only run to round 10 → "Pistol Purist" (and equivalents for shotgun / AR)

### Platinum tier
- [ ] Reach round 30 → "Off the Charts" (+200 RD)
- [ ] Defeat The Director (round 20 boss) → "Site Cleared" platinum toast (+200 RD)
- [ ] 5000 lifetime headshots → "Surgical Strike"

### System / UX
- [ ] Toast slides in from the **right edge**, holds ~3s, fades out
- [ ] Multiple completions in one wave queue and play one after another (no overlap)
- [ ] Each challenge fires **only once** — survives page reload + new run without re-triggering
- [ ] RD payout appears on title screen lifetime stats after completion
- [ ] Wiping save (F12) resets completion state

---

## 🔊 NEW: Zombie audio

- [ ] Idle zombies emit groan sounds at varied 4–10s intervals (positional 3D — louder when close, panned)
- [ ] Three distinct groan samples cycle randomly (no obvious repetition)
- [ ] Groans suppress while a zombie is mid-attack and after death (no groans from corpses)
- [ ] Each melee attack plays a growl on the swing
- [ ] When the swing connects with the barrier, an "attack_hit" sound plays in addition to the growl
- [ ] Suicide (exploder) plays its hit sound + a death sound on detonation
- [ ] Death plays one of two death samples (randomized)
- [ ] Tank/Director sound noticeably lower-pitched than Walkers
- [ ] Runners sound noticeably higher-pitched than Walkers
- [ ] A horde of walkers sounds varied (per-zombie pitch jitter, not monotone)
- [ ] Distant zombies audibly quieter than near ones (positional falloff with max_distance ~30)

---

## 🔊 NEW: UI audio

- [ ] Title screen: hovering Start/Meta/Settings plays a hover blip; clicking plays a click
- [ ] Settings screen: hover + click on Back button play hover/click respectively
- [ ] Meta screen: hover on affordable unlock buttons plays hover; purchase plays a confirm "ding"; Back plays click
- [ ] Pause menu: hover + click feedback on Resume and Return-to-Menu buttons
- [ ] Card draft: panel appearance plays a "draft appear" whoosh; each card flips in with a staggered card-flip sound; hovering or focusing a card plays hover; picking a card plays confirm; Skip plays click
- [ ] Shop: hover on offers plays hover; purchase plays confirm; Continue plays click
- [ ] Wave Complete: hover + click on Next Wave and Restart buttons
- [ ] Death screen: hover + click on Bank & Return button
- [ ] Challenge toast: each toast pop plays a confirm/ding (queued toasts each ding once)
- [ ] No double-sound or stale "play_sfx('ui_click')" residual anywhere in the UI

---

## 🆕 NEW: Death screen + combo UI (this session)

### Death screen
- [ ] When barrier hits 0, a dedicated **DeathScreen** overlay shows (red-bordered panel, not the old WaveComplete)
- [ ] Title reads "BARRIER BREACHED" with subtitle "Site Echo 7 lost containment."
- [ ] Stats grid shows: Rounds Survived, Total Kills, Tokens Earned, Tokens Unspent
- [ ] "Kills by type" line lists each enemy display name with ×N count
- [ ] "Top cards" line lists up to 3 most-used cards (cards equipped during the most kills)
- [ ] "Research Data banked" line **counts up** from 0 to the final earned amount
- [ ] RD earned matches `floor(tokens/10) × (1 + 0.05·round)` + milestone bonus (40 / 100 / 300 at rounds 10 / 15 / 20)
- [ ] Pressing **BANK & RETURN TO TITLE** returns to title screen, and the title's lifetime RD reflects the new total
- [ ] Reaching wave 20 victory also shows DeathScreen with "SITE ECHO 7 CONTAINED" title
- [ ] Old WaveComplete no longer appears on death (only the new DeathScreen does)

### Kill-streak combo UI
- [ ] Streak label appears at **3 kills** with text "STREAK ×3" (yellow)
- [ ] At **5 kills** it flips to "RAMPAGE ×5" (orange, larger) with a tween-in pop
- [ ] At **10 kills** it flips to "UNSTOPPABLE ×10" (darker orange, even larger) with pop
- [ ] At **20 kills** it flips to "ECHO LEGEND ×20" (magenta, biggest) with pop
- [ ] Any barrier_damaged event **silently resets** the streak (label vanishes, no audio)
- [ ] Streak label doesn't visually overlap the WAVE counter or boss banner

---

## 🏭 NEW: Cooling Tower arena (second map)

- [ ] **Round 10 → 11 transition**: when wave 10 ends, the arena visibly swaps — floor + walls + lighting all change before wave 11 begins
- [ ] **Cooling Tower look**: bluish ambient, tall cylindrical shell visible above, central overhead vent fan with two spinning blades, perimeter pipes ring the floor, low metallic outer walls
- [ ] **Vent fan animation**: blades rotate continuously, overhead vent lamp pulses brighter/dimmer as the fan sweeps shadow across it
- [ ] **Vent flicker**: occasional brief stutter on the overhead lamp (replaces fluorescent flicker)
- [ ] **Bluish dust motes** floating in air (vs warm motes in Containment Lab)
- [ ] **Spawn ring still works** — zombies on wave 11 spawn from the new arena's 8 spawn points (not the destroyed old arena's)
- [ ] **Barrier still at center**, full HP after swap (because lull auto-repair already brought it to 100% before swap)
- [ ] **No console errors** during the arena swap
- [ ] **Run from wave 1 to wave 11 unbroken** — no softlock, gameplay loop identical (cards, shop, HUD)
- [ ] **Performance** holds in Cooling Tower at peak wave 17–20 (more geometry than Lab — verify no FPS regression)

---

## 🎆 NEW: Visual feel pass (this session)

### Weapon VFX
- [ ] **Muzzle flash** is bright and visible at the barrel each shot (not just a faint glow)
- [ ] **Bullet tracer** — golden line streaks from gun to hit point on every shot (shotgun = one per pellet)
- [ ] **Impact sparks** burst on the floor / barrier where shots land (no sparks on zombie hits — those are blood)

### Enemy VFX
- [ ] **Blood burst** on every zombie hit, intensified on headshots
- [ ] **Death dissolve** — zombies slump, fade alpha to 0, and shrink instead of vanishing
- [ ] Headshot kills feel noticeably more visceral than body kills

### Arena atmosphere
- [ ] **Fog** — distant spawn points are hazy / atmospheric, not crisp against void
- [ ] **Perimeter walls** — ring of grey wall segments visible around the arena, with a few gaps suggesting corridors
- [ ] **Dust motes** — faint floating particles in the air around the barrier
- [ ] **Fluorescent flicker** — east/west ceiling lights stutter briefly every few seconds

### HUD juice
- [ ] **Hit marker** flashes white on hit, red+bigger on kill, yellow+biggest on headshot kill
- [ ] **Low-HP vignette** — red haze pulses around screen edge when barrier HP < 30%, fades out when repaired above 30%
- [ ] **Damage direction arrow** — red ▲ briefly appears near screen edge pointing toward the zombie that hit the barrier (test by letting a zombie attack from behind / sides)

### Perf
- [ ] Wave 17–20 still holds framerate with all the new particles + dust + tracers active

---

## 🔴 CRITICAL — verify these end-to-end then we can polish

### The fixes you reported broken
- [ ] **Menus actually isolate from the game now** (tree-paused while card draft / shop / wave complete are open — zombies freeze, weapon won't fire, ammo doesn't decrement on UI clicks)
- [ ] **Zombies actually move** toward the barrier (rewrote to direct steering — no longer dependent on the navmesh which was silently failing)
- [ ] **Marksman headshot refund is now 1 round to reserve** (was 2 to mag — too OP)
- [ ] **Zombies have visible glowing eyes** (red for Walker, orange for Runner, blue for Tank, etc.)
- [ ] **No duplicate cards** appear in drafts within a run

### New: Backup Sidearm — your no-softlock fallback
- [ ] Press `4` to swap to the **Sidearm** — appears in slot 4
- [ ] HUD reserve count shows **∞** for the Sidearm
- [ ] Sidearm feels weak (6 dmg, slow, small mag) but never runs out of ammo
- [ ] Even with all 3 main guns dry, you can still kill zombies with the Sidearm

### New: The Director (Round 20 final boss)
- [ ] Wave 10 starts → mini-boss banner "MINI-BOSS: THE SUBJECT"
- [ ] Wave 15 → "THE SUBJECT RETURNS" banner (Subject reappears mid-late game)
- [ ] Wave 19 → "TWO OF THEM" banner (double Subject)
- [ ] Wave 20 → "FINAL BOSS: THE DIRECTOR" banner — bigger than Subject, dark red, very high HP
- [ ] After clearing wave 20 → "ALL WAVES SURVIVED" with +300 RD bonus visible on title screen lifetime stats

### First-run tutorial
- [ ] On a fresh save (F12 wipes it), Wave 1 shows a control hint panel at top-left
- [ ] Panel fades after ~5 kills or 25 seconds
- [ ] On subsequent runs, the panel does NOT reappear

---

## 🟢 NICE-TO-VERIFY (when convenient)

- **30 cards now**: should see variety, no duplicates within a run, lifesteal "Vampire Rounds" actually heals the barrier on every kill, "The Edge" is a multi-stat legendary
- **5 enemy types** + 2 boss types are visually distinct (different sizes + colors + eyes)
- **Shop offers** apply correctly (ammo top-up, barrier repair, full resupply, speed loader, field welder)
- **Meta progression** purchases stick across runs (Combat Veteran starts you with 20 tokens, Reinforced Barrier gives +20% HP, etc.)
- **Settings** sensitivity slider persists across reloads (you said this works)
- **Pause menu** ESC works mid-game (you said this works)

---

## 🔊 Audio wire-up

- [ ] Pistol — firing plays the CC0 pistol_shoot sample (no longer the synth white-noise pop)
- [ ] AR — firing plays the ar_shoot sample on every bullet, full-auto sequences sound varied (pitch jitter)
- [ ] Shotgun — firing plays the shotgun_shoot sample (one play per trigger pull, not per pellet)
- [ ] Sidearm — firing plays the sidearm_shoot sample
- [ ] Back-to-back shots sound non-mechanical (±5% pitch randomization audibly present)
- [ ] Reload sound starts the moment R is pressed, not when the reload completes
- [ ] Swapping weapons mid-reload cuts the reload sound (no orphan reload audio after swap-cancel)
- [ ] Each weapon's reload sound matches the weapon (pistol vs shotgun vs AR vs sidearm)
- [ ] No double-sound (no synth fire SFX layered on top of the real sample)
- [ ] Audio levels reasonable — fire SFX not crushing other sounds; master-volume slider still controls them

### Handoff (NOT done in this pass)
- Zombie footstep audio — Zombie.tscn already has a NavigationAgent3D + AudioPlayer3D + sample ext_resources wired by the AI architect, but Zombie.gd hasn't caught up. Skipped to avoid colliding mid-edit. Route to `zombie-ai-architect`.

---

## 📋 STRESS / OPS

- Wave 17–20 with 22 active enemies — framerate hold?
- DevTools Console for red errors during the bigger waves
- Try Chrome vs Safari

---

## 🌐 Web build verification (run after next deploy)

These are browser-side checks for the deploy/export pipeline. Run in Chrome first, then Firefox, then Safari. Paste DevTools Console output for any failure.

### Build pipeline
- [ ] GH Actions workflow succeeds end to end (build job + deploy job both green)
- [ ] Live URL https://josh-buck.github.io/site-echo-7/ loads without 404 on the page itself
- [ ] DevTools Network tab: `index.pck` is < 80 MB gzipped (check "Transfer" column — that's compressed size)
- [ ] No 404s on any `.png`, `.ogg`, `.wasm`, `.pck`, or `index.*` asset (.nojekyll working)

### Boot console output
- [ ] Console shows `[SaveSystem] ready`, `[AudioMan] ready`, `[ChallengeTracker] ready` in that order
- [ ] **`[ChallengeTracker] loaded 28 challenges`** (CRITICAL — if it says 0, the `DirAccess.open("res://...")` enumeration failed under web PCK; see findings)
- [ ] No red errors / parse errors / "Cannot infer type" / "ext_resource not found" in console
- [ ] No "AudioContext was prevented from starting" warnings after first click on title screen
- [ ] No WebGL2 warnings (Safari is the suspect here)

### Challenges (the one most at risk)
- [ ] Reach round 5 → "First Steps" toast actually triggers in-browser (proves challenges loaded from PCK)
- [ ] Page reload after completing a bronze → toast does NOT re-fire (proves MetaProgress save round-tripped through IndexedDB)
- [ ] If 28 challenges did NOT load, fall back to a static `const CHALLENGE_PATHS := [...]` list — flag in the report

### Saves on web
- [ ] Earn RD, refresh the tab, RD persists (IndexedDB working)
- [ ] No `[SaveSystem] failed to open` errors after first save
- [ ] After save, console does NOT show repeated `DirAccess.rename_absolute` errors (would indicate the fallback path runs every save — works but spammy)

### Audio gating
- [ ] No audio before first click on title screen (browsers block AudioContext pre-gesture)
- [ ] After first click, ambient hum starts and all SFX become audible
- [ ] Master volume slider in Settings affects level live in-browser

### Renderer + memory
- [ ] No "VRAM compression" warnings on texture loads
- [ ] PBR materials look the same in browser as in editor (lab_tile, concrete, rusty_steel)
- [ ] DevTools Memory tab: heap stays under ~256 MB at peak wave 20 (we set Initial Memory to 256 MB; growth beyond requires extra)
- [ ] Frame rate at wave 17–20 holds ≥ 45 FPS on Chrome desktop

### Browser matrix
- [ ] Chrome desktop: full run to wave 20 with no console errors
- [ ] Firefox: barrier saves persist (Firefox's stricter IDB quota can silently fail)
- [ ] Safari: at minimum loads + plays wave 1 (Safari WebGL2 is the worst — document any breakage rather than spending evenings fixing)

### Audio pool stress
- [ ] Peak wave 20 (Tank + Director + 20 walkers + AR full-auto + barrier hits): no stuttering, no truncated SFX (validates 16/16 pool is sufficient)
- [ ] If you hear SFX cut off mid-play, bump `POOL_SIZE` in AudioMan.gd from 16 → 24

---

## How to report

Paste a screenshot + console log on critical failures. Otherwise just delete lines.

When CRITICAL is all green, the next building targets:
1. Second arena (visual variety — same gameplay loop, different look)
2. Real art pass on weapons / zombies / barrier
3. Performance pass if needed
4. Polish (kill streak combo, hit pause on crits, more particles)
