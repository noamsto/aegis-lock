import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Auth
import qs.Services

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

      Item {
        anchors.fill: parent;
        focus: true;

        // Key handler — forward to shield first
        Keys.onPressed: function (event) {
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

        // Mouse area for focus and shield dismissal
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

        // Hidden text input for keyboard capture
        // NOTE: No declarative binding on text — we sync imperatively via Connections
        // to avoid two-way binding loops (binding breaks after first keystroke)
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

        // Sync authController.currentText -> passwordInput.text (e.g., after auth failure clears text)
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

        // Status indicators (top-right corner)
        RowLayout {
          anchors.top: parent.top;
          anchors.right: parent.right;
          anchors.topMargin: Theme.spacingL;
          anchors.rightMargin: Theme.spacingXL;
          spacing: Theme.spacingL;
          visible: !shield.shieldActive;

          // Keyboard layout
          Text {
            text: Keyboard.layoutShort;
            font.pointSize: Theme.fontSizeSmall;
            color: Qt.alpha(Theme.surfaceForeground, 0.6);
            visible: Keyboard.available && Keyboard.layoutShort !== "";
          }

          // Battery indicator
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

        // Media controls (bottom-left corner)
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
            color: lockPrevMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.8) : Qt.alpha(Theme.surfaceForeground, 0.5);
            MouseArea {
              id: lockPrevMouse;
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
            color: lockPpMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.8) : Qt.alpha(Theme.surfaceForeground, 0.5);
            MouseArea {
              id: lockPpMouse;
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
            color: lockNextMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.8) : Qt.alpha(Theme.surfaceForeground, 0.5);
            MouseArea {
              id: lockNextMouse;
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
      }

      // Reset state when lock session activates
      Connections {
        target: lockSession;
        function onLockedChanged() {
          if (lockSession.locked) {
            authController.resetForNewSession();
            shield.reset();
            passwordInput.text = "";
            passwordInput.forceActiveFocus();
          }
        }
      }
    }
  }

}
