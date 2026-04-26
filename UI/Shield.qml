import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.Core
import qs.Auth

Item {
  id: root;
  anchors.fill: parent;

  required property var authController;

  readonly property bool shieldActive: internal.shieldActive;
  readonly property bool showingFingerprintIndicator: !internal.shieldActive && fpShowTimer.shouldShow;

  signal dismissed;

  function dismissShield() {
    if (!internal.shieldActive) return;
    internal.shieldActive = false;
    root.dismissed();
  }

  function reset() {
    internal.shieldActive = true;
    fpShowTimer.shouldShow = false;
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
    visible: opacity > 0;
    opacity: internal.shieldActive ? 1.0 : 0.0;
    z: 100;

    Rectangle {
      id: shieldPill;
      anchors.centerIn: parent;
      width: shieldContent.width + Theme.spacingXL * 2;
      height: shieldContent.height + Theme.spacingL * 2;
      radius: Theme.radiusL;
      color: Theme.shieldBackground;

      layer.enabled: true;
      layer.effect: MultiEffect {
        shadowEnabled: true;
        shadowColor: Qt.alpha("#000000", 0.5);
        shadowVerticalOffset: 3;
        shadowHorizontalOffset: 0;
        shadowBlur: 0.5;
      }
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

  // Delay showing fingerprint indicator after shield dismissed
  Timer {
    id: fpShowTimer;
    interval: 500;
    running: !internal.shieldActive && FingerprintDetector.available;
    property bool shouldShow: false;
    onTriggered: shouldShow = true;
  }
}
