import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.Core

Item {
  id: root;
  anchors.horizontalCenter: parent.horizontalCenter;
  anchors.bottom: parent.bottom;
  anchors.bottomMargin: parent.height * 0.25;
  width: 360;
  height: panelColumn.implicitHeight;

  required property var authController;
  required property TextInput passwordInput;
  required property bool showFingerprintIndicator;

  FontLoader {
    id: tablerFont;
    source: Qt.resolvedUrl("../Assets/Fonts/noctalia-tabler-icons.ttf");
  }

  // Character reveal model — each char shows briefly before becoming a dot
  ListModel {
    id: charRevealModel;
  }

  Timer {
    id: revealTimer;
    interval: 150;
    onTriggered: {
      // Mask the most recently revealed character
      for (var i = charRevealModel.count - 1; i >= 0; i--) {
        if (!charRevealModel.get(i).masked) {
          charRevealModel.setProperty(i, "masked", true);
          break;
        }
      }
    }
  }

  Connections {
    target: root.authController;
    function onCurrentTextChanged() {
      var text = root.authController.currentText;
      var modelCount = charRevealModel.count;

      if (text.length > modelCount) {
        // Characters added — mask all existing, reveal only the new ones
        for (var i = 0; i < modelCount; i++) {
          charRevealModel.setProperty(i, "masked", true);
        }
        for (var j = modelCount; j < text.length; j++) {
          charRevealModel.append({ "char": text.charAt(j), "masked": false });
        }
        revealTimer.restart();
      } else if (text.length < modelCount) {
        // Characters removed
        while (charRevealModel.count > text.length) {
          charRevealModel.remove(charRevealModel.count - 1);
        }
      }
    }
  }

  readonly property bool isRtl: {
    var t = root.authController.currentText;
    if (!t) return false;
    // Hebrew: U+0590-U+05FF, Arabic: U+0600-U+06FF
    var code = t.charCodeAt(0);
    return (code >= 0x0590 && code <= 0x05FF) || (code >= 0x0600 && code <= 0x06FF);
  }

  ColumnLayout {
    id: panelColumn;
    anchors.fill: parent;
    spacing: Theme.spacingL;

    // Error message
    Rectangle {
      Layout.fillWidth: true;
      Layout.preferredHeight: 44;
      radius: Theme.radiusM;
      color: Qt.alpha(Theme.error, 0.15);
      border.color: Qt.alpha(Theme.error, 0.3);
      border.width: 1;
      visible: root.authController.showFailure && root.authController.errorMessage;

      layer.enabled: visible;
      layer.effect: MultiEffect {
        shadowEnabled: true;
        shadowColor: Qt.alpha("#000000", 0.3);
        shadowVerticalOffset: 2;
        shadowHorizontalOffset: 0;
        shadowBlur: 0.3;
      }
      opacity: visible ? 1.0 : 0.0;

      RowLayout {
        anchors.centerIn: parent;
        spacing: Theme.spacingM;

        Text {
          text: "\uf06a"; // alert icon
          font.pointSize: Theme.fontSizeLarge;
          font.family: "Symbols Nerd Font";
          color: Theme.error;
        }

        Text {
          text: root.authController.errorMessage || L10n.tr("auth.failed");
          font.pointSize: Theme.fontSizeMedium;
          color: Theme.error;
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animNormal;
          easing.type: Easing.OutCubic;
        }
      }
    }

    // Fingerprint indicator
    Rectangle {
      id: fingerprintIndicator;
      Layout.alignment: Qt.AlignHCenter;
      width: 50;
      height: 50;
      radius: width / 2;
      color: showingError ? Qt.alpha("#F44336", 0.25) : Theme.indicatorBackground;
      border.color: showingError ? "#F44336" : Qt.alpha(Theme.primary, 0.3);
      border.width: showingError ? 2 : 1;
      visible: root.showFingerprintIndicator;
      opacity: visible ? 1.0 : 0.0;

      layer.enabled: visible;
      layer.effect: MultiEffect {
        shadowEnabled: true;
        shadowColor: Qt.alpha("#000000", 0.4);
        shadowVerticalOffset: 2;
        shadowHorizontalOffset: 0;
        shadowBlur: 0.4;
      }

      property bool showingError: false;
      property real shakeOffset: 0;

      transform: Translate { x: fingerprintIndicator.shakeOffset; }

      Text {
        anchors.centerIn: parent;
        text: "\uebd1"; // fingerprint icon (tabler)
        font.pointSize: Theme.fontSizeXXL;
        font.family: tablerFont.name;
        color: fingerprintIndicator.showingError ? "#F44336" : Theme.primary;

        Behavior on color {
          ColorAnimation { duration: 150; }
        }
      }

      SequentialAnimation {
        id: shakeAnimation;
        PropertyAnimation { target: fingerprintIndicator; property: "shakeOffset"; to: -10; duration: 50; }
        PropertyAnimation { target: fingerprintIndicator; property: "shakeOffset"; to: 10; duration: 50; }
        PropertyAnimation { target: fingerprintIndicator; property: "shakeOffset"; to: -5; duration: 50; }
        PropertyAnimation { target: fingerprintIndicator; property: "shakeOffset"; to: 0; duration: 50; }
      }

      Connections {
        target: root.authController;
        function onFingerprintFailed() {
          Log.i("PasswordPanel", "Fingerprint failed — showing error animation");
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
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic; }
      }
    }

    // Info message
    Rectangle {
      Layout.fillWidth: true;
      Layout.preferredHeight: 44;
      radius: Theme.radiusM;
      color: Theme.indicatorBackground;
      visible: root.authController.showInfo && root.authController.infoMessage;
      opacity: visible ? 1.0 : 0.0;

      Text {
        anchors.centerIn: parent;
        text: root.authController.infoMessage;
        font.pointSize: Theme.fontSizeMedium;
        color: Theme.surfaceVariantForeground;
      }

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animNormal;
          easing.type: Easing.OutCubic;
        }
      }
    }

    // Password input row
    Rectangle {
      id: inputRect;
      Layout.fillWidth: true;
      Layout.preferredHeight: 52;
      radius: Theme.radiusL;
      color: Theme.inputBackground;

      layer.enabled: true;
      layer.effect: MultiEffect {
        shadowEnabled: true;
        shadowColor: Qt.alpha("#000000", 0.4);
        shadowVerticalOffset: 2;
        shadowHorizontalOffset: 0;
        shadowBlur: 0.4;
      }
      border.color: root.authController.unlockInProgress
        ? Theme.primary
        : (root.passwordInput.activeFocus ? Theme.inputBorderFocused : Theme.inputBorder);
      border.width: root.passwordInput.activeFocus || root.authController.unlockInProgress ? Theme.borderMedium : Theme.borderThin;

      property real shakeOffset: 0;
      transform: Translate { x: inputRect.shakeOffset; }

      scale: root.authController.unlockInProgress ? 0.98 : 1.0;
      Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic; } }

      // Shake on auth failure
      SequentialAnimation {
        id: inputShakeAnimation;
        PropertyAnimation { target: inputRect; property: "shakeOffset"; to: -8; duration: 50; }
        PropertyAnimation { target: inputRect; property: "shakeOffset"; to: 8; duration: 50; }
        PropertyAnimation { target: inputRect; property: "shakeOffset"; to: -4; duration: 50; }
        PropertyAnimation { target: inputRect; property: "shakeOffset"; to: 0; duration: 50; }
      }

      // Brief scale bump on failure
      SequentialAnimation {
        id: inputFailScaleAnimation;
        PropertyAnimation { target: inputRect; property: "scale"; to: 1.03; duration: 100; easing.type: Easing.OutCubic; }
        PropertyAnimation { target: inputRect; property: "scale"; to: 1.0; duration: 200; easing.type: Easing.OutCubic; }
      }

      Connections {
        target: root.authController;
        function onFailed() {
          inputShakeAnimation.start();
          inputFailScaleAnimation.start();
        }
      }

      // Pulsing border during auth
      SequentialAnimation on border.color {
        running: root.authController.unlockInProgress;
        loops: Animation.Infinite;
        ColorAnimation { to: Qt.alpha(Theme.primary, 0.3); duration: 600; easing.type: Easing.InOutSine; }
        ColorAnimation { to: Theme.primary; duration: 600; easing.type: Easing.InOutSine; }
        onRunningChanged: { if (!running) inputRect.border.color = Qt.binding(function() {
          return root.passwordInput.activeFocus ? Theme.inputBorderFocused : Theme.inputBorder;
        }); }
      }

      Behavior on border.color {
        ColorAnimation {
          duration: Theme.animFast;
        }
      }

      MouseArea {
        anchors.fill: parent;
        onClicked: root.passwordInput.forceActiveFocus();
      }

      RowLayout {
        anchors.fill: parent;
        anchors.leftMargin: Theme.spacingL;
        anchors.rightMargin: Theme.spacingM;
        spacing: Theme.spacingM;

        // Lock icon
        Text {
          Layout.alignment: Qt.AlignVCenter;
          text: "\uf512";
          font.pointSize: Theme.fontSizeLarge;
          font.family: "Symbols Nerd Font";
          color: Theme.surfaceVariantForeground;
        }

        // Password display
        Item {
          Layout.fillWidth: true;
          Layout.fillHeight: true;

          // Placeholder text
          Text {
            anchors.verticalCenter: parent.verticalCenter;
            anchors.left: root.isRtl ? undefined : parent.left;
            anchors.right: root.isRtl ? parent.right : undefined;
            text: L10n.tr("password.placeholder");
            font.pointSize: Theme.fontSizeMedium;
            horizontalAlignment: root.isRtl ? Text.AlignRight : Text.AlignLeft;
            color: Qt.alpha(Theme.surfaceVariantForeground, 0.5);
            visible: root.authController.currentText === "";
          }

          // Password display with character reveal
          Row {
            anchors.verticalCenter: parent.verticalCenter;
            anchors.left: root.isRtl ? undefined : parent.left;
            anchors.right: root.isRtl ? parent.right : undefined;
            layoutDirection: root.isRtl ? Qt.RightToLeft : Qt.LeftToRight;
            spacing: 4;
            visible: root.authController.currentText !== "" && !showPasswordToggle.checked;
            clip: true;
            width: Math.min(implicitWidth, parent.width);

            Repeater {
              model: charRevealModel;

              Item {
                width: model.masked ? 8 : charLabel.implicitWidth;
                height: 20;
                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic; } }

                // Dot (shown when masked)
                Rectangle {
                  anchors.centerIn: parent;
                  width: 8; height: 8; radius: 4;
                  color: Theme.surfaceForeground;
                  visible: model.masked;
                }

                // Character (shown briefly before masking)
                Text {
                  id: charLabel;
                  anchors.centerIn: parent;
                  text: model.char;
                  font.pointSize: Theme.fontSizeMedium;
                  color: Theme.surfaceForeground;
                  visible: !model.masked;
                }
              }
            }
          }

          // Clear text display (when toggled visible)
          Text {
            anchors.verticalCenter: parent.verticalCenter;
            text: root.authController.currentText;
            font.pointSize: Theme.fontSizeMedium;
            horizontalAlignment: root.isRtl ? Text.AlignRight : Text.AlignLeft;
            color: Theme.surfaceForeground;
            visible: root.authController.currentText !== "" && showPasswordToggle.checked;
            elide: Text.ElideRight;
            width: parent.width;
          }
        }

        // Show/hide password toggle
        Rectangle {
          id: showPasswordToggle;
          Layout.alignment: Qt.AlignVCenter;
          width: 36;
          height: 36;
          radius: width / 2;
          color: toggleMouse.containsMouse ? Qt.alpha(Theme.primary, 0.1) : "transparent";
          property bool checked: false;

          Text {
            anchors.centerIn: parent;
            text: showPasswordToggle.checked ? "\uf06e" : "\uf070"; // eye / eye-off
            font.pointSize: Theme.fontSizeLarge;
            font.family: "Symbols Nerd Font";
            color: Theme.surfaceVariantForeground;
          }

          MouseArea {
            id: toggleMouse;
            anchors.fill: parent;
            hoverEnabled: true;
            cursorShape: Qt.PointingHandCursor;
            onClicked: showPasswordToggle.checked = !showPasswordToggle.checked;
          }
        }

        // Submit button / spinner
        Rectangle {
          Layout.alignment: Qt.AlignVCenter;
          width: 40;
          height: 40;
          radius: width / 2;
          color: root.authController.unlockInProgress
            ? Qt.alpha(Theme.primary, 0.6)
            : (submitMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.primary, 0.8));

          // Arrow icon (hidden during unlock)
          Text {
            anchors.centerIn: parent;
            text: "\uf061"; // arrow right
            font.pointSize: Theme.fontSizeLarge;
            font.family: "Symbols Nerd Font";
            color: Theme.primaryForeground;
            visible: !root.authController.unlockInProgress;
          }

          // Arc spinner (visible during unlock)
          Canvas {
            id: spinner;
            anchors.centerIn: parent;
            width: 24; height: 24;
            visible: root.authController.unlockInProgress;

            property real angle: 0;

            onAngleChanged: requestPaint();
            onVisibleChanged: if (!visible) angle = 0;

            NumberAnimation on angle {
              running: spinner.visible;
              from: 0; to: 360;
              duration: 800;
              loops: Animation.Infinite;
            }

            onPaint: {
              var ctx = getContext("2d");
              ctx.reset();
              var cx = width / 2, cy = height / 2, r = 9;
              var startRad = angle * Math.PI / 180;
              var arcLen = 1.8; // ~100 degree arc
              ctx.beginPath();
              ctx.arc(cx, cy, r, startRad, startRad + arcLen);
              ctx.strokeStyle = Theme.primaryForeground;
              ctx.lineWidth = 2.5;
              ctx.lineCap = "round";
              ctx.stroke();
            }
          }

          MouseArea {
            id: submitMouse;
            anchors.fill: parent;
            hoverEnabled: true;
            cursorShape: Qt.PointingHandCursor;
            enabled: !root.authController.unlockInProgress;
            onClicked: root.authController.tryUnlock(true);
          }
        }
      }
    }
  }
}
