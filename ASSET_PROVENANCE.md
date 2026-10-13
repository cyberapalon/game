# Asset provenance

Inventory for the Lumen Hollow prototype and its first visual pass. No paid asset packs or franchise reference artwork are used. Six original source images were generated specifically for this repository using the built-in image generation tool, following the user's botanical dark-fantasy brief.

| Asset | Source | Notes |
| --- | --- | --- |
| Seed-lantern keeper | Generated `assets/characters/keeper_sheet.png` | Original copper lantern hood and leaf-cloak design; 24 frames, six animation rows. |
| Moss walker | Generated `assets/characters/moss_walker_sheet.png` | Original jade seed-husk beetle; 16 frames, four animation rows. |
| Terrain, plants, and sanctuaries | Generated `assets/environment/conservatory_source.png` | Eight terrain cells and eight prop cutouts. `conservatory_tiles.png` is a packed derivative for the native TileSet. |
| Distant conservatory | Generated `assets/backgrounds/conservatory_depth.png` | Original painted glasshouse, ruins, vegetation, and mist. |
| Near parallax layer | Generated `assets/backgrounds/conservatory_roots.png` | Transparent original columns, lantern pods, roots, and ferns. |
| Slash, dust, impact, and dash | Generated `assets/vfx/garden_sheet.png` | Sixteen original effect frames; Godot draws additional small procedural motes. |
| Interface | Original drawing and native Godot buttons in `ui/hud.gd` | Uses the engine-bundled fallback font. |
| Application icon | Original `common/icon.svg` | Geometric seed-lantern emblem; no external images. |
| Sound effects and ambient drone | Original synthesis recipes in `common/sound.gd` | Runtime PCM generation; no samples, recordings, or third-party music. |
| Engine, bundled fallback font, default export splash | Supplied by Godot 4.7.2 | Retain applicable Godot and bundled-component notices for distribution. |

The complete prompt set is retained in `assets/GENERATION_PROMPTS.md`; source checksums and destinations are in `assets/generation_manifest.json`. No outside images were used as generation references. The reproducible resource builder is `tools/build_art_resources.py`. Cropping, atlas packing, and frame alignment are integration derivatives; source images remain intact.

This inventory records provenance and does not assign a new license to the repository or assert exclusive rights over generated imagery. Before a commercial release, confirm the project's chosen license and include the applicable engine and bundled-component license notices. Keep this inventory updated whenever replacement assets are introduced.
