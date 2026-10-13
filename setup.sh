#!/usr/bin/env bash
# Reproducible game-development VM bootstrap: Ubuntu Server 26.04 ARM64 (also x86_64).
# Run as the regular sudo-enabled user, from the cloned repository root.
# Safe to rerun; keeps existing Codex configuration and game files.
set -Eeuo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
trap 'printf "\nSetup failed at line %s. Fix the error above and rerun ./setup.sh.\n" "$LINENO" >&2' ERR

# Versions: pin the engine, follow stable patches for developer tooling.
GODOT_VERSION=4.7.2
NODE_MAJOR=24
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
LOCAL_BIN="$HOME/.local/bin"
export PATH="$LOCAL_BIN:$PATH"
export PIPX_BIN_DIR="$LOCAL_BIN"

# A focused selection; all names exist in the upstream skills catalog.
GODOT_SKILLS=(
  studio-game-director
  studio-gameplay-lead
  godot-project-foundations
  godot-gdscript-mastery
  godot-characterbody-2d
  godot-combat-system
  godot-genre-metroidvania
  godot-2d-animation
  godot-platform-web
  godot-testing-patterns
  gamedev-platformer
  gamedev-game-feel
  gamedev-level-design
  gamedev-steam-publish
)

[[ $# -eq 0 ]] || { echo 'Usage: ./setup.sh' >&2; exit 2; }
# shellcheck source=/dev/null
source /etc/os-release
[[ "$EUID" -ne 0 && "$ID" == ubuntu && "$VERSION_ID" == 26.04 && -d /run/systemd/system ]] || {
  echo 'Run this script as a regular user on Ubuntu Server 26.04 with sudo access.' >&2
  exit 1
}
case "$(uname -m)" in
  aarch64) godot_arch=arm64 ;;
  x86_64) godot_arch=x86_64 ;;
  *) echo 'Supported architectures: aarch64 (ARM64) and x86_64.' >&2; exit 1 ;;
esac
sudo -v
mkdir -p "$LOCAL_BIN"

echo '==> 1/6 Installing Linux utilities and media tools'
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  ca-certificates curl gnupg git git-lfs jq ripgrep unzip zip xz-utils file \
  python3 python3-venv pipx shellcheck ffmpeg imagemagick \
  libfontconfig1 libfreetype6 libgl1 libx11-6 libxi6 libxcursor1 \
  libxinerama1 libxrandr2 libasound2t64 libudev1 libdbus-1-3
# Keep any future large binary assets compatible with Git LFS (without tracking files yet).
git lfs install --skip-repo >/dev/null

echo '==> 2/6 Installing Node.js LTS and GitHub CLI'
if [[ ! "$(node --version 2>/dev/null || true)" =~ ^v${NODE_MAJOR}\. ]]; then
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | sudo -E bash -
fi
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
sudo chmod 0644 /etc/apt/keyrings/githubcli-archive-keyring.gpg
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' \
  "$(dpkg --print-architecture)" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
sudo apt-get update
sudo apt-get install -y --no-install-recommends nodejs gh
[[ "$(node --version)" == "v${NODE_MAJOR}."* ]] || {
  echo "Expected Node.js ${NODE_MAJOR}.x, got $(node --version)." >&2
  exit 1
}
npm config set prefix "$HOME/.local" --location=user

echo '==> 3/6 Installing the official Godot engine and Web export templates'
release="${GODOT_VERSION}-stable"
release_url="https://github.com/godotengine/godot-builds/releases/download/$release"
engine_archive="Godot_v${release}_linux.${godot_arch}.zip"
engine_exe="Godot_v${release}_linux.${godot_arch}"
templates_archive="Godot_v${release}_export_templates.tpz"
template_dir="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"

# Check only the exact release; never silently use a random distro version.
engine_ok=false
if [[ -x /usr/local/bin/godot ]] && \
   [[ "$(/usr/local/bin/godot --headless --version 2>/dev/null || true)" == "${GODOT_VERSION}.stable."* ]]; then
  engine_ok=true
fi
templates_ok=false
if [[ -s "$template_dir/version.txt" && -s "$template_dir/web_nothreads_debug.zip" \
   && -s "$template_dir/web_nothreads_release.zip" ]]; then
  templates_ok=true
fi

if [[ "$engine_ok" == false || "$templates_ok" == false ]]; then
  work_dir="$(mktemp -d)"
  trap 'rm -rf -- "$work_dir"' EXIT
  curl --fail --location --silent --show-error --retry 4 --retry-delay 2 \
    "$release_url/SHA512-SUMS.txt" -o "$work_dir/SHA512-SUMS.txt"

  # Verify the downloaded artifact against the official release's SHA512-SUMS.txt.
  fetch_and_verify() {
    local asset="$1"
    curl --fail --location --silent --show-error --retry 4 --retry-delay 2 \
      "$release_url/$asset" -o "$work_dir/$asset"
    awk -v asset="$asset" \
      '($2 == asset || $2 == "*" asset) { print; matched = 1 } END { if (!matched) exit 1 }' \
      "$work_dir/SHA512-SUMS.txt" > "$work_dir/checksums.txt" || {
        printf 'No official SHA512 checksum found for %s.\n' "$asset" >&2; return 1;
      }
    (cd "$work_dir" && sha512sum --check --status checksums.txt)
  }

  if [[ "$engine_ok" == false ]]; then
    fetch_and_verify "$engine_archive"
    mkdir -p "$work_dir/bin"
    unzip -j -q "$work_dir/$engine_archive" "$engine_exe" -d "$work_dir/bin"
    sudo install -m 0755 "$work_dir/bin/$engine_exe" /usr/local/bin/godot
  fi
  if [[ "$templates_ok" == false ]]; then
    echo 'Downloading the official export templates (approximately 1.3 GB)...'
    fetch_and_verify "$templates_archive"
    mkdir -p "$work_dir/web-templates"
    # Extract only the normal and single-threaded Web targets for now.
    # Windows/macOS/Linux Steam targets can be installed when needed later.
    unzip -j -q "$work_dir/$templates_archive" \
      'templates/version.txt' \
      'templates/web_debug.zip' 'templates/web_release.zip' \
      'templates/web_nothreads_debug.zip' 'templates/web_nothreads_release.zip' \
      -d "$work_dir/web-templates"
    mkdir -p "$template_dir"
    install -m 0644 "$work_dir/web-templates/"* "$template_dir/"
  fi
  rm -rf -- "$work_dir"
  trap - EXIT
fi
godot --headless --version

echo '==> 4/6 Installing Codex and GDScript quality tools'
npm install --global @openai/codex@latest skills@latest ctx7@latest
if pipx list --json | jq -e '.venvs | has("gdtoolkit")' >/dev/null; then
  pipx runpip gdtoolkit install --upgrade 'gdtoolkit==4.*'
else
  pipx install 'gdtoolkit==4.*'
fi

echo '==> 5/6 Configuring Codex, context documentation, and game-dev skills'
mkdir -p "$CODEX_HOME"
if [[ ! -f "$CODEX_HOME/config.toml" ]]; then
  umask 077
  cat > "$CODEX_HOME/config.toml" <<'CODEX_CONFIG'
# Initial defaults based on the separate, disposable ATL-style VM workflow.
# Codex has full access INSIDE this VM; do not put production credentials in it.
model = "gpt-6.1-sol"
model_reasoning_effort = "xhigh"
model_verbosity = "low"
approval_policy = "never"
sandbox_mode = "danger-full-access"
web_search = "live"
developer_instructions = "Always communicate with the user in Russian. Use English for code, names, identifiers, and files."

[features]
plugins = true
multi_agent = true
CODEX_CONFIG
fi
chmod 0600 "$CODEX_HOME/config.toml"
# Upstream provides 189 skills; install only the relevant subset.
skills add bgrenat/godot-game-dev-studio -g -a codex -y \
  --skill "${GODOT_SKILLS[@]}" </dev/null

# Persist npm's user-level binaries in future SSH/VS Code terminal sessions.
if ! grep -Fqx '# >>> game-development >>>' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'DEVELOPMENT'

# >>> game-development >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< game-development <<<
DEVELOPMENT
fi

echo '==> 6/6 Connecting GitHub and Codex (interactive, only if needed)'
if ! gh auth status --active --hostname github.com >/dev/null 2>&1; then
  gh auth login --hostname github.com --git-protocol https --web
fi
if ! codex login status >/dev/null 2>&1; then
  codex login --device-auth
fi
# Context7 installs an additional Codex documentation skill using a device-flow login.
# Keep this after installation so all login prompts appear at the end.
ctx7 setup --cli --codex --yes

cat <<'COMPLETE'

Setup complete.
  - Reconnect Remote SSH, then open this repository in VS Code.
  - Install VS Code Workspace Recommendations in the Extensions view.
  - Run `godot --headless --version`, `codex --version`, and `gdformat --version`.
  - Start Codex and ask it to create `project.godot`, playable scenes, and a Web build.
  - After Codex creates the game, follow README.md to export and serve it on port 8000.

For a native Godot editor, install the same version separately on macOS later.
COMPLETE
