# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Aegis Lock is a Wayland lockscreen built with **Quickshell** (QML-based shell framework). It supports PAM password authentication, fingerprint authentication via fprintd, and Material Design 3 theming.

## Development Commands

```bash
# Enter dev shell (or use direnv)
nix develop

# Run in preview mode (safe - floating window, Esc to quit)
AEGIS_PREVIEW=1 qs -p .

# Run with debug logging
AEGIS_DEBUG=1 AEGIS_PREVIEW=1 qs -p .

# Run as real session lock (risky - covers all monitors)
# Escape hatch: Ctrl+Alt+F2, login to TTY, killall qs
qs -p .

# Nix lint tools available in dev shell
nixfmt flake.nix        # Format nix files
statix check .          # Nix linter
deadnix .               # Find dead nix code
jsonfmt Assets/*.json   # Format JSON
shellcheck <script>     # Shell script linter
```

There are no automated tests. Testing is manual via preview mode or nested compositor (`cage -- qs -p .`).

## Architecture

**Entry point**: `shell.qml` — initializes all singletons, then loads either `PreviewSurface` (floating window) or `LockSurface` (real Wayland session lock via `WlSessionLock`).

### Module Organization

| Directory | Pattern | Purpose |
|-----------|---------|---------|
| `Core/` | Singletons | Config, Log, Theme, Locale — global state and services |
| `Services/` | Singletons | Battery, Keyboard, Media — system status polling via CLI tools |
| `Auth/` | Mixed | AuthController (per-surface instance), FingerprintDetector + PamConfigs (singletons) |
| `UI/` | Components | Visual components composed into surfaces |
| `Assets/` | Data | Default config JSON, translation strings |
| `nix/` | Build | Package, dev shell, Home Manager module |

### Authentication Flow

AuthController is the core state machine — **not** a singleton, instantiated per surface. It manages PAM context lifecycle:

1. Shield dismisses on any keypress/click
2. If fingerprint available: starts fingerprint PAM context first
3. User can press Enter to abort fingerprint and switch to password-only mode
4. Password mode: sends input to PAM via `pam.respond()`
5. PAM result determines unlock/retry

PAM configs are per-user files in `~/.config/aegis-lock/pam/` (created by PamConfigs.qml) unless `AEGIS_PAM_CONFIG` env var specifies a system PAM config name.

### Configuration Hierarchy

1. `Assets/config-default.json` — bundled defaults
2. `~/.config/aegis-lock/config.json` — user overrides (deep-merged, hot-reloaded via FileView)

Theme colors: own override (`~/.config/aegis-lock/colors.json`) → noctalia colors (`~/.config/noctalia/colors.json`) → built-in Material 3 defaults.

### Key Environment Variables

- `AEGIS_PREVIEW=1` — preview mode (floating window instead of session lock)
- `AEGIS_DEBUG=1` — enable debug-level logging
- `AEGIS_CONFIG_DIR` — override config directory path
- `AEGIS_PAM_CONFIG` — use system PAM config name instead of per-user configs

### QML Patterns

- **Singletons** for global state (Config, Theme, Log, Locale, services)
- **Scoped components** for per-instance state (AuthController)
- **FileView** for watched file monitoring with hot reload
- **Process/StdioCollector** for external command execution (battery, keyboard, fingerprint, media, session controls)
- **Timers** for polling intervals (battery 30s, keyboard 5s, media 3s)
- System detection with fallbacks (hyprctl → swaymsg, BAT0 → BAT1)

### Nix Outputs

- `packages.default` — the aegis-lock package (wraps `qs` binary with project path)
- `devShells.default` — dev environment with Quickshell, linters, QML tooling
- `homeModules.default` — Home Manager module for declarative config/PAM setup
- `overlays.default` — package overlay
