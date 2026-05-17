# Ideas parking lot

Stuff that's NOT in v1 (or not yet decided). Park here so the code stays clean. Promote to a real spec only when a milestone explicitly pulls it in.

## Working title

**Picked for now: Site Echo 7.** Repo slug: `site-echo-7`. Revisit before v1.0 — if a punchier name surfaces during build, swap.

Backup candidates (kept here in case Site Echo 7 starts feeling too on-the-nose during M2):
- **Last Draw** — double meaning: last card drawn, last gunslinger drawn, last stand
- **Deckbound** — punchy, evokes the hook directly
- **Cardlocked** — describes the loop literally
- **Drawn Round** — pun on cards and waves, possibly too clever
- **Spin Cycle** — leans on the 360° defense, may undersell
- **The Reload** — clean, on-theme, slightly generic
- **Quartermaster** — fits the research-notes-as-cards framing

## Card ideas (build the M2 draft pool from this)

### Stat cards (boring but necessary)
- Fire Rate Up I / II / III (+15% / +30% / +50%)
- Damage Up I / II / III
- Mag Size Up (+25% / +50% / +100%)
- Reload Speed Up (+20% / +40%)
- Recoil Down (-30% / -60%)
- Reserve Ammo Up
- Movement... oh wait, no movement. Spin speed up?

### Conditional cards (more interesting)
- **Marksman:** headshots refund 2 ammo to the magazine
- **Adrenaline:** kills within 1s of a reload boost fire rate 50% for 3s
- **Last Round:** the final bullet in a magazine deals 3× damage
- **Overpressure:** first 3 shots after a reload pierce armor
- **Lifesteal:** every 10th kill restores 1 barrier HP
- **Field Surgeon:** kills while reloading speed up the reload
- **Tunnel Vision:** zoomed-in shots gain +50% damage but spin speed drops while zoomed
- **Cold Barrel:** first shot after a pause (1s+) crits

### Compound cards (the fun ones)
- **Stuffed Shells:** shotgun also fires a frag grenade every 4th shell
- **Ricochet Rounds:** pistol bullets bounce once
- **Through-and-through:** AR bullets penetrate up to 2 enemies
- **Sidearm Smith:** pistol gains automatic fire (but ammo halves)
- **Demolitions:** melee kills detonate the corpse
- **Skullsplitter:** headshots cause a 1m AOE
- **Magnet:** kills pull dropped ammo toward the player… (wait, no drops. Skip or redesign.)
- **Stim Mag:** reloading also heals 1 barrier HP

### Synergy cards (deck-building emerges)
- **Pyromania:** if you hold 3+ "fire" cards, all bullets ignite enemies
- **Surgical:** if all your cards are "precision," headshots one-shot non-elites
- **Cluster Fuck:** if you hold 3+ "explosive" cards, frags spawn child frags

### Curse cards (high-risk high-reward)
- **Glass Cannon:** +100% damage dealt, +100% damage taken
- **Reload Rouletter:** 25% chance reload takes 2× as long, 75% chance instant reload
- **Last Stand Only:** ammo is unlimited but reloading is disabled — you only have one mag
- **Frenzy:** zombies move 30% faster but grant 50% more tokens

### Weapon-mod cards (swap how a weapon fundamentally works)
- **Drum Mag (AR):** mag size 3×, reload time 3×
- **Slug Rounds (Shotgun):** spread becomes single high-damage projectile, range 3×
- **Suppressor (Pistol):** silenced — zombies aggro slower (matters if we add stealth zombies)

## Weapon ideas

### v1 loadout pool
- M1 Pistol (starter, infinite reserve)
- Combat Shotgun
- Assault Rifle
- SMG
- Bolt-Action Rifle (high damage, slow rate, scope)

### v1.x / v2 candidates
- Crossbow (silent, retrievable bolts)
- Flamethrower (DOT, short range)
- Grenade Launcher (limited reserves, big AOE)
- Sentry Turret (deployable, defends a 90° arc — partial movement substitute)
- Tesla Coil (chain-lightning to nearby enemies)
- Sword / Riot Shield (melee with parry)

## Enemy ideas

### v1 roster
- **Walker** — slow, baseline. Round 1+.
- **Runner** — fast, low HP. Round 6+.
- **Tank** — slow, armored, high HP. Round 10+.
- **Spitter** — ranged, acid spit damages barrier from a distance. Round 12+.
- **Exploder** — runs at barrier, detonates. Round 8+.

### v1.x / v2
- **Lurker** — invisible until close, audio cue only (pairs with the "audio-first" hook we didn't pick but could still bake in)
- **Carrier** — spawns mini-zombies on death
- **Screamer** — buffs nearby zombies' speed
- **Crawler** — short, hard to hit, fast

## Boss ideas

- **Round 10 mini-boss: The Subject** — escaped test subject, fast, leaping attacks
- **Round 20 boss: Site Director (Zombified)** — multi-phase, summons adds, weak point is a glowing nape
- **Round 30+: The Source** — actually breaks the barrier on contact, must be killed before it touches

## Arena ideas

### v1
- **Containment Lab** — circular biolab, frosted glass walls, emergency lighting strobing
- **Cooling Tower** (M3 stretch) — outdoor, fog, wind audio, taller silhouettes against sky

### v1.x / v2
- **Reactor Room** — radiation hazard zones modify gameplay
- **Helipad** — open sky, weather effects
- **Mess Hall** — interior, tight sightlines

## Meta-progression unlock tree ideas

(Costs in Research Data, the persistent currency. Slow on purpose.)

- **Card Pool Tier 1:** 200 RD — adds 5 new draft cards
- **Card Pool Tier 2:** 600 RD — adds 5 more, including synergies
- **Weapon Unlocks:** Each new weapon costs 250–1000 RD (4 total post-pistol)
- **Starter Perks:** Pick 1 of 3 at run start — e.g. "start with +50 tokens," "barrier +20% HP," "first card draft is from 5 cards," "deck size +1 max"
- **Barrier Upgrades:** Permanent — +max HP (tier 1/2/3 at 500/1000/1500 RD), +repair rate, +regen between waves
- **Cosmetics:** Titles unlocked by challenges, weapon skins by deep-round milestones (nice-to-have v1, primary v2)

## Challenge ideas

(Each challenge tier grants flat RD: bronze 10, silver 30, gold 75, platinum 200. Stacks on top of run-end RD banking.)

### Survival tier
- Reach round 5 / 10 / 15 / 20 / 30 / 50 / 75 / 100 (each is its own challenge)
- Survive an entire run without using the shop wall
- Survive an entire run on the starter pistol only

### Marksmanship tier
- Headshot 50 / 250 / 1000 / 5000 zombies (lifetime)
- 10 consecutive headshots in a single round
- 100 consecutive shots without a miss
- One-shot a Tank with a headshot

### Weapon mastery tier (one per weapon)
- 100 / 500 / 2000 kills with the [Pistol / Shotgun / AR / SMG / Bolt-Action]
- Score the gold tier on a weapon mastery challenge to unlock that weapon's "mastery skin"

### No-damage tier
- Survive a single round without barrier damage
- Survive 5 consecutive rounds without barrier damage
- Reach round 10 without ever taking barrier damage
- Complete a full run without barrier damage (platinum)

### Card challenges
- Have a deck of 8+ / 12+ / 15+ / 20+ cards in one run
- Trigger every synergy card at least once across your account history
- Win a run with at least one curse card active

### Specialist runs
- Reach round 10 using only the [Pistol / Shotgun / AR / etc.]
- Reach round 15 with no stat-boost cards in your deck
- Reach round 10 with a deck of fewer than 3 cards (minimalist)

### Speedrunner tier
- Clear round 5 in under 60 seconds
- Clear round 10 in under 30 seconds (with appropriate firepower)

### Discovery tier
- Defeat the first mini-boss
- Defeat the first full boss
- Survive 10 rounds in each arena

### Joke / flavor tier (small RD, big satisfaction)
- Kill 100 zombies with melee only
- Take a screenshot of your deck at round 20+ (auto-unlock via UI button)
- Die in round 1 (granted free; teaches the meta-banking loop)

## Hook variations we could layer in later

- **Audio cues are mandatory:** zombies offscreen don't appear on a compass — only audio tells you. Could be a hard-mode toggle.
- **Research notes lore:** Each card has a sentence of in-fiction context. Builds a paranoia narrative across many runs.
- **Daily seed:** same card pool / wave seed every day across all players (no leaderboard, just shared experience). Pure GDScript randomness with seeded RNG — easy to bolt on.

## Things to investigate (not commit to)

- Godot 4.6 web export with PBR — real-world build size and load time benchmarks
- KTX2 vs WebP for texture compression in Godot web
- Audio bus mixing on single-threaded web — perf cost?
- IndexedDB save size limits in Chrome/Safari/Firefox
- Gamepad API support in Godot web (mouse-only is fine for v1 if it's painful)

## Cut for v1 — re-evaluate at v1.0 retrospective

- Multiple language support
- Photo mode / replay system
- Workshop / mod support
- Steam release (or any non-GH-Pages distribution)
- Co-op
- Mobile / touch controls
