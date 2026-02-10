import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Auth
import qs.Services

// Shared lock screen UI content used by both LockSurface and PreviewSurface.
Item {
  id: root;
  anchors.fill: parent;
  focus: true;

  required property var authController;

  // Exposed for parent to call reset/dismiss
  property alias shield: shield;
  property alias passwordInput: passwordInput;

  // Emitted when Escape is pressed (preview mode uses this to quit)
  signal escapePressed;

  // Key handler — forward to shield first
  Keys.onPressed: function (event) {
    if (event.key === Qt.Key_Escape) {
      root.escapePressed();
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
    authController: root.authController;
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
    authController: root.authController;
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
        color: Battery.charging ? Theme.primary
          : Battery.percentage <= 10 ? Theme.error
          : Qt.alpha(Theme.surfaceForeground, 0.6);
      }

      Text {
        text: Battery.percentage + "%";
        font.pointSize: Theme.fontSizeSmall;
        color: Battery.charging ? Theme.primary : Qt.alpha(Theme.surfaceForeground, 0.6);
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
    Rectangle {
      width: 32; height: 32; radius: 16;
      color: prevMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.1) : "transparent";
      Behavior on color { ColorAnimation { duration: 100; } }
      Text {
        anchors.centerIn: parent;
        text: "\uf04a";
        font.pointSize: Theme.fontSizeMedium;
        font.family: "Symbols Nerd Font";
        color: prevMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.8) : Qt.alpha(Theme.surfaceForeground, 0.5);
      }
      MouseArea {
        id: prevMouse;
        anchors.fill: parent;
        hoverEnabled: true;
        cursorShape: Qt.PointingHandCursor;
        onClicked: Media.previous();
      }
    }

    // Play/Pause
    Rectangle {
      width: 36; height: 36; radius: 18;
      color: ppMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.1) : "transparent";
      Behavior on color { ColorAnimation { duration: 100; } }
      Text {
        anchors.centerIn: parent;
        text: Media.playing ? "\uf04c" : "\uf04b";
        font.pointSize: Theme.fontSizeLarge;
        font.family: "Symbols Nerd Font";
        color: ppMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.8) : Qt.alpha(Theme.surfaceForeground, 0.5);
      }
      MouseArea {
        id: ppMouse;
        anchors.fill: parent;
        hoverEnabled: true;
        cursorShape: Qt.PointingHandCursor;
        onClicked: Media.playPause();
      }
    }

    // Next
    Rectangle {
      width: 32; height: 32; radius: 16;
      color: nextMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.1) : "transparent";
      Behavior on color { ColorAnimation { duration: 100; } }
      Text {
        anchors.centerIn: parent;
        text: "\uf04e";
        font.pointSize: Theme.fontSizeMedium;
        font.family: "Symbols Nerd Font";
        color: nextMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.8) : Qt.alpha(Theme.surfaceForeground, 0.5);
      }
      MouseArea {
        id: nextMouse;
        anchors.fill: parent;
        hoverEnabled: true;
        cursorShape: Qt.PointingHandCursor;
        onClicked: Media.next();
      }
    }

    // Track info (marquee scroll when text overflows)
    Item {
      id: trackContainer;
      Layout.maximumWidth: 300;
      Layout.preferredWidth: Math.min(trackText.implicitWidth, 300);
      implicitHeight: trackText.implicitHeight;
      clip: true;

      property bool overflow: trackText.implicitWidth > trackContainer.width;

      Text {
        id: trackText;
        y: 0;
        text: {
          var parts = [];
          if (Media.artist) parts.push(Media.artist);
          if (Media.title) parts.push(Media.title);
          return parts.join(" — ");
        }
        font.pointSize: Theme.fontSizeSmall;
        color: Qt.alpha(Theme.surfaceForeground, 0.5);

        SequentialAnimation on x {
          running: trackContainer.overflow && Media.available;
          loops: Animation.Infinite;
          // Pause at start position
          PauseAnimation { duration: 2000; }
          // Scroll left to reveal hidden text
          NumberAnimation {
            to: -(trackText.implicitWidth - trackContainer.width);
            duration: Math.max((trackText.implicitWidth - trackContainer.width) * 30, 1000);
            easing.type: Easing.Linear;
          }
          // Pause at end
          PauseAnimation { duration: 2000; }
          // Scroll back
          NumberAnimation {
            to: 0;
            duration: Math.max((trackText.implicitWidth - trackContainer.width) * 30, 1000);
            easing.type: Easing.Linear;
          }
        }
      }

      // Reset scroll position when track changes
      Connections {
        target: Media;
        function onTitleChanged() { trackText.x = 0; }
        function onArtistChanged() { trackText.x = 0; }
      }
    }
  }
}
