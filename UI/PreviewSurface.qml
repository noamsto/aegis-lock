import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Auth
import qs.Services

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
        shield.reset();
      });
    }
    onFailed: {
      if (authController.usePasswordOnly || !authController.fingerprintMode) {
        authController.currentText = "";
      }
    }
  }

  contentItem.children: [
    Item {
      anchors.fill: parent;
      focus: true;

      Keys.onPressed: function (event) {
        // Escape to quit preview
        if (event.key === Qt.Key_Escape) {
          Qt.quit();
          event.accepted = true;
          return;
        }

        var wasShieldActive = shield.shieldActive;
        if (shield.handleKeyPress(event)) {
          if (wasShieldActive && FingerprintDetector.available) {
            authController.startFingerprintAuth();
          }
          event.accepted = true;
          return;
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          authController.tryUnlock(true);
          event.accepted = true;
        }
      }

      Background {}

      MouseArea {
        anchors.fill: parent;
        hoverEnabled: true;
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton;
        onPositionChanged: passwordInput.forceActiveFocus();
        onClicked: {
          var wasShieldActive = shield.shieldActive;
          if (shield.handleClick()) {
            if (wasShieldActive && FingerprintDetector.available) {
              authController.startFingerprintAuth();
            }
          } else {
            passwordInput.forceActiveFocus();
          }
        }
      }

      Shield {
        id: shield;
        authController: authController;
      }

      Header {
        visible: !shield.shieldActive;
      }

      TextInput {
        id: passwordInput;
        visible: false;
        echoMode: TextInput.Password;
        onTextChanged: {
          authController.currentText = text;
          if (shield.shieldActive && text.length > 0) {
            shield.dismissShield();
            if (FingerprintDetector.available) {
              authController.startFingerprintAuth();
            }
          }
        }
        enabled: true;
        Component.onCompleted: forceActiveFocus();
      }

      Connections {
        target: authController;
        function onCurrentTextChanged() {
          if (passwordInput.text !== authController.currentText) {
            passwordInput.text = authController.currentText;
          }
        }
      }

      PasswordPanel {
        authController: authController;
        passwordInput: passwordInput;
        visible: !shield.shieldActive;
      }

      SessionControls {
        visible: (!shield.shieldActive) && (Config.data.general ? Config.data.general.showSessionButtons !== false : true);
      }

      // Status indicators
      RowLayout {
        anchors.top: parent.top;
        anchors.right: parent.right;
        anchors.topMargin: Theme.spacingL;
        anchors.rightMargin: Theme.spacingXL;
        spacing: Theme.spacingL;
        visible: !shield.shieldActive;

        Text {
          text: Keyboard.layoutShort;
          font.pointSize: Theme.fontSizeSmall;
          color: Qt.alpha(Theme.surfaceForeground, 0.6);
          visible: Keyboard.available && Keyboard.layoutShort !== "";
        }

        RowLayout {
          spacing: Theme.spacingS;
          visible: Battery.available;

          Text {
            text: Battery.icon;
            font.pointSize: Theme.fontSizeSmall;
            font.family: "Symbols Nerd Font";
            color: Battery.percentage <= 10 ? Theme.error : Qt.alpha(Theme.surfaceForeground, 0.6);
          }

          Text {
            text: Battery.percentage + "%";
            font.pointSize: Theme.fontSizeSmall;
            color: Qt.alpha(Theme.surfaceForeground, 0.6);
          }
        }
      }

      // Media controls
      RowLayout {
        anchors.bottom: parent.bottom;
        anchors.left: parent.left;
        anchors.bottomMargin: Theme.spacingXL;
        anchors.leftMargin: Theme.spacingXL;
        spacing: Theme.spacingM;
        visible: !shield.shieldActive && Media.available;

        // Previous
        Text {
          text: "\uf04a"; // step-backward
          font.pointSize: Theme.fontSizeMedium;
          font.family: "Symbols Nerd Font";
          color: prevMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.8) : Qt.alpha(Theme.surfaceForeground, 0.5);
          MouseArea {
            id: prevMouse;
            anchors.fill: parent;
            anchors.margins: -4;
            hoverEnabled: true;
            cursorShape: Qt.PointingHandCursor;
            onClicked: Media.previous();
          }
        }

        // Play/Pause
        Text {
          text: Media.playing ? "\uf04c" : "\uf04b"; // pause / play
          font.pointSize: Theme.fontSizeLarge;
          font.family: "Symbols Nerd Font";
          color: ppMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.8) : Qt.alpha(Theme.surfaceForeground, 0.5);
          MouseArea {
            id: ppMouse;
            anchors.fill: parent;
            anchors.margins: -4;
            hoverEnabled: true;
            cursorShape: Qt.PointingHandCursor;
            onClicked: Media.playPause();
          }
        }

        // Next
        Text {
          text: "\uf04e"; // step-forward
          font.pointSize: Theme.fontSizeMedium;
          font.family: "Symbols Nerd Font";
          color: nextMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.8) : Qt.alpha(Theme.surfaceForeground, 0.5);
          MouseArea {
            id: nextMouse;
            anchors.fill: parent;
            anchors.margins: -4;
            hoverEnabled: true;
            cursorShape: Qt.PointingHandCursor;
            onClicked: Media.next();
          }
        }

        // Track info
        Text {
          text: {
            var parts = [];
            if (Media.artist) parts.push(Media.artist);
            if (Media.title) parts.push(Media.title);
            return parts.join(" — ");
          }
          font.pointSize: Theme.fontSizeSmall;
          color: Qt.alpha(Theme.surfaceForeground, 0.5);
          elide: Text.ElideRight;
          Layout.maximumWidth: 300;
        }
      }

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
    }
  ]
}
