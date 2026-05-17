# Art Sources & Licenses

All textures in this directory are **CC0 (public domain)**. No attribution legally required.

## materials/

All six PBR material sets sourced from **AmbientCG** (https://ambientcg.com), CC0. The 1K JPG variant was downloaded; only the maps we use (Color, NormalGL, Roughness, Metalness, Displacement) are committed — `.blend` / `.mtlx` / `.usdc` / preview `.png` and the redundant `NormalDX` were dropped.

OpenGL normal convention is used (Godot expects GL, not DX).

| Folder | Source asset | Notes |
|---|---|---|
| `concrete/` | Concrete034 — https://ambientcg.com/view?id=Concrete034 | Clean facility concrete. Color, NormalGL, Roughness, Height. Non-metal — no metalness map. |
| `metal_panel/` | MetalPlates006 — https://ambientcg.com/view?id=MetalPlates006 | Painted/sealed metal panel — modular wall trim. Includes Metalness. |
| `rusty_steel/` | Metal021 — https://ambientcg.com/view?id=Metal021 | Weathered/rusty steel — perimeter scaffolds, age accents. Includes Metalness. |
| `lab_tile/` | Tiles074 — https://ambientcg.com/view?id=Tiles074 | Clean lab-tile floor for the Containment Lab. Non-metal. |
| `weapon_metal/` | Metal032 — https://ambientcg.com/view?id=Metal032 | Dense brushed-steel for viewmodel slides/barrels. Includes Metalness. |
| `weapon_polymer/` | Plastic010 — https://ambientcg.com/view?id=Plastic010 | Matte polymer for grips/stocks. Non-metal. |

## Format / size

- All maps 1024×1024 JPG (AmbientCG's 1K JPG bundle).
- Total committed: ~12 MB on disk.

## KTX2 / Basis conversion (deferred)

AmbientCG ships JPG; Godot's exporter will compress these during web export. KTX2 supercompression can be done in a future pass if the export size blows the 80 MB initial-download budget. Conversion command (for reference, requires `toktx` from KTX-Software):

```
toktx --t2 --bcmp --genmipmap --assign_oetf srgb out.ktx2 input_color.jpg     # albedo (sRGB)
toktx --t2 --bcmp --genmipmap --assign_oetf linear out.ktx2 input_normal.jpg  # normal/rough/metal (linear)
```

For now, JPG sources are fine — Godot does its own VRAM compression at export time.

## Godot StandardMaterial3D files

Each subfolder also contains a `material.tres` ready to drop on any mesh (UV-tiling handled per-mesh). These were hand-authored, not from AmbientCG's bundled `.tres` (which references stripped maps).

## Next-priority sourcing (not yet landed)

If a future asset-scout pass has budget remaining:
- **Models**: low-poly zombie (CC0 Quaternius "Survivors" or BeepBox riggable), 3 modular wall meshes for kit-bashing, ceiling panel mesh, generic crate prop.
- **HDRI** for IBL ambient lighting: Poly Haven `factory_yard_1k.hdr` or similar industrial-interior CC0 HDRI.
- **Decals**: blood splatter, scorch mark, warning tape — CC0 alpha PNGs.
