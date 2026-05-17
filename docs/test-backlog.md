# Test backlog

Stuff to verify on the live build when you get back to playing. Mark items as you confirm them. New items get appended to the top under their milestone.

Live URL: **https://josh-buck.github.io/site-echo-7/**

Quick reset shortcuts in-game:
- Click anywhere in browser to capture cursor
- `ESC` releases cursor
- `F12` wipes the save (dev only)

---

## M3a — game feel polish (latest deploy)

### Visual feedback
- [ ] **Screen shake** on pistol fire (small), shotgun fire (heavy), AR full-auto (constant low-level shake)
- [ ] **Screen shake** on barrier damage scales with hit size
- [ ] **Big screen shake** on barrier destruction
- [ ] **Muzzle flash** — warm orange light pulses from weapon barrel on each shot (visible especially on shotgun in dark areas)
- [ ] **Damage numbers** — white numbers float up from each zombie hit, fade out over ~0.8s
- [ ] **Headshot damage numbers** — render orange and larger
- [ ] **Hit marker** — red `x` appears briefly at crosshair when you successfully hit a zombie
- [ ] Hit feedback feels responsive (not delayed)

### Combo testing
- [ ] Pick "Steady Hand" card (recoil -50%) → screen shake noticeably reduced
- [ ] Headshot a Tank → big orange "55" or so damage number with hit marker

---

## M2c3 — procedural audio

All sounds are GDScript-synthesized AudioStreamWAVs (no external assets). Should work in the browser after the first click (audio gating).

### Audio inventory
- [ ] **Pistol fire** — sharp crack, plays per shot
- [ ] **Shotgun fire** — deeper boom with low-end thump
- [ ] **AR fire** — short rapid pops during full-auto
- [ ] **Reload** — two clicks + slide sound on R
- [ ] **Zombie groan** — periodic low growl from each zombie (every 5–11s, only while alive). 3D positional — should sound louder when zombies are close.
- [ ] **Zombie death** — descending groan on kill
- [ ] **Barrier hit** — metallic clang when zombies attack the barrier
- [ ] **Barrier destroyed** — low rumble + crash when barrier hits 0 HP
- [ ] **Wave start sting** — rising tone when a new wave begins
- [ ] **Card pick** — ascending chirp on card selection
- [ ] **Shop open** — chord on opening the shop
- [ ] **UI clicks** — short blip on Start Run, card pick, shop buy, continue, next wave, retry

### Verification checks
- [ ] First click on title screen → quiet UI click. Subsequent UI interactions all click.
- [ ] Wave 1 starts → rising tone audible
- [ ] Walker zombies groan with positional pan (spin the player toward/away from one — should change)
- [ ] Pistol vs Shotgun vs AR have distinctly different fire sounds
- [ ] Zombie death sound plays on every kill at the zombie's location
- [ ] No audio plays before the very first user click (web autoplay gate)
- [ ] No audio crashes / no Console errors related to AudioStreamWAV

---

## M2c1 + M2c2 — title screen, shop wall, RD banking

### Title screen
- [x] Page now opens to a black title screen "SITE ECHO 7" ← verified
- [x] Lifetime stats visible (kills, best wave, research data) ← verified
- [ ] "START RUN" button captures pointer + loads gameplay ← **fixed in latest push** — Background panel was eating clicks. Added mouse_filter=IGNORE + fullscreen click fallback. Retry on next deploy.
- [ ] After dying or quitting back, title screen reappears with updated lifetime stats

### Shop wall flow (between waves)
- [ ] Complete wave → card draft appears
- [ ] Pick (or skip) a card → "REQUISITIONS WALL" appears next
- [ ] Shop shows 3 random offers from the pool of 5 (Ammo Top-Up, Barrier Repair, Full Resupply, Field Welder, Speed Loader)
- [ ] Offer buttons display name + description + cost; disabled (grayed out) when you can't afford
- [ ] Click affordable offer → tokens deduct, effect applies, button disappears
- [ ] Can buy multiple offers if you can afford
- [ ] CONTINUE button closes shop → "WAVE COMPLETE" summary panel → NEXT WAVE button

### Shop offer effects
- [ ] **Ammo Top-Up** (30 tokens): active weapon's reserve refills to max
- [ ] **Speed Loader** (20 tokens): current mag refills (does not consume reserve normally)
- [ ] **Barrier Repair** (50 tokens): barrier HP goes up by 30
- [ ] **Field Welder** (150 tokens): barrier HP goes to full
- [ ] **Full Resupply** (75 tokens): ALL three weapons' reserves refill to max

### Run end → Research Data
- [ ] When barrier breaks → "BARRIER BREACHED" appears; tokens convert to Research Data with a small per-round bonus
- [ ] Title screen "Research Data" stat increases between runs
- [ ] RETURN TO MENU goes back to title (not retry-in-place)

---

## M2b — card system

### Card draft flow
- [ ] Wave 1 completes → a full-screen overlay appears titled "RESEARCH NOTES RECOVERED"
- [ ] 3 cards are displayed side-by-side, each with a rarity tag (COMMON / RARE), name, description, and effect summary
- [ ] Common cards display in light gray, Rare cards display in **blue**
- [ ] Clicking a card picks it; overlay closes; WAVE COMPLETE summary panel appears
- [ ] After the draft pick, the DECK line at bottom-left of HUD shows the picked card's name
- [ ] Each subsequent wave (2, 3, 4, ...) offers a fresh draft of 3 cards
- [ ] "Skip Draft" button at the bottom passes without picking (deck doesn't grow)
- [ ] Deck accumulates across waves — by wave 5 the DECK line should have 4+ cards in it (skip a few if you want fewer)

### Stat-card effects (pick the card, then verify the effect)
- [ ] **Quick Trigger I** (Fire Rate +25%): weapons fire noticeably faster after pick
- [ ] **Hollow Points** (Damage +30%): hits drop zombies in fewer shots
- [ ] **Extended Mag** (Mag +50%): pistol HUD shows 18 / N instead of 12 / N after reload
- [ ] **Quick Hands** (Reload +67%): reload animation/timer noticeably shorter
- [ ] **Steady Hand** (Recoil -50%): pistol viewmodel kicks half as much; AR is much more controllable
- [ ] **Bandolier** (Reserve +50%): pistol HUD shows higher reserve cap (e.g. 180 instead of 120)
- [ ] **Headstrong** (Headshot +40%): visible spike in damage on a headshot

### Conditional cards
- [ ] **Marksman** (headshot kills refund 2 ammo): kill a zombie with a headshot, watch current_ammo go UP by 2 after the kill
- [ ] **Last Round** (final bullet 3× damage): fire down to current_ammo == 1, then fire — that last shot should one-shot a Walker even without other damage cards

### Combos
- [ ] Pick Quick Trigger + Hollow Points + Steady Hand → dramatically smoother+stronger weapon feel
- [ ] Pick Adrenaline + Quick Trigger → noticeable double fire rate boost (compound multiplication: 1.15 × 1.25 = ~1.44)

### Edge cases
- [ ] Card draft works after the very last wave (wave 10 → ALL WAVES SURVIVED) — currently the run-ends overlay should still appear
- [ ] Reloading after picking Extended Mag fills you to 18, not 12

---

## M2a — weapons, enemies, waves, tokens

### Weapons
- [ ] Pistol (slot 1) fires single shot, 12 mag, semi-auto
- [ ] Shotgun (slot 2) fires 8 pellets in a spread; one-shots a Walker at point-blank
- [ ] AR (slot 3) is full-auto (hold left-click to keep firing)
- [ ] Press `1` / `2` / `3` to swap directly to a weapon
- [ ] Press `Q` to cycle to the next weapon
- [ ] Weapon name appears in HUD under the ammo counter when you swap
- [ ] Each weapon maintains its own ammo state across swaps (i.e. swap away mid-mag, come back, mag is still partial)
- [ ] Reload key `R` reloads the active weapon only
- [ ] Out-of-ammo: pulling the trigger triggers a reload automatically

### Enemies
- [ ] Walker (default brown) appears in wave 1+, moves slow (~1.5 m/s)
- [ ] Runner (smaller, orange eyes) appears wave 3+, **3× faster** than Walker
- [ ] Tank (larger, blue eyes) appears wave 5+, slow but tanky — body shots feel weak
- [ ] Headshot a Tank → damage bypasses armor and feels normal (high)
- [ ] Tank gives more tokens than Runner gives more than Walker (5 / 2 / 1)

### Waves & flow
- [ ] Wave 1 completes → "WAVE 1 COMPLETE" overlay appears with NEXT WAVE + RESTART buttons
- [ ] NEXT WAVE button advances to wave 2, mouse re-captures, gameplay resumes
- [ ] Wave counter at top of HUD updates to current round
- [ ] Wave 5 introduces Tanks (1 tank in composition)
- [ ] Wave 10 is the heaviest (24 walkers + 20 runners + 7 tanks)
- [ ] After wave 10 completes → "ALL WAVES SURVIVED" overlay with PLAY AGAIN
- [ ] If barrier reaches 0 HP → "BARRIER BREACHED" overlay, only RETRY button (no NEXT WAVE)

### Tokens & HUD
- [ ] TOKENS counter top-right of HUD updates as you kill zombies
- [ ] HP bar (top-left) updates when zombies attack the barrier
- [ ] Score counter (kill count) under TOKENS
- [ ] HUD shows `RELOADING...` while reloading

### Stress test
- [ ] Play through wave 8+ with all three enemy types — does framerate hold?
- [ ] DevTools Memory tab — does WASM heap stay below 256 MB at peak?

---

## M1 — first-person + barrier + single wave (already verified, sanity check)

- [x] Click to capture pointer
- [x] Mouse motion spins camera
- [x] Click / SPACE fires
- [x] Save persists across reload
- [x] Barrier breach triggers game-over

---

## General things to watch for (any build)

- [ ] **Browser DevTools Console** — open it, are there any red errors during play?
- [ ] **Audio gating** — once we add audio (M2c), confirm nothing plays before first click
- [ ] **Mobile/touch** — if you accidentally open on phone: known not-supported, should fail gracefully
- [ ] **Cross-browser** — does it work in Firefox? Safari is the usual breaker.

---

## How to report issues

When you find something broken:

1. **Take a screenshot** (Cmd+Shift+4 → drag) and paste into chat
2. **Open DevTools Console** (right-click → Inspect → Console) and copy any red error text
3. Tell me the wave number / what you were doing when it broke

I'll patch and push. Tag deploys with the issue you found so we can re-test.
