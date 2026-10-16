#!/usr/bin/env bash
# Bundle the packaged Linux build into a release tarball:
#
#   pnpm --filter @mcp_router/electron run package   # build first
#   tools/linux/make-release.sh                      # -> dist/mcp-router-<version>-linux-x64.tar.gz
#
# The tarball contains the app, install.sh, the icon and the license; users
# extract it and run ./install.sh.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/apps/electron/out/MCP Router-linux-x64"
VERSION="$(node -p "require('$REPO_ROOT/apps/electron/package.json').version")"
NAME="mcp-router-$VERSION-linux-x64"
STAGE="$REPO_ROOT/dist/$NAME"

if [[ ! -x "$BUILD_DIR/mcp-router" ]]; then
  echo "No build found at: $BUILD_DIR" >&2
  echo "Run: pnpm --filter @mcp_router/electron run package" >&2
  exit 1
fi

rm -rf "$STAGE" "$STAGE.tar.gz"
mkdir -p "$STAGE"
cp -a "$BUILD_DIR" "$STAGE/app"
cp "$REPO_ROOT/tools/linux/install.sh" "$STAGE/"
cp "$REPO_ROOT/apps/electron/public/images/icon/icon.png" "$STAGE/"
cp "$REPO_ROOT/LICENSE.md" "$STAGE/"

cat >"$STAGE/README.txt" <<EOF
MCP Router $VERSION for Linux (x86_64) - unofficial patch

An unofficial Linux build of MCP Router (https://github.com/mcp-router/mcp-router),
not affiliated with or endorsed by its authors. Free, for personal and
non-commercial use; see LICENSE.md.

Install:    ./install.sh
Uninstall:  ./install.sh --uninstall

Source and docs: https://github.com/jubeater/mcp-router
EOF

tar -C "$REPO_ROOT/dist" -czf "$STAGE.tar.gz" "$NAME"
(cd "$REPO_ROOT/dist" && sha256sum "$NAME.tar.gz" >"$NAME.tar.gz.sha256")
rm -rf "$STAGE"

echo "$REPO_ROOT/dist/$NAME.tar.gz"
