# Test backlog

Live URL: **https://josh-buck.github.io/site-echo-7/**

Big push just landed — game is now 20 waves long with two bosses, 30 cards, 4 weapons. Delete lines as you verify or message me with broken items.

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

## 📋 STRESS / OPS

- Wave 17–20 with 22 active enemies — framerate hold?
- DevTools Console for red errors during the bigger waves
- Try Chrome vs Safari

---

## How to report

Paste a screenshot + console log on critical failures. Otherwise just delete lines.

When CRITICAL is all green, the next building targets:
1. Second arena (visual variety — same gameplay loop, different look)
2. Real art pass on weapons / zombies / barrier
3. Performance pass if needed
4. Polish (kill streak combo, hit pause on crits, more particles)
