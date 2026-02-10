import Quickshell
import QtQuick
import qs.Core
import qs.Auth
import qs.UI
import qs.Services

ShellRoot {
  id: root;

  // Lock mode requires explicit opt-in to prevent accidental session locks
  // (e.g., a running Quickshell instance picking up this shell.qml via direnv)
  readonly property bool lockMode: Quickshell.env("AEGIS_LOCK") === "1";
  readonly property bool previewMode: !lockMode;

  Component.onCompleted: {
    Log.i("Shell", "Aegis Lock starting...", previewMode ? "(preview mode)" : "(lock mode)");
    Config.init();
    Theme.init();
    L10n.init();
    PamConfigs.init();
    FingerprintDetector.init();
    Battery.init();
    Keyboard.init();
    Media.init();
    Log.i("Shell", "Initialization complete");
  }

  // Preview mode: regular window (safe for development)
  Loader {
    active: Config.ready && root.previewMode;
    sourceComponent: PreviewSurface {}
    onLoaded: Log.i("Shell", "Preview surface loaded");
  }

  // Lock mode: real session lock
  Loader {
    active: Config.ready && !root.previewMode;
    sourceComponent: LockSurface {
      lockRequested: true;
    }
    onLoaded: Log.i("Shell", "Lock surface loaded");
  }
}
