import Quickshell
import Quickshell.Wayland
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

  function _refreshServices() {
    Battery.refresh();
    Media.refresh();
    Keyboard.refresh();
  }

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

  // Lock mode: WlSessionLock exists IMMEDIATELY (not gated by Config.ready)
  // so quickshell's onReload() can transfer the lock manager between generations.
  // Only the UI content waits for Config.ready.
  WlSessionLock {
    id: lockSession;
    locked: root.lockMode;

    // Per ext-session-lock-v1, if the client disconnects while a lock is held
    // without first flushing unlock_and_destroy, the compositor MUST keep the
    // session locked — a synchronous Qt.quit() races the wayland write and
    // can leave a stuck black surface only TTY recovery can clear.
    onLockedChanged: {
      if (root.lockMode && !locked) Qt.callLater(Qt.quit);
    }

    WlSessionLockSurface {
      id: lockSurface;

      Component.onCompleted: Log.i("Shell", "Lock surface created for screen:", screen?.name ?? "unknown");
      Component.onDestruction: Log.i("Shell", "Lock surface destroyed for screen:", screen?.name ?? "unknown");

      // Black placeholder while Config loads
      Rectangle {
        anchors.fill: parent;
        color: "black";
        visible: !lockContentLoader.loaded;
      }

      Loader {
        id: lockContentLoader;
        anchors.fill: parent;
        active: Config.ready;
        sourceComponent: Item {
          anchors.fill: parent;

          AuthController {
            id: authController;
            onUnlocked: {
              lockSession.locked = false;
              authController.currentText = "";
              // Quit is handled by lockSession.onLockedChanged after wayland flush.
            }
            onFailed: {
              authController.currentText = "";
            }
          }

          LockContent {
            id: lockContent;
            authController: authController;
            onEscapePressed: {}
          }

          Connections {
            target: lockSession;
            function onLockedChanged() {
              if (lockSession.locked) {
                authController.resetForNewSession();
                lockContent.shield.reset();
                lockContent.passwordInput.text = "";
                lockContent.passwordInput.forceActiveFocus();
                // QML event loop freezes across suspend; cached values can be hours stale.
                root._refreshServices();
              }
            }
          }

          Connections {
            target: lockContent.shield;
            function onDismissed() { root._refreshServices(); }
          }
        }
        onLoaded: Log.i("Shell", "Lock content loaded, Config.ready:", Config.ready);
      }
    }
  }
}
