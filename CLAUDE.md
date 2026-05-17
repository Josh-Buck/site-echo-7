# CLAUDE.md — Site Echo 7

Working title: **Site Echo 7**. Repo slug: `site-echo-7`. Will live at `Josh-Buck/site-echo-7`, deployed via GitHub Actions to GitHub Pages at `https://josh-buck.github.io/site-echo-7/`. Title is not final-final — can rebrand at v1.0 if a better name surfaces during build.

## What this is

A 3D first-person stationary horde shooter. Player is locked behind a circular barrier in a research-facility arena, spins 360° to shoot zombies coming from all directions, survives escalating rounds, drafts weapon-modifier **cards** between rounds, dies eventually, banks meta-XP to unlock new cards/weapons/perks for the next run.

The build-a-deck card system is the hook. Cards are framed as "recovered research notes" that hot-modify the player's weapons (Site Echo-7 fiction).

## Core values

- **Quality over speed.** No hard deadline. We ship a milestone when it meets its definition-of-done, not when a week ends. A worse game shipped fast is still a worse game.
- **Ambition is allowed.** Full PBR, real art, real polish. We may fail. That's preferable to a generic game that succeeds.
- **Permanent progression is intentionally slow.** Players come back because they want the next unlock. If unlocks come too fast, the loop dies.
- **Every milestone is browser-playable.** Quality > speed does not mean "ship at the end." It means each milestone is the best it can be before we move on.

## Locked decisions

| Axis | Decision |
|---|---|
| Engine | Godot 4.6, GDScript only (no .gdextension — web-incompatible) |
| Deploy | GitHub Pages via `actions/deploy-pages` (GitHub-official, artifact-based — no `gh-pages` branch) |
| Tactical feel | Tactical-arcade hybrid. Aim matters, reloads are real decisions, recoil is learnable. NOT milsim. |
| Timeline | No hard deadline. Ship each milestone when it meets its definition-of-done. |
| Perspective | First-person, locked position, free spin (mouse + gamepad right stick) |
| Genre | Tactical-arcade horde defense (precision matters, but not milsim) |
| Setting | Modern military research facility — "Site Echo-7" outbreak |
| Art | Constrained PBR (see Art Budget below). Fallback path: low-PBR regrade. |
| Progression | Endless runs + meta unlocks (roguelite-lite) |
| Hook | Draft-deck weapon modifiers — 1-of-3 card pick between rounds |
| Session length target | 10–20 minutes per run |
| Online | Offline only. No accounts, no leaderboards in v1. |

## Art budget (full PBR — survival rules)

Full PBR from day 1. The look is the point — we accept slower asset velocity to get visuals that justify the project's existence. These rules exist so PBR doesn't break the web build, not to compromise the look.

- **What "PBR" means here:** each material has albedo (base color), roughness, metallic, normal, and AO maps. The engine uses physics-grounded lighting math. Sources: hand-authored in Blender + Substance/Materialize, or sourced from CC0 PBR libraries (AmbientCG, Poly Haven CC0).
- 1024×1024 max texture size. 512 where it reads fine. The eye doesn't care at first-person distances if you've authored well.
- Trim sheets + modular kit-bashing — one PBR material covers many surfaces. This is how PBR ships at scale on web.
- KTX2 / Basis Universal compression on export. Non-negotiable for build size.
- Baked lighting only — no realtime GI, no SDFGI, no SSR. PBR + baked light still looks great; the cuts are runtime-only.
- Polycount per asset: zombie ~5k tris, weapon viewmodel ~12k, arena props ~1k. (More generous than a "constrained" budget because PBR makes the silhouette earn it.)
- Web build target: aim for < 80 MB gzipped initial download. If we blow it, lazy-load arena 2 assets.
- If a single asset takes more than 2–3 evenings, step back: is the design over-scoped, or are you fighting the tool? Don't grind.
- **No "lowpbr" fallback path.** We're committing. If PBR doesn't work on web for our scope, we redesign the scope, not the visual language.

## Architecture conventions

**Autoloads** (cross-cutting state, project settings → autoload):
- `GameState` — current run: round, score, currency, active deck
- `MetaProgress` — persistent: unlocks, total kills, best wave, research tokens
- `EventBus` — signal hub: `enemy_killed`, `wave_started`, `wave_ended`, `card_drafted`, `barrier_damaged`, `weapon_fired`, `weapon_reloaded`
- `AudioMan` — bus mixing, 3D positional audio, gesture-gated first play
- `SaveSystem` — `user://` persistence, autosave on wave end + on meta change
- `CardSystem` — draft pool, active deck, effect resolution pipeline

**Static data → `Resource` subclasses (`.tres`)**, editor-inspector friendly:
- `WeaponData` (damage, fire rate, mag, reload, recoil pattern, ammo type, viewmodel scene)
- `EnemyData` (HP, speed, attack, drop table, scene, AI script)
- `CardData` (target slot, effect script ref, rarity, prereqs, downside)
- `WaveData` (composition, count, spawn timing)
- `PerkData` (meta perks)

**Scene layout — by domain, not by file type:**

```
scenes/
  player/        Player.tscn + Player.gd + WeaponManager.gd
  weapons/       Weapon.tscn + Weapon.gd + data/*.tres
  enemies/       Zombie.tscn + Zombie.gd + data/*.tres
  barrier/       Barrier.tscn + Barrier.gd
  arena/         Arena.tscn + SpawnRing.gd
  ui/            HUD.tscn, CardDraft.tscn, MainMenu.tscn, MetaMenu.tscn
  cards/         Card.gd (base) + effects/ + data/*.tres
autoload/        GameState.gd, MetaProgress.gd, EventBus.gd, AudioMan.gd, SaveSystem.gd, CardSystem.gd
art/             models/, textures/, materials/, lowpbr_*/
audio/           sfx/, music/, generated/
.github/
  workflows/
    deploy.yml
```

## Build & deploy

- Local play: open project in Godot 4.6 editor, F5.
- Local web test: `godot --headless --export-release "Web" build/web/index.html` then `python3 -m http.server -d build/web`.
- Deploy: push to `main` → GH Action exports headless → publishes to `gh-pages`.
- Export preset name: `Web`. Initial Memory: 256 MB. Threads: off. PWA: off (v1).
- `.nojekyll` must land at gh-pages root.
- Godot version: install path `4.6.stable`, download URL `4.6-stable` (yes they're different — don't lose another evening to this).

## Style preferences

- Short comments. Default to none. Comment the WHY when non-obvious, never the WHAT.
- Short commit messages. No co-author footer.
- Spread commits over time; don't batch a milestone into one mega-commit.
- One bundled PR per milestone deploy.
- snake_case for files, scripts, vars. PascalCase for classes and scene nodes.
- Prefer `signal` + `EventBus` over hard references between unrelated systems.
- Prefer composition (child nodes) over inheritance.

## Non-negotiables

See `docs/non-negotiables.md`. Read it before touching scope.

## Ideas parking lot

See `docs/ideas.md`. Stuff that's *not* in v1 goes here, not into the code.

## Agent team

Project-level Claude Code subagents live in `.claude/agents/`. Each has a focused lane; route work to the right one rather than to a generalist.

| Agent | Lane | Invoke when… |
|---|---|---|
| `zombie-gameplay-dev` | Player controller + weapons code (under `scenes/player/`, `scenes/weapons/`) | Adding/tuning the player camera, mouse-look spin, firing logic, raycast/projectile weapons, recoil physics, reload behavior |
| `zombie-ai-architect` | Enemy AI + wave spawning (under `scenes/enemies/`, spawn ring) | Building/tuning Walker, Runner, Tank, Spitter, Exploder, bosses; state machines; NavigationAgent3D; wave composition execution |
| `zombie-ui-manager` | UI, menus, HUD + custom Resource schemas | HUD elements, card draft UI, shop, meta progression screen, settings, schema for `WeaponData`/`CardData`/`EnemyData`/etc. |
| `godot-engineer` | Cross-cutting / autoloads / arena / barrier / card effect internals | Anything not in a specialist's lane: autoload internals, barrier behavior, arena geometry, CardSystem internals, save schema migrations |
| `game-designer` | Cards, balance, economy, challenges, difficulty curve | Designing new cards (proposes 3 candidates), tuning numbers, designing challenges, balancing the RD economy. Hands off implementation. |
| `art-scout` | Sourcing CC0 PBR assets + audio | Finding materials, models, SFX, music. License-verifies. Respects the art budget. |
| `web-export-doctor` | Godot web build diagnostics | A feature works in editor but breaks in browser; deploy fails; browser console error; build-size blowup |

**Routing rule of thumb:** code-in-a-specific-folder → folder's specialist; cross-cutting/glue → `godot-engineer`; design questions → `game-designer`; "is this broken?" web issues → `web-export-doctor`; assets → `art-scout`.
