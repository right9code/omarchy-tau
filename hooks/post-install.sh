#!/usr/bin/env bash
set -e

TAU_SRC_DIR="$HOME/Projects/tau"
BIN_DIR="$HOME/.local/bin"
STUB_PATH="$BIN_DIR/tau"
APPS_DIR="$HOME/.local/share/applications"
MENU_EXT_DIR="$HOME/.config/omarchy/extensions"
THEME_HOOK_DIR="$HOME/.config/omarchy/hooks/theme-set.d"
DEFAULTS_DIR="$HOME/.config/omarchy/defaults"

echo "[Omarchy Tau] Initializing custom Tau setup..."

# 1. Resolve Bun runner
if command -v bun &> /dev/null; then
  BUN_CMD="bun"
elif command -v mise &> /dev/null; then
  echo "[Omarchy Tau] Using Bun via mise..."
  mise use -g --quiet "bun" 2>/dev/null || true
  BUN_CMD="mise x bun -- bun"
elif [ -f "$HOME/.bun/bin/bun" ]; then
  BUN_CMD="$HOME/.bun/bin/bun"
else
  echo "[Omarchy Tau] Error: Bun binary not found! Please install Bun or activate it in mise."
  exit 1
fi

# 2. Verify Tau repo exists
if [ ! -d "$TAU_SRC_DIR" ]; then
  echo "[Omarchy Tau] Repository not found at $TAU_SRC_DIR. Cloning..."
  mkdir -p "$HOME/Projects"
  git clone https://github.com/right9code/tau "$TAU_SRC_DIR"
fi

# 3. Install dependencies & build Tau
cd "$TAU_SRC_DIR"
echo "[Omarchy Tau] Installing Tau dependencies..."
$BUN_CMD install

echo "[Omarchy Tau] Adding missing esbuild dynamic imports..."
$BUN_CMD add -d @smithy/node-http-handler @smithy/core @aws-sdk/credential-provider-node 2>/dev/null || true

echo "[Omarchy Tau] Building Tau..."
$BUN_CMD run build

# 4. Create launcher stub in ~/.local/bin/tau
mkdir -p "$BIN_DIR"
cat << 'STUB_EOF' > "$STUB_PATH"
#!/usr/bin/env bash
TAU_DIR="$HOME/Projects/tau"
export MISE_MINIMUM_RELEASE_AGE=0
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"

if command -v bun &> /dev/null; then
    RUNNER="bun"
elif command -v mise &> /dev/null; then
    RUNNER="mise x bun -- bun"
else
    RUNNER="$HOME/.bun/bin/bun"
fi

if [ -f "$TAU_DIR/dist/cli.mjs" ]; then
    exec $RUNNER run "$TAU_DIR/dist/cli.mjs" "$@"
elif [ -f "$TAU_DIR/dist/tau.mjs" ]; then
    exec $RUNNER run "$TAU_DIR/dist/tau.mjs" "$@"
else
    exec $RUNNER run --cwd "$TAU_DIR" start "$@"
fi
STUB_EOF
chmod +x "$STUB_PATH"
echo "[Omarchy Tau] Installed executable stub to $STUB_PATH"

# 5. Create Desktop Entry for application launcher
mkdir -p "$APPS_DIR"
cat << 'DESKTOP_EOF' > "$APPS_DIR/tau.desktop"
[Desktop Entry]
Name=Tau Agent
Comment=Custom AI coding agent
Exec=omarchy-launch-tui --app-id=org.omarchy.agent tau
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=Development;Utility;
StartupNotify=true
DESKTOP_EOF
update-desktop-database "$APPS_DIR" 2>/dev/null || true

# 6. Add theme sync hook
mkdir -p "$THEME_HOOK_DIR"
cat << 'HOOK_EOF' > "$THEME_HOOK_DIR/99-tau-theme.sh"
#!/usr/bin/env bash
THEME_NAME="$1"
TAU_CFG="$HOME/.config/tau"
mkdir -p "$TAU_CFG"
echo "{\"theme\": \"$THEME_NAME\"}" > "$TAU_CFG/omarchy-theme.json"
HOOK_EOF
chmod +x "$THEME_HOOK_DIR/99-tau-theme.sh"

# 7. Add Tau to Omarchy Menu
mkdir -p "$MENU_EXT_DIR"
cat << 'MENU_EOF' > "$MENU_EXT_DIR/omarchy-menu.jsonc"
{
  "setup.default.agent.tau": {
    "icon": "󰚩",
    "label": "Tau",
    "checked": "[[ \"$(omarchy-default-agent)\" == \"tau\" ]]",
    "action": "mkdir -p ~/.config/omarchy/defaults && echo tau > ~/.config/omarchy/defaults/agent && omarchy menu refresh && notify-send 'Default Agent' 'Set to Tau'"
  }
}
MENU_EOF
omarchy menu refresh 2>/dev/null || true

# 8. Set Tau as default agent
mkdir -p "$DEFAULTS_DIR"
echo "tau" > "$DEFAULTS_DIR/agent"

# 9. Ensure omarchy-agent has tau dispatcher
if [ -f /usr/bin/omarchy-agent ] && ! grep -q "tau)" /usr/bin/omarchy-agent; then
  echo "[Omarchy Tau] Patching /usr/bin/omarchy-agent..."
  sudo sed -i '/^\*)/i \tau)\n  command=(tau)\n  [[ -n ${prompt:-} ]] && command+=("$prompt")\n  ;;\n' /usr/bin/omarchy-agent || true
fi

echo "[Omarchy Tau] Installation completed successfully!"
