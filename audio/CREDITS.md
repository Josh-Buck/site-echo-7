# Audio Sources & Licenses

All audio in this directory is **CC0 (public domain)**. No attribution legally required, but credited here for traceability and integrity.

Re-encoded with `oggenc` from `vorbis-tools`: SFX at 96 kbps mono 44.1 kHz, ambient at 128 kbps stereo 44.1 kHz. Pipeline:
```
ffmpeg -i SRC -ac 1 -ar 44100 -f wav - | oggenc -b 96 -o OUT.ogg -
```

## sfx/weapons/

| File | Source | Notes |
|---|---|---|
| `pistol_shoot.ogg` | OpenGameArt — "Gunshot Sounds" by Vince Sevedge, CC0 — https://opengameart.org/content/gunshot-sounds | CZ-52 pistol recording |
| `ar_shoot.ogg` | same pack | SKS rifle recording — proxy for AR |
| `shotgun_shoot.ogg` | same pack | shotgun recording, short |
| `sidearm_shoot.ogg` | same pack | Mosin Nagant — proxy for bolt-action sidearm |
| `pistol_reload.ogg` | OpenGameArt — "Gun reload sounds" by SpringySpringo, CC0 — https://opengameart.org/content/gun-reload-sounds | `gunreload1.wav` |
| `ar_reload.ogg` | same pack | `assaultriflereload1.wav` |
| `shotgun_reload.ogg` | same pack | `shotguncock.wav` |
| `sidearm_reload.ogg` | same pack, pitch-shifted | `shotguncock.wav` at 0.75x sample rate for heavier bolt-throw feel |

## sfx/zombies/

All from OpenGameArt — "Zombies Sound Pack" (Summoning Wars), CC0 — https://opengameart.org/content/zombies-sound-pack

| File | Source clip |
|---|---|
| `groan_01.ogg` | zombie-1.wav |
| `groan_02.ogg` | zombie-7.wav |
| `groan_03.ogg` | zombie-12.wav |
| `attack_growl.ogg` | zombie-5.wav |
| `attack_hit.ogg` | zombie-16.wav |
| `death_01.ogg` | zombie-20.wav |
| `death_02.ogg` | zombie-23.wav |

## sfx/barrier/

| File | Source |
|---|---|
| `hit_01.ogg`, `hit_02.ogg`, `hit_heavy.ogg` | Kenney "Impact Sounds" pack, CC0 — https://kenney.nl/assets/impact-sounds (`impactMetal_heavy_*`, `impactBell_heavy_000`) |
| `critical_alarm.ogg` | OpenGameArt — "30 CC0 SFX loops", CC0 — https://opengameart.org/content/30-cc0-sfx-loops (`alarm_02.ogg`) |

## sfx/ui/

All from Kenney "Interface Sounds" pack, CC0 — https://kenney.nl/assets/interface-sounds

| File | Source clip |
|---|---|
| `click.ogg` | click_001.ogg |
| `confirm.ogg` | confirmation_001.ogg |
| `card_flip.ogg` | open_001.ogg |
| `hover.ogg` | select_001.ogg |
| `draft_appear.ogg` | bong_001.ogg |

## sfx/footsteps/concrete/

Source: Kenney "Impact Sounds" pack, CC0 (`footstep_concrete_00[0-3].ogg`).
- `a_1..4.ogg` — direct re-encode (clean concrete, Containment Lab)
- `b_1..4.ogg` — same source pitched to 0.9x sample rate for a heavier dust/grit variant (second surface in Containment Lab — e.g. rubble area)

## sfx/footsteps/metal/

`grate_1..4.ogg` — OpenGameArt "Metal footsteps on concrete", CC0 — https://opengameart.org/content/metal-footsteps-on-concrete. 4 of 25 source samples (1, 5, 10, 15) chosen for variety.

## ambient/

| File | Source |
|---|---|
| `lab_hum_loop.ogg` | OpenGameArt "30 CC0 SFX loops" (`machine_05.ogg`), CC0 — https://opengameart.org/content/30-cc0-sfx-loops. Loop point: clip is natively loopable |
| `tension_stinger.ogg` | Kenney "Sci-fi Sounds" pack (`computerNoise_002.ogg`), CC0 — https://kenney.nl/assets/sci-fi-sounds. One-shot, ~2s, suitable for round-start sting |

## Total size

`du -sh audio/` should report < 1 MB. All assets re-encoded — originals discarded.
