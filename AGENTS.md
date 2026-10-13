# Game development instructions

- Godot 4.7.2, GDScript, 2D, browser-first, desktop/Steam later. Do not use Godot 3 APIs, C#, .NET, or extensions that break Web export.
- Speak to the user in Russian; write source code, identifiers, filenames, and documentation in English.
- Work on the current branch; do not create branches, commit, or push unless asked. Preserve existing changes.
- Make a small playable vertical slice before designing a large game. Optimize for precise, satisfying player control and game feel.
- Keep scenes/components reusable, code statically typed where practical, and use Godot-native facilities instead of recreating engine systems.
- Use relevant installed Godot/game-development skills. For Godot API details, consult official Godot 4.7 documentation (Context7 if available).
- Before handoff, import resources and check errors with `godot --headless --path . --editor --import`. Export a browser debug build with `godot --headless --path . --export-debug "Web" build/web/index.html` and report any warnings or limitations.
- `export_presets.cfg` contains the single-threaded Web preset. Preserve Web compatibility, using the Compatibility renderer (WebGL 2.0).
- Use original or appropriately licensed assets. Track provenance/licenses before any commercial release; do not copy Hollow Knight characters, music, art, or maps.
- Keep the environment reproducible. Do not run the full `setup.sh` during ordinary feature implementation.
