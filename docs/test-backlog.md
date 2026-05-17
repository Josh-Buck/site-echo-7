# Test backlog

Stuff to verify on the live build when you get back to playing. Mark items as you confirm them. New items get appended to the top under their milestone.

Live URL: **https://josh-buck.github.io/site-echo-7/**

Quick reset shortcuts in-game:
- Click anywhere in browser to capture cursor
- `ESC` releases cursor
- `F12` wipes the save (dev only)

---

## M2a — weapons, enemies, waves, tokens (latest deploy)

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
