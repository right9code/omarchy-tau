#!/usr/bin/env bash
set -e

BIN_STUB="$HOME/.local/bin/tau"
DESKTOP_ENTRY="$HOME/.local/share/applications/tau.desktop"
THEME_HOOK="$HOME/.config/omarchy/hooks/theme-set.d/99-tau-theme.sh"
THEME_CONFIG="$HOME/.config/tau/omarchy-theme.json"
MENU_EXT="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
DEFAULT_AGENT_FILE="$HOME/.config/omarchy/defaults/agent"

echo "[Omarchy Tau] Executing removal and cleanup..."

# 1. Remove binary stub
if [ -f "$BIN_STUB" ]; then
  rm -f "$BIN_STUB"
  echo "  - Removed $BIN_STUB"
fi

# 2. Remove desktop launcher
if [ -f "$DESKTOP_ENTRY" ]; then
  rm -f "$DESKTOP_ENTRY"
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  echo "  - Removed $DESKTOP_ENTRY"
fi

# 3. Remove theme sync hook & config
if [ -f "$THEME_HOOK" ]; then
  rm -f "$THEME_HOOK"
  echo "  - Removed $THEME_HOOK"
fi
if [ -f "$THEME_CONFIG" ]; then
  rm -f "$THEME_CONFIG"
  echo "  - Removed $THEME_CONFIG"
fi

# 4. Remove Tau from Omarchy Menu & refresh
if [ -f "$MENU_EXT" ]; then
  # Reset the menu extension
  echo "{}" > "$MENU_EXT"
  omarchy menu refresh 2>/dev/null || true
  echo "  - Cleared Tau from $MENU_EXT"
fi

# 5. Reset default agent if it is set to tau
if [ -f "$DEFAULT_AGENT_FILE" ] && [ "$(cat "$DEFAULT_AGENT_FILE" 2>/dev/null)" = "tau" ]; then
  rm -f "$DEFAULT_AGENT_FILE"
  echo "  - Reset default agent setting"
fi

# 6. Clean up dispatcher from /usr/bin/omarchy-agent if present
if [ -f /usr/bin/omarchy-agent ] && grep -q "tau)" /usr/bin/omarchy-agent; then
  echo "  - Removing tau dispatcher from /usr/bin/omarchy-agent..."
  sudo sed -i '/tau)/,+3d' /usr/bin/omarchy-agent 2>/dev/null || true
fi

echo "[Omarchy Tau] Removal complete!"
