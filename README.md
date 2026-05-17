# Site Echo 7

3D stationary horde shooter with a draft-deck weapon-modifier system. Browser-playable. Godot 4.6, GDScript only, single-threaded web build, GitHub Pages.

→ Design docs: [`CLAUDE.md`](CLAUDE.md) · [`docs/design-plan.md`](docs/design-plan.md) · [`docs/non-negotiables.md`](docs/non-negotiables.md) · [`docs/ideas.md`](docs/ideas.md)

## Status

**M0 — Scaffold.** The browser smoke test: a 3D cube in front of an orbiting camera, press SPACE to score, the score persists across page reloads via `user://meta.save` (IndexedDB on web). Proves the pipeline works end-to-end before we build anything real.

## Local dev

Requires Godot 4.6-stable. Open `project.godot` in the editor. Hit F5.

The editor will likely prompt to set the main scene the first time — it should auto-detect `res://scenes/Main.tscn` from `project.godot`, but confirm.

### Smoke test in editor

1. Open project → see the cube + UI labels rendering.
2. Press SPACE (or click). Cube bounces, lifetime score increments.
3. Close, reopen — score persists.
4. Press R to wipe the save.

### Smoke test as web build (local)

```sh
mkdir -p build/web
godot --headless --export-release "Web" build/web/index.html
python3 -m http.server -d build/web 8080
```

Open `http://localhost:8080` in a browser. Same test as above. **Note:** `localhost:8080` is OK because the page is loaded from a server, not `file://`.

## Pushing to GitHub & enabling Pages

The repo isn't on GitHub yet — set this up once.

```sh
cd ~/godot-shooter
# Create empty repo on github.com/Josh-Buck/site-echo-7 first (no README, no .gitignore).
git remote add origin git@github.com:Josh-Buck/site-echo-7.git
git push -u origin main
```

Then, in repo Settings → Pages:
- **Source: GitHub Actions** (not "Deploy from branch")
- Save.

Push triggers `.github/workflows/deploy.yml`. First run takes ~5–8 minutes (downloads Godot + templates; subsequent runs cached). When green, the build is live at:

`https://josh-buck.github.io/site-echo-7/`

## Things to verify on the live build

1. Page loads, you see the cube + score UI.
2. SPACE / click increments lifetime score.
3. Hard-reload (Ctrl+Shift+R) the page — score persists.
4. Browser DevTools → Application → IndexedDB → there's an entry for `/site-echo-7/`.

If any of these fail, M0 isn't done. See `docs/design-plan.md` verification plan.

## Project layout

```
project.godot            Godot main config (autoloads, renderer, main scene)
export_presets.cfg       Web export preset (single-threaded, 256MB heap, PWA off)
icon.svg                 Game icon
.gitignore               Godot 4 standard ignores

autoload/                Singletons (registered in project.godot [autoload])
  GameState.gd           Current-run state
  MetaProgress.gd        Persistent unlocks, lifetime stats
  EventBus.gd            Signal hub
  AudioMan.gd            Audio + first-gesture gate
  SaveSystem.gd          user:// JSON persistence, versioned
  CardSystem.gd          Card draft + effect pipeline (stub for M0)

scenes/
  Main.tscn / Main.gd    M0 smoke test scene

art/                     PBR materials, models, textures (empty in M0)
audio/                   SFX, music, generated audio (empty in M0)

docs/                    Design docs — read these before changing scope
  design-plan.md
  ideas.md
  non-negotiables.md

.github/workflows/
  deploy.yml             GitHub Actions → actions/deploy-pages
```

## After M0 lands green

Open `docs/design-plan.md` → M1 checklist. Next up: first-person camera, mouse-look spin, the M1 Pistol with real recoil/reload/ammo, one Walker zombie type, the circular barrier, single-wave loop.
