# Linux patch (unofficial)

This repository is a **local patch** of [mcp-router/mcp-router](https://github.com/mcp-router/mcp-router),
based on its final release (v0.6.4, end of support 2026-09-18). It is not affiliated with or endorsed by
the original authors, and it is maintained for personal, non-commercial use only.

The original code is licensed under the Sustainable Use License (see [LICENSE.md](LICENSE.md)), which
continues to apply to this patch. All original license and copyright notices are kept unchanged.

The `main` branch mirrors upstream; the Linux changes live on the `linux-port` branch.

## What the patch changes

- **Build**: `nodeLinker: hoisted` moved into `pnpm-workspace.yaml` (pnpm 10 no longer reads it from
  `.npmrc`, which Electron Forge requires); Linux binary named `mcp-router`; `desktopName` set so the
  window, launcher and `mcpr://` handler match.
- **Install**: `tools/linux/install.sh` installs the packaged build per user (app files, launcher on
  `PATH`, icon, `.desktop` entry, `mcpr://` handler). `--uninstall` removes it.
- **Start at login**: writes an XDG autostart entry, since Electron's login-item API is a no-op on Linux.
- **`mcpr://` links**: handles a link passed on cold start (`argv`), not only to a running instance.
- **Secrets**: forces the Secret Service keyring (`--password-store=gnome-libsecret`) on desktops
  Chromium doesn't recognize (niri, sway, Hyprland, ...), where it would otherwise fall back to storing
  tokens unencrypted. KDE and an explicit `--password-store` flag are left alone.

## Build and install

```bash
pnpm install
pnpm turbo run build --filter='./packages/*'
pnpm --filter @mcp_router/electron run package
tools/linux/install.sh
```
