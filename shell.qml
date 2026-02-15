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

  // Shared auth controller for all lock surfaces — lives outside the per-screen
  // Variants so all monitors share the same PAM session and unlock state.
  AuthController {
    id: authController;
    onUnlocked: {
      lockSession.locked = false;
      authController.currentText = "";
    }
    onFailed: {
      if (authController.usePasswordOnly || !authController.fingerprintMode) {
        authController.currentText = "";
      }
    }
  }

  // Lock mode: WlSessionLock exists IMMEDIATELY (not gated by Config.ready)
  // so quickshell's onReload() can transfer the lock manager between generations.
  // Only the UI content waits for Config.ready.
  WlSessionLock {
    id: lockSession;
    locked: root.lockMode;

    // One lock surface per screen so every monitor shows the lock UI
    Variants {
      model: Quickshell.screens;

      delegate: Component {
        WlSessionLockSurface {
          required property ShellScreen modelData;
          screen: modelData;

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
                  }
                }
              }
            }
            onLoaded: Log.i("Shell", "Lock surface loaded for screen:", modelData.name);
          }
        }
      }
    }
  }
}
