# Asset pipeline + manual testing walkthroughs

Step-by-step for the v1.0 items that need your hand on the keyboard.

---

## 1. Rigged zombie meshes — Mixamo

Mixamo is Adobe's free auto-rig + animation library. Login required (Adobe ID — free; no Creative Cloud subscription needed).

### Get a base character

1. Go to **https://www.mixamo.com/** and sign in with an Adobe ID (free tier is fine).
2. Top nav → **Characters**. Search "**zombie**" — pick one. Recommended starters:
   - "**Mutant**" or "**Crypto**" — basic humanoid, good silhouette
   - "**Big Vegas**" — bulkier, fits the Tank archetype
3. Click the character → preview pane appears on the right. **Download** button → format **FBX for Unity (.fbx)** (Mixamo's FBX preset bakes the rig correctly). Skin: **With Skin**. Pose: **T-Pose**. Frames per Second: **30**. Click **Download**.
4. Save the .fbx somewhere local, e.g. `~/Downloads/zombie_walker.fbx`.

### Get animations

1. With the character still selected, click **Animations** tab.
2. Search and pick three:
   - `Zombie Walk` (or `Zombie Crawl` for variety)
   - `Zombie Attack` (any short one)
   - `Zombie Death` (any — falls to ground)
3. For each one, the preview shows it on the chosen character. Adjust **Trim** sliders if you want shorter clips. Adjust **Overdrive** speed if needed.
4. **Download** each → format **FBX for Unity (.fbx)** → **Without Skin** (animation only, skeleton baked) → **30 fps**.
5. Save them next to the base character with descriptive names: `zombie_walk.fbx`, `zombie_attack.fbx`, `zombie_death.fbx`.

### Convert FBX → GLB (Godot's preferred format)

Blender is already installed (I used it for the gun conversion). Run:

```bash
# Drop all the Mixamo FBX files into one folder, e.g. ~/Downloads/mixamo/
# Then run this conversion script (one-liner using Blender headless):

/Applications/Blender.app/Contents/MacOS/Blender --background --python-expr '
import bpy, os, sys
src_dir = os.path.expanduser("~/Downloads/mixamo")
dst_dir = os.path.expanduser("~/godot-shooter/art/models/zombies")
os.makedirs(dst_dir, exist_ok=True)
for name in os.listdir(src_dir):
    if not name.lower().endswith(".fbx"):
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=os.path.join(src_dir, name))
    out_name = os.path.splitext(name)[0] + ".glb"
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(dst_dir, out_name),
        export_format="GLB",
        export_apply=False,         # keep the armature
        export_animations=True,
        export_morph=False,
    )
    print("[ok]", out_name)
'
```

This converts every FBX in `~/Downloads/mixamo/` to GLB and drops them in `~/godot-shooter/art/models/zombies/`.

### Wire it into the game

Tell me when the GLBs exist (`ls ~/godot-shooter/art/models/zombies/*.glb`) and I'll update `Zombie.tscn` to instance them + hook up walk/attack/death animations via `AnimationPlayer`. That part I can do autonomously once the files are present.

---

## 2. Arena props — Quaternius / Kenney sci-fi kits

CC0 sci-fi prop packs. Download once, pick what fits, drop in `art/models/props/`.

### Best free packs

| Pack | URL | Best assets for us |
|---|---|---|
| Quaternius — **Sci-Fi Essentials Kit** | https://quaternius.com/packs/scifiessentialskit.html | crates, barrels, monitors, cables, vents, consoles |
| Quaternius — **Modular Sci-Fi MegaKit** | https://quaternius.com/packs/modularscifimegakit.html | wall panels, doors, computer banks, lights |
| Kenney — **Space Kit** | https://kenney.nl/assets/space-kit | smaller / more stylized; modular |
| Kenney — **Prototype Bits** | https://kenney.nl/assets/prototype-bits | grey-box props, useful for blockouts |

### Step-by-step

1. **Quaternius first** (better fit for our look): open the **Sci-Fi Essentials Kit** page → click the Download button. Routes to Google Drive (their hosting). You'll need to be signed into a Google account.
2. The Drive folder shows FBX / OBJ / Blend / glTF subfolders. **Download the whole folder as ZIP** (Drive: right-click the folder → Download).
3. Extract to `~/Downloads/scifi_essentials/`. You'll see hundreds of files — most of them are duplicates across formats.
4. **Pick ~10 props** that fit a "destroyed lab" feel:
   - 2× small crates
   - 2× barrels (toxic / explosive look)
   - 1× console / monitor bank
   - 1× hanging cable strand
   - 1× ceiling vent fan
   - 1× damaged wall panel
   - 1× warning sign
   - 1× canister / fuel tank
5. Note the file names. We want **.glb** versions if available, else **.fbx** (we'll convert).
6. Same Blender conversion as the Mixamo step:

   ```bash
   /Applications/Blender.app/Contents/MacOS/Blender --background --python-expr '
   import bpy, os
   src_dir = os.path.expanduser("~/Downloads/scifi_essentials/GLB")  # or FBX
   dst_dir = os.path.expanduser("~/godot-shooter/art/models/props")
   os.makedirs(dst_dir, exist_ok=True)
   keep = ["crate_a", "crate_b", "barrel_red", "monitor", ...]   # filenames you want
   for name in os.listdir(src_dir):
       stem = os.path.splitext(name)[0]
       if stem not in keep:
           continue
       bpy.ops.wm.read_factory_settings(use_empty=True)
       bpy.ops.import_scene.gltf(filepath=os.path.join(src_dir, name))
       bpy.ops.export_scene.gltf(
           filepath=os.path.join(dst_dir, stem + ".glb"),
           export_format="GLB",
           export_apply=True,
       )
       print("[ok]", stem)
   '
   ```

7. Once `art/models/props/*.glb` exists, tell me which prop is which (e.g. `crate_a.glb` = small ammo crate, `barrel_red.glb` = toxic barrel) and I'll wire them into `Arena._build_random_debris()` and `CoolingTower` — pick weighted-random per slot, with rotation jitter, like the existing crates.

---

## 3. Cross-browser + heap + frame budget — manual testing

We need to verify the game runs cleanly on the three macOS browsers and that web-export memory/perf is in spec.

### Setup

1. Open the live build: **https://josh-buck.github.io/site-echo-7/**
2. Hard refresh on each browser before testing (Cmd+Shift+R on Chrome/Firefox, Cmd+Option+E then Cmd+R on Safari) so you're not on a cached old version.

### Cross-browser smoke (15 minutes per browser)

For **Chrome**, **Firefox**, and **Safari** — repeat this checklist:

| # | Step | Pass if… |
|---|---|---|
| 1 | Page loads, title screen renders | No console errors (open DevTools Console first — F12 / Cmd+Option+I) |
| 2 | Click anywhere on page | Audio gesture registers (no "AudioContext was not allowed to start" warning) |
| 3 | Open Settings, change FOV to 90 and back | Slider responds, FOV visibly changes |
| 4 | Open Lifetime Stats → back, Credits → back, Modifiers → back | All screens load + ESC returns to title |
| 5 | Click **START RUN** | Story intro appears (first run), or game starts directly (later runs) |
| 6 | Click to capture mouse | Pointer lock acquired, crosshair appears |
| 7 | Hold W/A/S/D — note: you don't move, only the gun rotates | Aim follows mouse, no stutter |
| 8 | Fire (left click) | Pistol synth pop, muzzle flash, tracer visible, bullet hole on barrier/floor |
| 9 | Reload (R) | Reload click plays, mag count refills |
| 10 | Press number keys 1-6 | Weapons swap (only unlocked ones show) |
| 11 | Press Q | Cycles through unlocked weapons |
| 12 | Press ESC | Pause menu appears, ESC again to resume |
| 13 | Press ~ (tilde) | Dev console appears bottom-bar |
| 14 | Type `tokens 500` in console + Enter | 500 tokens added to HUD |
| 15 | Type `skip 10` | Wave fast-forwards to wave 10 (Subject boss) |
| 16 | Play through wave 10 | Boss fight, music/lighting goes red |
| 17 | Type `skip 20` | Wave 20 (Director). Lights stay red. Phase-2 at <50% HP |
| 18 | Type `kill` | All zombies die, wave ends |
| 19 | If Director died → Victory screen with random flavor line | "Site Echo 7 Contained" + stats |
| 20 | Click "BANK & RETURN TO TITLE" | Returns to title, RD banked, version shows in bottom-right |

Note any step where the browser behaves differently. Common gotchas:
- **Safari**: pointer lock can be finicky — sometimes requires clicking twice, or canvas focus
- **Firefox**: gamepad rumble may not fire; audio gesture gate sometimes needs an extra click
- **Chrome**: usually the cleanest

Send me the FAILED row numbers per browser and I'll fix.

### DevTools heap watch (Chrome — 10 minutes)

We need to verify the WASM heap doesn't blow past 256 MB during peak combat.

1. **Chrome only** (best memory tools). Open the live build.
2. F12 → **Memory** tab.
3. Select "**Heap snapshot**" → **Take snapshot**. Note the "Used heap size" value.
4. Start a run, play to wave 5 normally (don't use console). Then use `skip 18` to jump to wave 18.
5. Survive ~30 seconds of wave 18 combat (lots of zombies on screen).
6. Take another **heap snapshot** while combat is active.
7. Compare the two snapshots' "Used JS heap size":
   - **Pass**: peak heap < 256 MB
   - **Warning**: 256–400 MB — usable, but tight
   - **Fail**: > 400 MB — there's a leak somewhere; tell me which scene was active

Also screenshot the **Memory** panel's `Memory > Used JS heap size` chart for the whole run. That'll show whether memory climbs linearly (leak) or plateaus (healthy).

### Frame-time budget (Chrome — 10 minutes)

We want 60fps (16.6ms/frame) at the 95th percentile during peak combat.

1. F12 → **Performance** tab.
2. Click the **Record** button (circle, top-left).
3. Use the dev console: `skip 18` + wait ~5 seconds for spawns + start firing.
4. Record for **30 seconds** of active combat.
5. Click **Stop**.
6. The result shows a frame chart at the top. Look for:
   - **Solid green bar** = 60fps. Good.
   - **Yellow / orange spikes** = a frame took >16.6ms. Note the cause:
     - **Scripting** (yellow): a GDScript function ran long
     - **Rendering** (purple): GPU draw was slow
     - **System** (grey): browser background work
7. Click any spike → "Bottom-Up" tab → shows what function ate the frame time.
8. Send me a screenshot of:
   - The frame chart (top of the Performance tab)
   - One spike's Bottom-Up breakdown if you see consistent stalls

Typical hot frames to expect:
- First shot in a run (synth + material compile)
- First kill (BloodBurst pool warmup — should be once-only)
- Wave 11 transition (arena swap)
- Wave 20 director phase change

If any of those are not the spikes — that's where the bug is.

---

## When all of this lands

- Mixamo zombies + arena props: I integrate them, run the smoke test, push v0.8.0
- Cross-browser results: I patch whatever fails per browser
- Heap / frame budget: I optimize whatever shows up as a hotspot

Once those are in, v1.0 is shippable.
