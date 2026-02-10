# Aegis Lock

Standalone Wayland lockscreen for Hyprland, built with [Quickshell](https://quickshell.outfoxxed.me/). Supports PAM password authentication, fingerprint unlock via fprintd, and automatic Material Design 3 theming from [Noctalia](https://github.com/noctalia).

## Features

- Password and fingerprint authentication (via PAM)
- Automatic color sync with Noctalia's color scheme
- Session controls (logout, suspend, reboot, shutdown) with safety countdown
- Media playback controls (playerctl)
- Battery and keyboard layout indicators
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

If you use [Noctalia](https://github.com/noctalia) as your Hyprland shell, you can replace its built-in lock screen with Aegis Lock. In `~/.config/noctalia/gui-settings.json`, add a `command` field to the lock entry in `sessionMenu.powerOptions`:

```json
{
  "sessionMenu": {
    "powerOptions": [
      {
        "action": "lock",
        "enabled": true,
        "command": "aegis-lock"
      }
    ]
  }
}
```

When you press the lock button in Noctalia's session menu, it will launch Aegis Lock instead of Noctalia's built-in lock screen. Colors are synced automatically (see [Noctalia color sync](#noctalia-color-sync)).

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

Aegis Lock generates per-user PAM configs by default (`~/.config/aegis-lock/pam/`). On NixOS, you can use system-level PAM instead for better security:

```nix
# configuration.nix (NixOS system config)
{
  security.pam.services.aegis-lock = {};
}
```

Then in your Home Manager config, point aegis-lock to the system PAM config:

```nix
{
  programs.aegis-lock = {
    enable = true;
    pamConfig = "aegis-lock"; # uses /etc/pam.d/aegis-lock
  };
}
```

For fingerprint support with system PAM, add fprintd:

```nix
# configuration.nix
{
  services.fprintd.enable = true;
  security.pam.services.aegis-lock = {
    fprintAuth = true;
  };
}
```

## Noctalia color sync

Aegis Lock automatically picks up Noctalia's color scheme. When Noctalia generates a `~/.config/noctalia/colors.json`, Aegis Lock reads it on startup and watches for changes. The following Material Design 3 keys are used:

| colors.json key     | Aegis Lock property       |
|---------------------|---------------------------|
| `primary`           | Accent color              |
| `onPrimary`         | Text on accent            |
| `surface`           | Background                |
| `onSurface`         | Primary text              |
| `surfaceVariant`    | Secondary surfaces        |
| `onSurfaceVariant`  | Secondary text            |
| `error`             | Error states              |
| `onError`           | Text on error             |
| `outline`           | Borders                   |

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
