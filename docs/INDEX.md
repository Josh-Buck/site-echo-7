# Docs index — Site Echo 7

Master map of every document in this repo, what it's for, and how current it is. Update the table when adding or substantially revising a doc.

Last reconciled: **2026-06-12 (v0.9.6)** — post bug-audit, all docs below verified against the shipped build.

| Doc | Purpose | Currency |
|---|---|---|
| [`../CLAUDE.md`](../CLAUDE.md) | Working agreement: locked decisions, conventions, gotchas, operating cadence, agent routing. Read first. | Evergreen — updated when conventions change |
| [`design-plan.md`](design-plan.md) | The original milestone plan (M0–M3) + live status banner at top. Historical body, current banner. | Banner current as of v0.9.6; body is historical |
| [`production-gaps.md`](production-gaps.md) | **The live punch list.** `[x]` done, `[ ]` open on the v1.0 path, `[-]` deferred post-v1.0. "What's left for v1.0" section names what needs user hands. | Current as of v0.9.6 |
| [`test-backlog.md`](test-backlog.md) | What the user should verify in the live build right now. Items deleted as verified. | Current as of v0.9.5 audit |
| [`codebase-map.md`](codebase-map.md) | Where everything lives: boot flow, autoloads, EventBus signal table, scene graph, per-domain file index. | Current as of v0.7.x structure + v0.9 notes; audio architecture note below |
| [`asset-pipeline.md`](asset-pipeline.md) | Step-by-step walkthroughs for user-driven work: Mixamo zombies (§1, done), Sci-Fi props (§2, done), cross-browser/heap/frame testing (§3, pending). | §1–2 completed and integrated; §3 awaiting user |
| [`non-negotiables.md`](non-negotiables.md) | Hard rules — web constraints, save policy, license policy, "NOT in v1" list. | Evergreen |
| [`ideas.md`](ideas.md) | Parking lot for post-v1.0 ideas + asset credits + parked user asks. | Append-only |
| [`m1-contract.md`](m1-contract.md) | M1 definition-of-done. | Historical — M1 shipped |

## Architecture notes that supersede older doc text

- **Audio (v0.9 restart):** `AudioMan` has NO EventBus listeners. Single 6-player 2D pool, pure-sine synths, no positional 3D, no ambient loops, no zombie vocals. Sounds are explicit calls: `play_weapon_fire(id)`, `play_weapon_reload()`, `play_barrier_destroyed()`, `play_sfx("streak_break")`, UI helpers. Anywhere older docs mention 3D pools, bus-routed ambient hums, or barrier impact OGGs — that's gone.
- **Zombies (v0.8–v0.9.5):** single rigged Mixamo GLB (`art/models/zombies/zombie.glb`, Walk/Attack/Death NLA tracks) with per-archetype albedo tint over cached material overrides. The primitive rig, eye-glow nodes, footstep/groan audio plumbing are all removed.
- **Regression safety net:** `godot --headless res://tools/smoke_test.tscn` — 42 assertions (boot, wave-end flow, arena swap, boss composition, zombie damage pipeline, Director rage). Run before every push.

## What's genuinely left for v1.0 (mirror of production-gaps.md)

User-hands-required: music sourcing, cross-browser/heap/frame manual testing (`asset-pipeline.md` §3), launch art. Larger deferred systems: mid-run save (Continue button), weapon reload animations (needs rigged weapon assets).
