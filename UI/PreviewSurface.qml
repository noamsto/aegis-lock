import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Auth

// Preview mode: renders lock UI in a regular floating window instead of WlSessionLock.
// Run with: AEGIS_PREVIEW=1 qs -p /path/to/aegis-lock
// Auth still works (PAM) — you can test password/fingerprint login.
// Close the window or Ctrl+C to exit.
FloatingWindow {
  id: previewWindow;
  title: "Aegis Lock — Preview";
  implicitWidth: 1280;
  implicitHeight: 720;
  visible: true;

  color: "transparent";

  AuthController {
    id: authController;
    onUnlocked: {
      Log.i("Preview", "Unlock successful! (preview mode — not actually locked)");
      authController.currentText = "";
      // In preview mode, reset so you can test again
      Qt.callLater(function () {
        authController.resetForNewSession();
        lockContent.shield.reset();
      });
    }
    onFailed: {
      if (authController.usePasswordOnly || !authController.fingerprintMode) {
        authController.currentText = "";
      }
    }
  }

  contentItem.children: [
    LockContent {
      id: lockContent;
      authController: authController;
      onEscapePressed: Qt.quit();
    },

    // Preview mode label
    Rectangle {
      anchors.top: parent.top;
      anchors.left: parent.left;
      anchors.topMargin: Theme.spacingM;
      anchors.leftMargin: Theme.spacingM;
      width: previewLabel.implicitWidth + Theme.spacingL;
      height: previewLabel.implicitHeight + Theme.spacingM;
      radius: Theme.radiusS;
      color: Qt.alpha(Theme.primary, 0.3);

      Text {
        id: previewLabel;
        anchors.centerIn: parent;
        text: "PREVIEW MODE — Esc to quit";
        font.pointSize: Theme.fontSizeSmall;
        color: Theme.surfaceForeground;
      }
    }
  ]
}
