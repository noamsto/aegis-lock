# Testing Aegis Lock

## Prerequisites

- [Quickshell](https://github.com/quickshell-mirror/quickshell) installed (`qs` binary)
- A running Wayland session
- `fprintd` installed (optional, for fingerprint testing)

## 1. Preview Mode (Safest)

Renders the lock UI in a regular floating window. No session lock is grabbed —
you can close the window or press Esc to quit at any time. PAM authentication
still works, so you can verify password and fingerprint flows.

```sh
AEGIS_PREVIEW=1 qs -p /path/to/aegis-lock
```

With debug logging:

```sh
AEGIS_DEBUG=1 AEGIS_PREVIEW=1 qs -p /path/to/aegis-lock
```

### What to test

- Window appears with dark background and "Press any key to unlock" shield
- Pressing any key or clicking dismisses the shield
- Clock, date, and welcome message appear
- Typing shows password dots in the input field
- Pressing Enter authenticates via PAM (use your real password)
- Successful auth logs "Unlock successful!" and resets the UI for another attempt
- Wrong password shows error banner and clears the input
- If fingerprint hardware is available, the fingerprint indicator appears after
  shield dismissal
- Session buttons (suspend/reboot/shutdown) render at the bottom
- Esc quits the preview

## 2. Nested Compositor (Safe)

Runs a real session lock inside an isolated Wayland session. If something goes
wrong, close the outer compositor window.

### Using cage

```sh
cage -- qs -p /path/to/aegis-lock
```

### Using sway

```sh
WLR_BACKENDS=wayland sway &
# Then in the nested sway terminal:
qs -p /path/to/aegis-lock
```

### What to test

- `WlSessionLock` grabs the session correctly (screen goes to lock UI)
- The lock surface covers the full screen
- Typing password and pressing Enter unlocks the session
- Fingerprint unlock works (if hardware present)

## 3. Real Session Lock (Risky)

Grabs the actual Wayland session lock on your running desktop.

### Before you start

1. **Verify TTY access**: press `Ctrl+Alt+F2` to confirm you can switch to a
   text console. You'll need this as an escape hatch.
2. **Verify PAM configs exist**:
   ```sh
   ls -la ~/.config/aegis-lock/pam/
   # Should contain: fingerprint-only.conf, password-only.conf, other
   ```
   If missing, run preview mode once first — it creates them on startup.
3. **Verify your password works**: test in preview mode first.

### Run

```sh
qs -p /path/to/aegis-lock
```

### Escape hatch

If the lock screen is broken (black screen, crash, unresponsive):

1. Switch to a TTY: `Ctrl+Alt+F2`
2. Log in with your username and password
3. Kill Quickshell: `killall qs`
4. Switch back to your desktop: `Ctrl+Alt+F1`

### What to test

- Lock screen appears immediately covering all monitors
- Shield overlay shows on lock
- Password unlock works
- Fingerprint unlock works
- Session buttons (suspend/reboot/shutdown) function correctly
- After unlock, your desktop session resumes normally

## Environment Variables

| Variable | Effect |
|---|---|
| `AEGIS_PREVIEW=1` | Render in a window instead of session lock |
| `AEGIS_DEBUG=1` | Enable verbose debug logging |
| `AEGIS_CONFIG_DIR=/path/` | Override config directory (default: `~/.config/aegis-lock/`) |
| `AEGIS_PAM_CONFIG=aegis-lock` | Use system PAM config (`/etc/pam.d/aegis-lock`) instead of per-user configs |

## Troubleshooting

### "PAM not available" error

Quickshell was built without PAM support, or PamContext is not available.
Rebuild Quickshell with PAM enabled.

### Fingerprint indicator doesn't appear

Check that fprintd is running and has enrolled fingerprints:

```sh
fprintd-list $USER
```

Expected output includes "found 1 device" and finger entries like "- #0: Right Index Finger".

### Black screen on lock

The lock surface failed to render. Switch to a TTY (`Ctrl+Alt+F2`), kill `qs`,
and check the console output for QML errors. Run in preview mode to debug.

### Password not accepted

Verify PAM configs are correct:

```sh
cat ~/.config/aegis-lock/pam/password-only.conf
# Should contain: auth required pam_unix.so
```

Test PAM directly:

```sh
# Should prompt for password and succeed
pamtester password-only.conf $USER authenticate
```
