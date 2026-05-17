# Test backlog

Live URL: **https://josh-buck.github.io/site-echo-7/**

When you verify an item, **delete the line** — keeps the list tight. When you find a bug, paste a screenshot + (optionally) DevTools Console output.

DevTools Console: Safari → Settings → Advanced → "Show features for web developers" → Develop menu → Show JavaScript Console. Or Chrome (Cmd+Option+J).

---

## 🔴 CRITICAL — these block more building

If any of these fail, paste the symptom and I'll fix before adding more features.

### Core run loop
- [ ] **START RUN** → gameplay starts, cursor captures after first click
- [ ] **Wave 1 → card draft → SHOP → CONTINUE → WAVE COMPLETE → NEXT WAVE** all advance correctly
- [ ] **Wave 10 win** shows "ALL WAVES SURVIVED"; **barrier breach** shows "BARRIER BREACHED"
- [ ] **RETURN TO MENU** goes to title screen, lifetime stats updated

### Pause + menu navigation (M3e — just shipped)
- [ ] **ESC during gameplay** → PAUSE overlay, zombies freeze, weapon stops
- [ ] **ESC again (or RESUME)** unpauses, cursor recaptures
- [ ] **ESC on Settings or Meta Progression screen** returns to title (also a BACK button)

### Input bleed-through (M3d — just shipped)
- [ ] Clicking buttons in card draft / shop / wave complete **does NOT fire the weapon**
- [ ] Click that closes a menu also doesn't fire — next click after that does

### Weapons + enemies
- [ ] Weapon swap with `1` / `2` / `3` / `Q` works
- [ ] One card visibly affects weapon feel after pick (any stat card)

---

## 🟢 NICE-TO-VERIFY — won't block development

### M3d enemies (just shipped)
- Exploder (wave 4+): smaller, orange eyes, detonates on barrier contact
- Spitter (wave 6+): green, stops far away, fires glowing acid projectile
- Within a wave, enemy types appear shuffled (mixed order)

### M3c new cards (pool of 20)
- Stockpile, Heavy Mag, Lightweight, Magnum Frame, Surgical, Berserker, Sniper, Field Specialist, Glass Cannon, Field Trauma — appear in drafts with visible effects
- Legendary cards in gold, Curse cards in purple

### M3b meta progression
- Combat Veteran (+20 tokens at run start), Reinforced Barrier (+20% HP), Quick Draft (5 cards first draft), Quartermaster (1 free card), Barrier Plating I/II/III (+10/+20/+30 HP, stacking)

### M3a game feel
- Screen shake on weapon fire and barrier hit
- Muzzle flash light at barrel
- Floating damage numbers (orange + larger on headshots)
- Red `x` hit marker

### M2c3 audio (low priority — bump volume up first)
- Pistol / Shotgun / AR have distinct fire sounds
- Zombie groans are positional
- Wave-start sting at the beginning of each wave

### M2b card details
- Marksman: headshot kills refund 2 ammo
- Last Round: final bullet does 3× damage

### Shop offers (M2c2)
- Ammo Top-Up, Speed Loader, Barrier Repair, Field Welder, Full Resupply — verify effects when bought

### Settings
- Master Volume slider — not tested, low priority

---

## 📋 STRESS / OPS (don't gate on these)

- Wave 8+ with all 5 enemy types — framerate holds?
- DevTools Memory: WASM heap < 256 MB at peak?
- DevTools Console: persistent red errors during normal play?
- Try Chrome and Firefox — Safari is known to be picky

---

## How to report

- Critical bug → screenshot + console paste → I fix immediately, then continue
- Nice-to-fix → tell me when convenient, I'll batch
- Item works → delete the line
- Item I shouldn't bother testing → tell me, I'll remove
