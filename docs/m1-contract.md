# M1 integration contract

> **Historical — M1 shipped.** The constants below are still accurate for the current codebase (player at 0,1.6,0; barrier radius 3.0; spawn ring radius 12; 8 spawn points; collision layers unchanged). The "files to create" sections are outdated — see **`docs/codebase-map.md`** for the live file index.

Shared constants and file ownership for the M1 parallel build. Agents read this so their work integrates cleanly.

## Coordinate system

- Y is up
- Player position: `(0, 1.6, 0)` — eye height, inside the barrier, at world origin
- Barrier center: `(0, 0, 0)`, radius `3.0 m`, height `1.6 m`
- Arena floor: `(0, 0, 0)` plane, circular, radius `18 m`
- Spawn ring: 8 points at radius `12 m`, evenly spaced (45° increments), `y = 0`

## Collision layers (Godot physics layers, 1-indexed)

- Layer 1 — Player (camera ray origin, weapon viewmodel)
- Layer 2 — Environment / Barrier (static world geometry)
- Layer 3 — Enemy (zombies)
- Layer 4 — Player damage volume (only used for zombie attack detection later)

**Critical interactions:**
- Player weapon raycast: query mask = layer 3 only. The barrier on layer 2 does NOT block weapon shots — player can fire through it.
- Zombie NavigationAgent3D: navmesh excludes the barrier interior, so zombies path to the barrier's outer surface and attack from there.
- Zombie attack hit detection: zombies on layer 3 detect barrier (layer 2) and player damage volume (layer 4 if added).

## EventBus signals (already declared in `autoload/EventBus.gd`)

Producers and consumers for M1:

| Signal | Emitted by | Consumed by |
|---|---|---|
| `weapon_fired(weapon, payload)` | Weapon.gd | CardSystem (no-op stub in M1), HUD |
| `weapon_reloaded(weapon)` | Weapon.gd | HUD |
| `weapon_swapped(old, new)` | WeaponManager.gd (no-op in M1, 1 weapon) | HUD |
| `enemy_damaged(enemy, amount, source_weapon)` | Zombie.gd | HUD (damage numbers later), CardSystem |
| `enemy_killed(enemy, source_weapon, headshot, position)` | Zombie.gd | GameState (tokens), HUD, MetaProgress |
| `barrier_damaged(amount, attacker)` | Barrier.gd | HUD |
| `barrier_destroyed` | Barrier.gd | Main (game over) |
| `wave_started(round_number, composition)` | SpawnRing.gd | HUD |
| `wave_ended(round_number)` | SpawnRing.gd | HUD, Main (M1 shows WaveComplete) |
| `run_started` | Main / GameState | HUD |
| `run_ended(stats)` | Main / GameState | DeathScreen (future) |

## Input actions (project.godot, already updated)

- `shoot` — left mouse button OR SPACE
- `aim` — right mouse button
- `reload` — R
- `pause` — ESC (keycode 4194305)
- `dev_reset` — F12 (keycode 4194343) — wipes save during dev

## Resource paths

| Resource | Path |
|---|---|
| `WeaponData` class | `res://scenes/weapons/data/weapon_data.gd` |
| M1 Pistol data | `res://scenes/weapons/data/pistol_m1.tres` |
| `EnemyData` class | `res://scenes/enemies/data/enemy_data.gd` |
| Walker data | `res://scenes/enemies/data/walker.tres` |
| `WaveData` class | `res://scenes/arena/data/wave_data.gd` |
| Wave 1 data | `res://scenes/arena/data/wave_1.tres` |

## Scene paths

| Scene | Owned by | Path |
|---|---|---|
| `Main.tscn` (M1 root) | orchestrator | `res://scenes/Main.tscn` |
| `Arena.tscn` | godot-engineer | `res://scenes/arena/Arena.tscn` |
| `Barrier.tscn` | godot-engineer | `res://scenes/barrier/Barrier.tscn` |
| `Player.tscn` | zombie-gameplay-dev | `res://scenes/player/Player.tscn` |
| `Weapon.tscn` (base) | zombie-gameplay-dev | `res://scenes/weapons/Weapon.tscn` |
| `Zombie.tscn` (base) | zombie-ai-architect | `res://scenes/enemies/Zombie.tscn` |
| `Walker.tscn` | zombie-ai-architect | `res://scenes/enemies/Walker.tscn` |
| `HUD.tscn` | zombie-ui-manager | `res://scenes/ui/HUD.tscn` |
| `WaveComplete.tscn` | zombie-ui-manager | `res://scenes/ui/WaveComplete.tscn` |

## Spawn point discovery

Arena.tscn places 8 `Marker3D` nodes named `SpawnPoint0..SpawnPoint7` at radius 12, 45° increments, y=0. Each is in the **`spawn_points` group**. `SpawnRing.gd` discovers them via `get_tree().get_nodes_in_group("spawn_points")`.

## Damage payload format (Weapon.gd → CardSystem → Zombie.gd)

```gdscript
var payload := {
    "damage": weapon.data.base_damage,
    "headshot_multiplier": weapon.data.headshot_multiplier,
    "ammo_cost": 1,
    "source_weapon": self,
    "is_headshot": false,         # filled by hit-detection
    "hit_position": Vector3.ZERO, # filled by hit-detection
    "hit_normal": Vector3.UP,
    "penetration_remaining": 0,
    "knockback_force": 0.0,
}
```

`CardSystem.mutate_payload(payload)` returns the (possibly modified) payload. M1's `CardSystem` is a no-op pass-through.

## Renderer

`Compatibility` (project.godot is already set). Web build requires it.

**Do not use:**
- SSR (screen-space reflections)
- SDFGI
- Volumetric fog
- VoxelGI
- Lightmap GI baking (might work, but skip for M1)

**OK to use:**
- StandardMaterial3D with PBR fields (albedo, metallic, roughness, normal)
- DirectionalLight3D with shadow_enabled
- OmniLight3D, SpotLight3D (with shadows OK)
- Particles via GPUParticles3D
- WorldEnvironment with ProceduralSkyMaterial + ambient light

## Out of scope for M1

(Park in `docs/ideas.md` if relevant; do NOT implement.)

- Multiple weapons (M1 has only the pistol; WeaponManager supports swap but no second slot)
- Multiple enemy types (M1 has only the Walker)
- Multiple waves (M1 has only Wave 1)
- Cards (CardSystem is a no-op stub in M1)
- Tokens / shop / Research Data / meta progression (M2+)
- Bosses, special enemies, audio polish, particles beyond muzzle flash (M3)
