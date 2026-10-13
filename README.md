# Godot Game Starter (Ubuntu ARM64 VM)

Minimal repository setup for Godot 4.7.2, Codex CLI, VS Code Remote SSH, and browser preview. The VM stays isolated from macOS; no GUI, Docker, database, or JavaScript game runtime is required.

## One-time VM setup

Ubuntu Server 26.04 (ARM64) in UTM, with a sudo-enabled regular user and an SSH connection from VS Code on macOS:

```bash
chmod +x setup.sh
./setup.sh
```

Setup installs: official Godot editor CLI, single-threaded and threaded Web export templates, Node.js 24 LTS, Codex, Context7, selected Godot/game-dev skills, GitHub CLI, Git LFS, gdformat/gdlint, ShellCheck, FFmpeg, ImageMagick, and basic utilities. The official Godot export-templates archive is ~1.3 GB; sufficient free disk space and network access are required. Downloads are checked against the official SHA512 release file.

Setup asks for GitHub and Codex authorization only when required. It will not overwrite existing `~/.codex/config.toml`. By default, a newly generated Codex config grants full access within the disposable VM; avoid keeping sensitive credentials there.

Reconnect VS Code Remote SSH after setup. Install recommended extensions from the workspace (`.vscode/extensions.json`). Godot Tools is configured to launch a headless language server from the VM; the desktop Godot editor is optional.

## First Codex task

Run `codex` in this repository root and ask it to create a playable, original 2D platformer prototype. It should create `project.godot`, all scenes/scripts/assets, configure a main scene and input map, use the Compatibility renderer, and validate the existing `Web` export preset. A complete sample prompt is included in the ChatGPT response that provided this starter.

## Build and view on macOS

After Codex has generated a working Godot project (`project.godot` exists):

```bash
# Import/validate resources using the headless engine.
godot --headless --path . --editor --import

# Build the browser version.
mkdir -p build/web
godot --headless --path . --export-debug "Web" build/web/index.html

# Serve over SSH port forwarding (keep this terminal open).
python3 -m http.server 8000 --bind 127.0.0.1 --directory build/web
```

In VS Code Ports, forward `8000` if it wasn't forwarded automatically. Then open **http://localhost:8000** in Chrome/Brave on macOS. Game changes require re-export and page refresh; this is not Next.js hot reload. The default Web export is single-threaded, so a simple local HTTP server works without special COOP/COEP headers.

## Optional Godot MCP plugin

Godot MCP is **not required** for the first playable prototype. Once `project.godot` exists, you can add a third-party MIT-licensed editor bridge (inspect the project changes before committing):

```bash
npx --yes @srdarkx/godot-mcp@latest init . --client codex
npx --yes @srdarkx/godot-mcp@latest doctor .
```

Restart Codex after adding the project-local MCP configuration. Live editor operations require the Godot editor/bridge running; file editing, headless validation, and Web export work without MCP. In a VM without a GUI, full live screenshot/editor features may not be available. Do not assume the MCP can see a browser running on the Mac.

## Later: Steam

For Windows/macOS/Linux release builds, add desktop export presets and their matching templates, validate on actual target systems, integrate Steamworks, and include Godot and asset license notices. You do not need to change engines.
