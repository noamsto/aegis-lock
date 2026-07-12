# Aegis Lock

Standalone Wayland lockscreen for Hyprland, built with [Quickshell](https://quickshell.outfoxxed.me/). Supports PAM password authentication, fingerprint unlock via fprintd, and automatic Material Design 3 theming from [Noctalia](https://github.com/noctalia-dev).

## Features

- Password and fingerprint authentication (via PAM)
- Blurred wallpaper background (reads current wallpaper from Noctalia)
- Password character reveal — typed characters show briefly before masking
- Shake and scale animation on authentication failure
- Automatic color sync with Noctalia's Material Design 3 scheme
- Session controls (logout, suspend, reboot, shutdown) with safety countdown
- Media playback controls (playerctl)
- Battery and keyboard layout indicators
- RTL text support (Hebrew, Arabic)
- Configurable clock format, date format, and UI options
- NixOS Home Manager module for declarative setup

## Installation

### Flake input

From [FlakeHub](https://flakehub.com/flake/noamsto/aegis-lock) (recommended — includes binary cache so you don't have to build from source):

```nix
{
  inputs.aegis-lock.url = "https://flakehub.com/f/noamsto/aegis-lock/*.tar.gz";
}
```

To use the FlakeHub binary cache, add the [FlakeHub cache](https://docs.flakehub.com/docs/cache) to your NixOS or nix config:

```nix
# configuration.nix
{
  nix.settings = {
    extra-substituters = [ "https://cache.flakehub.com" ];
    extra-trusted-public-keys = [ "cache.flakehub.com-1:t6986ugxCA+d/ZF9IaN/dblm8aAKnJoMbuzEHbU0Rn8=" ];
  };
}
```

Or from GitHub (builds from source):

```nix
{
  inputs.aegis-lock.url = "github:noamsto/aegis-lock";
}
```

### Home Manager module

Add the module to your Home Manager imports and enable it:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    aegis-lock.url = "https://flakehub.com/f/noamsto/aegis-lock/*.tar.gz";
  };

  outputs = { nixpkgs, home-manager, aegis-lock, ... }: {
    homeConfigurations."user" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        aegis-lock.homeModules.default
        {
          programs.aegis-lock = {
            enable = true;

            # Optional: override settings (merged with defaults)
            settings = {
              general = {
                clockFormat = "HH:mm";
                dateFormat = "dddd, MMMM d";
                showSessionButtons = true;
                countdownEnabled = true;
                countdownDuration = 10000; # ms before session action executes
              };
            };

            # Optional: use system PAM instead of per-user configs (see PAM section)
            # pamConfig = "aegis-lock";

            # Optional: disable fingerprint auth
            # fingerprint.enable = false;
          };
        }
      ];
    };
  };
}
```

### Noctalia session menu

If you use [Noctalia](https://github.com/noctalia-dev) as your Hyprland shell, you can replace its built-in lock screen with Aegis Lock by giving the lock action a `command`. Setting a command routes the lock button (session panel, `/session` launcher, and `noctalia msg session lock`) through Aegis Lock instead of Noctalia's built-in lockscreen.

**Noctalia v5** — add to any `~/.config/noctalia/*.toml`:

```toml
[[shell.session.actions]]
action = "lock"
command = "aegis-lock"
```

**Noctalia v4** — in `~/.config/noctalia/gui-settings.json`, add a `command` field to the lock entry in `sessionMenu.powerOptions`:

```json
{
  "sessionMenu": {
    "powerOptions": [
      { "action": "lock", "enabled": true, "command": "aegis-lock" }
    ]
  }
}
```

Colors are synced automatically (see [Noctalia color sync](#noctalia-color-sync)).

### Hyprland integration

Bind aegis-lock to your preferred lock key in your Hyprland config:

```conf
# hyprland.conf
bind = SUPER, L, exec, aegis-lock
```

Or with `hyprlock`-style idle locking via `hypridle`:

```conf
# hypridle.conf
listener {
    timeout = 300
    on-timeout = aegis-lock
}
```

### PAM configuration on NixOS

Aegis Lock ships two authentication modes:

**Per-user PAM configs (default, recommended for fingerprint users)**

The Home Manager module generates separate PAM configs in `~/.config/aegis-lock/pam/` — one for fingerprint and one for password. Aegis Lock runs them as separate PAM sessions and switches between them: fingerprint starts automatically after the shield is dismissed, and the user can press Enter at any time to abort fingerprint and switch to password input instantly. This is the same approach GDM uses for concurrent fingerprint + password.

No extra NixOS config needed — just enable fingerprint:

```nix
{
  programs.aegis-lock = {
    enable = true;
    fingerprint.enable = true; # default
  };
}
```

Make sure fprintd is enabled in your NixOS config:

```nix
# configuration.nix
{
  services.fprintd.enable = true;
}
```

**System PAM config (simpler, password-only or sequential)**

For setups without fingerprint, or if you prefer system-managed PAM rules, you can point aegis-lock to a single `/etc/pam.d/` config. Note: with a single PAM stack, fingerprint and password run sequentially — the user must wait for fingerprint to timeout before password input is accepted.

```nix
# configuration.nix
{
  security.pam.services.aegis-lock = {};
}
```

```nix
# Home Manager
{
  programs.aegis-lock = {
    enable = true;
    pamConfig = "aegis-lock"; # uses /etc/pam.d/aegis-lock
  };
}
```

## Wallpaper background

Aegis Lock displays your current wallpaper as a blurred background behind the lock screen. It reads the wallpaper path from `~/.config/noctalia/last-wallpaper`, written by a Noctalia wallpaper-change hook. The file is watched for changes, so wallpaper updates are reflected live.

**Noctalia v5** — add to any `~/.config/noctalia/*.toml`. The changed wallpaper's path is exposed as `$NOCTALIA_WALLPAPER_PATH`:

```toml
[hooks]
wallpaper_changed = 'echo "$NOCTALIA_WALLPAPER_PATH" > ~/.config/noctalia/last-wallpaper'
```

**Noctalia v4** — in `~/.config/noctalia/gui-settings.json`, the path is the positional `$1`:

```json
{
  "wallpaper": {
    "hooks": {
      "wallpaperChange": "echo \"$1\" > ~/.config/noctalia/last-wallpaper"
    }
  }
}
```

If the file doesn't exist or is empty, Aegis Lock falls back to a solid color background using the theme's surface color.

## Noctalia color sync

Aegis Lock picks up Noctalia's color scheme from `~/.config/noctalia/colors.json`, read on startup and watched for changes. The following Material Design 3 keys are used:

| colors.json key     | Aegis Lock property       |
|---------------------|---------------------------|
| `primary`           | Accent color              |
| `onPrimary`         | Text on accent            |
| `primaryContainer`  | Accent container          |
| `surface`           | Background                |
| `onSurface`         | Primary text              |
| `surfaceVariant`    | Secondary surfaces        |
| `onSurfaceVariant`  | Secondary text            |
| `error`             | Error states              |
| `onError`           | Text on error             |
| `outline`           | Borders                   |

**Noctalia v5** no longer writes `colors.json` directly — its live palette is exposed through the template system. Install the bundled template so Noctalia regenerates `colors.json` on every palette change:

```bash
cp contrib/noctalia-v5-colors.json ~/.config/noctalia/templates/aegis-colors.json
```

Then add to any `~/.config/noctalia/*.toml`:

```toml
[theme.templates.user.aegis_lock]
input_path  = "$XDG_CONFIG_HOME/noctalia/templates/aegis-colors.json"
output_path = "$XDG_CONFIG_HOME/noctalia/colors.json"
```

**Noctalia v4** writes `~/.config/noctalia/colors.json` itself — no template needed.

To override Noctalia's colors, create `~/.config/aegis-lock/colors.json` with the same key format. This takes priority over Noctalia.

## Configuration

Settings are read from `~/.config/aegis-lock/config.json` and deep-merged with defaults. The Home Manager module writes this file for you via `programs.aegis-lock.settings`.

Default values:

```json
{
  "general": {
    "avatarImage": "",
    "fingerprintEnabled": true,
    "clockFormat": "HH:mm",
    "dateFormat": "dddd, MMMM d",
    "showSessionButtons": true,
    "countdownEnabled": true,
    "countdownDuration": 10000
  },
  "theme": {
    "source": "auto",
    "colorsFile": ""
  }
}
```

## Development

```bash
# Enter dev shell
nix develop

# Preview mode (floating window, Esc to quit)
AEGIS_PREVIEW=1 qs -p .

# With debug logging
AEGIS_DEBUG=1 AEGIS_PREVIEW=1 qs -p .

# Real session lock (covers all monitors)
# Escape hatch: Ctrl+Alt+F2 → login → killall qs
qs -p .
```

See [TESTING.md](TESTING.md) for detailed testing instructions.

## License

MIT
