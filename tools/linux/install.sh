#!/usr/bin/env bash
# Install (or uninstall) the packaged Linux build for the current user.
#
#   pnpm --filter @mcp_router/electron run package   # build first
#   tools/linux/install.sh                           # install / update
#   tools/linux/install.sh --uninstall               # remove (keeps app data)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/apps/electron/out/MCP Router-linux-x64"
ICON_SRC="$REPO_ROOT/apps/electron/public/images/icon/icon.png"

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
APP_DIR="$DATA_HOME/mcp-router/app"
BIN_LINK="$HOME/.local/bin/mcp-router"
DESKTOP_FILE="$DATA_HOME/applications/mcp-router.desktop"
ICON_FILE="$DATA_HOME/icons/hicolor/512x512/apps/mcp-router.png"
AUTOSTART_FILE="$CONFIG_HOME/autostart/mcp-router.desktop"

refresh_caches() {
  update-desktop-database "$DATA_HOME/applications" 2>/dev/null || true
  gtk-update-icon-cache -q "$DATA_HOME/icons/hicolor" 2>/dev/null || true
}

if [[ "${1:-}" == "--uninstall" ]]; then
  rm -rf "$DATA_HOME/mcp-router" "$BIN_LINK" "$DESKTOP_FILE" "$ICON_FILE" "$AUTOSTART_FILE"
  refresh_caches
  echo "Uninstalled. App data in $CONFIG_HOME/MCP Router was kept."
  exit 0
fi

if [[ ! -x "$BUILD_DIR/mcp-router" ]]; then
  echo "No build found at: $BUILD_DIR" >&2
  echo "Run: pnpm --filter @mcp_router/electron run package" >&2
  exit 1
fi

if pgrep -f "$APP_DIR/mcp-router" >/dev/null; then
  echo "MCP Router is running; quit it (tray > Quit) before updating." >&2
  exit 1
fi

# App files
rm -rf "$APP_DIR"
mkdir -p "$(dirname "$APP_DIR")"
cp -a "$BUILD_DIR" "$APP_DIR"

# Launcher on PATH
mkdir -p "$(dirname "$BIN_LINK")"
ln -sfn "$APP_DIR/mcp-router" "$BIN_LINK"

# Icon (source is 530x530; scale to a standard size when ImageMagick is available)
mkdir -p "$(dirname "$ICON_FILE")"
if command -v magick >/dev/null; then
  magick "$ICON_SRC" -resize 512x512 "$ICON_FILE"
else
  cp "$ICON_SRC" "$ICON_FILE"
fi

# Desktop entry; the name must match "desktopName" in apps/electron/package.json
# xdg-open's generic mode (niri, sway, ...) doesn't unquote Exec, so only quote when needed
EXEC_PATH="$APP_DIR/mcp-router"
[[ "$EXEC_PATH" == *" "* ]] && EXEC_PATH="\"$EXEC_PATH\""
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=MCP Router
Comment=Manage MCP servers
Exec=$EXEC_PATH %U
Icon=mcp-router
Terminal=false
Categories=Development;
StartupWMClass=mcp-router
MimeType=x-scheme-handler/mcpr;
EOF

refresh_caches
xdg-mime default mcp-router.desktop x-scheme-handler/mcpr

echo "Installed to $APP_DIR"
echo "Launch from your app menu or run: mcp-router"
