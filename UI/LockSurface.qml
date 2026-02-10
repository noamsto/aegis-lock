import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Auth

Item {
  id: root;

  property bool lockRequested: false;

  WlSessionLock {
    id: lockSession;
    locked: root.lockRequested;

    WlSessionLockSurface {
      id: lockSurface;

      AuthController {
        id: authController;
        onUnlocked: {
          lockSession.locked = false;
          root.lockRequested = false;
          authController.currentText = "";
        }
        onFailed: {
          if (authController.usePasswordOnly || !authController.fingerprintMode) {
            authController.currentText = "";
          }
        }
      }

      LockContent {
        id: lockContent;
        authController: authController;
        // Escape does nothing in real lock mode
        onEscapePressed: {}
      }

      // Reset state when lock session activates
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
  }
}
