# Test backlog

Live URL: **https://josh-buck.github.io/site-echo-7/** — title screen bottom-right should read **v0.9.5**.

Delete lines as you verify, or tell me which numbers are broken.

---

## 🆕 v0.9.5 — bug-fix audit (verify these first)

Console should be CLEAN now — open DevTools (F12) before playing:

1. [ ] **No "Node not found: Mesh" error spam.** Previously: errors on every zombie spawn and every headshot. Console should show zero red errors during a full wave.
2. [ ] **Headshot white-flash works** — zombie body flashes white for a heartbeat on a headshot that doesn't kill.
3. [ ] **Kills look right** — corpse plays its fall-over animation for ~1s, then shrinks away. No scale-flicker at the moment of death.
4. [ ] **Director rage recolor works** — at wave 20, drop the Director below half HP: body shifts red + scale-pop + growl. (Use `~` console: `skip 20`, then shoot him.)
5. [ ] **Zombie tints are brighter** — archetypes should read as distinct hues over the zombie texture, not muddy near-black.
6. [ ] **Runner animation speed** — runners' walk cycle plays ~2x faster than walkers (was same cadence for all).
7. [ ] **Big-zombie headshots are honest** — on the Tank/Director, chest hits no longer count as headshots (head zone now scales with body size).
8. [ ] **Barrier-destroyed thud plays** — when you lose, there's a single low thud (was silent).
9. [ ] **Streak-break sound plays** — build a 3+ kill streak, let a zombie hit the barrier: short two-note "tsk tsk."
10. [ ] **Shop → BROWSE CARDS → BACK** returns you to the Shop (paused, cursor visible). Previously this unpaused the game underneath the shop and captured the mouse.
11. [ ] **Turrets don't shoot corpses** — emplaced turrets only target live zombies.
12. [ ] **Dev console `skip N`** — old wave's spawns no longer continue spawning into the new wave.

## Audio state (v0.9 restart — confirm or deny)

The ONLY sounds in the game now: your gunshot (one soft pop per shot), your reload click, UI clicks/hovers, card flip, streak-break, barrier-destroyed thud. **If you hear anything that sounds like gunfire when you're not shooting, report exactly when it happens** — every remaining sound has a single traceable call site.

## Still needs your hands (see docs/asset-pipeline.md)

- Music (CC0 source decision)
- Cross-browser smoke + DevTools heap + frame profiling (§3 of asset-pipeline.md)
- Launch art

## Regression safety net

`godot --headless res://tools/smoke_test.tscn` — 42 assertions covering boot, the wave-end flow, arena swap, boss waves, and (new) the zombie damage pipeline + Director rage. CI-runnable; all passing as of v0.9.5.
