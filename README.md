# Site Echo 7

A 3D first-person stationary horde shooter. Built in Godot 4.6, deployed to GitHub Pages.

**Play it now:** https://josh-buck.github.io/site-echo-7/

You stand behind a circular barrier in a research-facility arena, spin 360° to fire at zombies coming from every direction, draft research-note cards between rounds that hot-modify your weapons, and survive 20 waves to the Director boss fight.

## How to play

- **Mouse** — spin to aim (you don't move)
- **L-Click** — fire
- **R** — reload
- **1-6** — weapon slot
- **Q** — cycle weapons
- **ESC** — pause

Run length: ~10-20 minutes. Death banks Research Data toward permanent unlocks for next run.

## Core hook

- **Draft a research-note card** at the end of every wave. Cards permanently buff a weapon stat (fire rate, damage, mag size, recoil, headshot multiplier, reserve ammo) or unlock a conditional effect (Marksman refunds ammo on headshot, Last Round triples damage on the final mag round, Lifesteal heals the barrier per kill).
- **Synergy cards** stack with categories — Pyromaniac needs 3 fire-tagged cards in your deck; once it activates, +50% damage / +20% fire rate to the lot.
- **Curse cards** trade safety for power — Glass Cannon doubles damage but halves your effective barrier HP.

## Weapons (6 slots)

| Slot | Weapon         | Notes                                              |
|------|----------------|----------------------------------------------------|
| 1    | M1 Pistol      | Starter. Semi-auto, balanced.                      |
| 2    | Assault Rifle  | Auto. Higher RPM, smaller mag.                     |
| 3    | Combat Shotgun | 12-pellet spread. Devastating up close.            |
| 4    | Sidearm        | **Infinite reserve.** Weak fallback, always available. |
| 5    | Compact SMG    | 12 rps, 35 mag, low per-shot. Spray and pray.      |
| 6    | Bolt-Action    | 0.7 rps, 60 dmg, ×3 headshot. One round chambered. |

## Enemies

Walker, Runner, Tank, Spitter, Exploder, Armored Walker, plus two bosses: The Subject (wave 10) and The Director (wave 20). Director enters a phase-2 rage below 50% HP — faster, harder hits, body recolors.

## Token shop (between waves)

Tokens drop from kills. Spend on:
- **Ammo Top-Up / Full Resupply / Speed Loader** — refill reserves.
- **Barrier Repair / Field Welder** — patch barrier HP.
- **Auto-Turret** — deploy a static emplacement. Stacks to 4.
- **Field Regenerator** — barrier auto-heals +1 HP/s next wave.
- **Reinforced Plating** — permanent +15 max barrier HP.
- **Chill Emitter** — zombies move 20% slower next wave.

## Meta-progression

Research Data persists across runs. Unlocks new weapons (AR 350 RD, Shotgun 450 RD, SMG 550 RD, Bolt 700 RD), barrier upgrades, perks (Quartermaster pre-drafts a card, Combat Veteran starts with 20 tokens, Quick Draft = 5-card first draft). 26 challenges across Bronze/Silver/Gold/Platinum tiers grant additional RD. Cosmetic titles unlock from challenges and best-wave milestones.

## Tech

- **Godot 4.6** Compatibility renderer for web export
- **GDScript only**, single-threaded (no .gdextension, no Thread — web build constraints)
- **CC0 assets**: Quaternius Ultimate Gun Pack (weapons), AmbientCG + Poly Haven (PBR materials)
- **Audio synthesized at runtime** (procedural WAVs in `AudioMan.gd`) plus a few real ambient .ogg samples
- **GitHub Actions deploy** on every push to `main` → GitHub Pages

## Folder layout

```
autoload/      GameState, MetaProgress, SaveSystem, EventBus, AudioMan, CardSystem, ChallengeTracker
scenes/
  player/      Player + WeaponManager + HitPause + CasingPool
  weapons/     Weapon base + 6 weapon scenes + .tres data + vfx (TracerPool, sparks, BulletHolePool)
  enemies/     Zombie + AcidSpit + enemy .tres + BloodBurstPool
  barrier/     Barrier defense + alarm
  arena/       Containment Lab + Cooling Tower + SpawnRing + wave .tres
  cards/       CardData + 38 cards + 26 challenge .tres
  turret/      Auto-turret emplacement
  ui/          HUD + CardDraft + Shop + Title + Settings + Meta + LifetimeStats + Credits + StoryIntro + ChallengeToast + WaveComplete + DeathScreen + PauseMenu + Tutorial
art/           PBR materials + weapon GLBs
audio/         Procedural synth in AudioMan + a few real .ogg samples
docs/          Design plan, production gaps, test backlog, codebase map, ideas
tools/         smoke_test.tscn — headless E2E test, 35+ assertions
```

## Build / test

```bash
# Local headless smoke test (~10s):
godot --headless res://tools/smoke_test.tscn

# Local web export (requires Godot 4.6 web export templates installed):
mkdir -p build/web
godot --headless --import || true
godot --headless --export-release "Web" build/web/index.html
python3 -m http.server -d build/web 8080
# then open http://localhost:8080
```

CI runs both on every push.

## Status

See `docs/production-gaps.md` for the live punch list. Most P1 items shipped (lunar arena, 6 weapons + 5 enemies + 2 bosses, 38 cards inc. 3 synergies + 3 curses, 26 challenges, token shop with 9 offers, lifetime stats, credits, colorblind mode, save export/import, hold-to-confirm, hit-pause variants, boss telegraph audio, story intro, intercom flavor lines, randomized debris). Real rigged zombie meshes and a music soundtrack are the remaining P0 holdouts.

## License

Source under MIT. Quaternius assets are CC0. Audio is procedural / public-domain.
