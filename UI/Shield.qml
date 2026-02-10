import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Auth

Item {
  id: root;
  anchors.fill: parent;

  required property var authController;

  FontLoader {
    id: tablerFont;
    source: Qt.resolvedUrl("../Assets/Fonts/noctalia-tabler-icons.ttf");
  }

  readonly property bool shieldActive: internal.shieldActive;
  readonly property bool showingFingerprintIndicator: fingerprintIndicator.visible;

  function dismissShield() {
    if (!internal.shieldActive) return;
    internal.shieldActive = false;
  }

  function reset() {
    internal.shieldActive = true;
    fpShowTimer.shouldShow = false;
    fingerprintIndicator.showingError = false;
  }

  function handleKeyPress(event) {
    if (internal.shieldActive) {
      dismissShield();
      return true;
    }
    return false;
  }

  function handleClick() {
    if (internal.shieldActive) {
      dismissShield();
      return true;
    }
    return false;
  }

  QtObject {
    id: internal;
    property bool shieldActive: true;
  }

  // Shield overlay — "Press any key to unlock"
  Rectangle {
    id: shieldOverlay;
    anchors.fill: parent;
    color: "transparent";
    visible: internal.shieldActive;
    z: 100;

    Rectangle {
      anchors.centerIn: parent;
      width: shieldContent.width + Theme.spacingXL * 2;
      height: shieldContent.height + Theme.spacingL * 2;
      radius: Theme.radiusL;
      color: Theme.shieldBackground;
    }

    RowLayout {
      id: shieldContent;
      anchors.centerIn: parent;
      spacing: Theme.spacingM;

      Text {
        Layout.alignment: Qt.AlignVCenter;
        text: "\uf512"; // lock icon (nerd font)
        font.pointSize: Theme.fontSizeLarge;
        font.family: "Symbols Nerd Font";
        color: Theme.surfaceVariantForeground;
      }

      Text {
        Layout.alignment: Qt.AlignVCenter;
        text: L10n.tr("shield.press-to-unlock");
        font.pointSize: Theme.fontSizeMedium;
        color: Theme.surfaceVariantForeground;
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.animNormal;
        easing.type: Easing.OutCubic;
      }
    }
  }

  // Fingerprint status indicator
  Rectangle {
    id: fingerprintIndicator;
    width: 50;
    height: 50;
    anchors.horizontalCenter: parent.horizontalCenter;
    anchors.bottom: parent.bottom;
    anchors.bottomMargin: 420;
    radius: width / 2;
    color: showingError ? Qt.alpha("#F44336", 0.25) : Theme.indicatorBackground;
    border.color: showingError ? "#F44336" : Qt.alpha(Theme.primary, 0.3);
    border.width: showingError ? 2 : 1;
    visible: !internal.shieldActive && fpShowTimer.shouldShow;
    opacity: visible ? 1.0 : 0.0;

    property bool showingError: false;

    Text {
      anchors.centerIn: parent;
      text: "\uebd1"; // fingerprint icon (tabler)
      font.pointSize: Theme.fontSizeXXL;
      font.family: tablerFont.name;
      color: fingerprintIndicator.showingError ? "#F44336" : Theme.primary;

      Behavior on color {
        ColorAnimation {
          duration: 150;
        }
      }
    }

    // Shake animation on error
    SequentialAnimation {
      id: shakeAnimation;
      PropertyAnimation {
        target: fingerprintIndicator;
        property: "anchors.horizontalCenterOffset";
        to: -10;
        duration: 50;
      }
      PropertyAnimation {
        target: fingerprintIndicator;
        property: "anchors.horizontalCenterOffset";
        to: 10;
        duration: 50;
      }
      PropertyAnimation {
        target: fingerprintIndicator;
        property: "anchors.horizontalCenterOffset";
        to: -5;
        duration: 50;
      }
      PropertyAnimation {
        target: fingerprintIndicator;
        property: "anchors.horizontalCenterOffset";
        to: 0;
        duration: 50;
      }
    }

    // Delay showing indicator after shield dismissed
    Timer {
      id: fpShowTimer;
      interval: 500;
      running: !internal.shieldActive && FingerprintDetector.available;
      property bool shouldShow: false;
      onTriggered: shouldShow = true;
    }

    // Listen for fingerprint errors
    Connections {
      target: root.authController;
      function onFingerprintFailed() {
        Log.i("Shield", "Fingerprint failed — showing error animation");
        fingerprintIndicator.showingError = true;
        shakeAnimation.start();
        errorResetTimer.start();
      }
    }

    Timer {
      id: errorResetTimer;
      interval: 1500;
      onTriggered: fingerprintIndicator.showingError = false;
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.animNormal;
        easing.type: Easing.OutCubic;
      }
    }
  }
}
