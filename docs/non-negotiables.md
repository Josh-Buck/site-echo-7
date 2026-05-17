# Non-negotiables

The hard rules. If a feature, refactor, or "wouldn't it be cool if" violates one of these, the answer is no — or the rule changes first, deliberately, in this file.

## Scope & shipping

1. **Every milestone deploys to GH Pages.** If M1 isn't playable in a browser at the URL, M1 is not done. No exceptions, no "I'll wire the action up next milestone."
2. **Quality over speed. No hard deadline.** A milestone ships when it meets its definition-of-done, not when a week ends. If it takes twice as long to look right, take twice as long. Don't ship a worse game to meet an imaginary clock.
3. **Card system is the hook. Protect it.** If something has to get cut to keep card drafting feeling good, cut weapons, cut enemies, cut polish. Don't cut cards.
4. **Visuals are the second hook. Don't compromise them to save time.** If PBR is taking longer, that's the cost of the choice. Cut feature scope, never the visual bar.
5. **Permanent progression is intentionally slow.** Per-run RD income is small relative to unlock costs. Don't "balance" by making it faster — slow unlocks ARE the retention mechanic.
6. **One bundled PR per milestone.** Spread commits within the milestone, but ship the deploy as one reviewable unit.

## Web build constraints (these will hurt if ignored)

5. **Pure GDScript only.** No `.gdextension`, no GDNative, no C# (Godot web export doesn't support .NET). If a library requires it, find a pure-GDScript path or drop the feature.
6. **Single-threaded build.** GitHub Pages does not send `COOP`/`COEP` headers, so `SharedArrayBuffer` is unavailable. Threads off in the export preset. Don't write code that assumes multithreading.
7. **`.nojekyll` at gh-pages root.** Without this, GH Pages hides files starting with `_` and your build is half-broken with no useful error. Workflow must write it.
8. **Audio waits for first user gesture.** Browsers block autoplay. Title screen must require a click before `AudioMan` starts playing anything.
9. **`OS.shell_open` is a no-op on web.** Don't link to external help/credits via it — use `JavaScriptBridge` `window.open` or a plain HTML overlay.
10. **Initial Memory: 256 MB in export preset.** Default 64 MB will OOM the moment you spawn a horde. Raise it, verify in browser DevTools the WASM heap isn't capping out.

## Save & state

11. **Save after every wave.** Mid-run saves to `user://` (which is IndexedDB on web). A browser tab close mid-run must not lose progress.
12. **Save after every meta-progress change.** Unlocking a card or banking research tokens writes immediately. Never trust the player to "exit cleanly."
13. **Save format is versioned.** Add a `version: int` field on day 1. Future-you will thank present-you when the schema changes in M3.

## Assets & legality

14. **License-clean only.** CC0 (Kenney, OpenGameArt, Freesound CC0 tier), your own work, or properly licensed. Track sources in `art/SOURCES.md` and `audio/SOURCES.md` as you go, not in retrospect.
15. **Procedural fallback for every asset type.** SFX synthesized via `AudioStreamWAV` if a sourced sound isn't right yet. Untextured material if a model isn't textured yet. Always have a working ugly version before chasing a pretty version.

## Code & architecture

16. **Cross-cutting state goes in autoloads.** Run state, meta progress, save, audio, events, cards. Don't pass these through node trees.
17. **Static data goes in `Resource` subclasses (`.tres`).** Editor-inspector edits, type-safe, diff-friendly. No hardcoded weapon stats in `.gd` files.
18. **`EventBus` for decoupled comms.** A weapon doesn't reach into the HUD. It emits a signal; the HUD listens.
19. **No premature abstractions.** Three similar lines is fine. Don't build a card-effect DSL until you have 15 cards and feel the friction.

## What we are NOT doing in v1

(If you find yourself doing one of these, stop and re-read this list.)

- ❌ Multiplayer / online of any kind
- ❌ Accounts, leaderboards, cloud saves
- ❌ Movement beyond rotation (no strafing, no crouching, no leaning)
- ❌ Loot drops on the floor (zombies grant currency directly)
- ❌ A storyline beyond the Site Echo-7 framing (no cutscenes, no NPCs)
- ❌ Procedural arena generation (1–2 hand-built arenas only)
- ❌ Crafting (cards replace crafting)
- ❌ Mod support
- ❌ Mobile / touch controls (desktop browser only)
- ❌ Localization (English only in v1)
