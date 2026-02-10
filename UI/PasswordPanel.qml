import QtQuick
import QtQuick.Layouts
import qs.Core

Item {
  id: root;
  anchors.horizontalCenter: parent.horizontalCenter;
  anchors.bottom: parent.bottom;
  anchors.bottomMargin: 200;
  width: 360;
  height: panelColumn.implicitHeight;

  required property var authController;
  required property TextInput passwordInput;

  ColumnLayout {
    id: panelColumn;
    anchors.fill: parent;
    spacing: Theme.spacingL;

    // Error message
    Rectangle {
      Layout.fillWidth: true;
      Layout.preferredHeight: 44;
      radius: Theme.radiusM;
      color: Theme.error;
      visible: root.authController.showFailure && root.authController.errorMessage;
      opacity: visible ? 1.0 : 0.0;

      RowLayout {
        anchors.centerIn: parent;
        spacing: Theme.spacingM;

        Text {
          text: "\uf06a"; // alert icon
          font.pointSize: Theme.fontSizeLarge;
          font.family: "Symbols Nerd Font";
          color: Theme.errorForeground;
        }

        Text {
          text: root.authController.errorMessage || L10n.tr("auth.failed");
          font.pointSize: Theme.fontSizeMedium;
          color: Theme.errorForeground;
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: Theme.animNormal;
          easing.type: Easing.OutCubic;
        }
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
      Layout.fillWidth: true;
      Layout.preferredHeight: 52;
      radius: Theme.radiusL;
      color: Theme.inputBackground;
      border.color: root.passwordInput.activeFocus ? Theme.inputBorderFocused : Theme.inputBorder;
      border.width: root.passwordInput.activeFocus ? Theme.borderMedium : Theme.borderThin;

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
            text: L10n.tr("password.placeholder");
            font.pointSize: Theme.fontSizeMedium;
            color: Qt.alpha(Theme.surfaceVariantForeground, 0.5);
            visible: root.authController.currentText === "";
          }

          // Dot display for password
          Row {
            anchors.verticalCenter: parent.verticalCenter;
            spacing: 4;
            visible: root.authController.currentText !== "" && !showPasswordToggle.checked;

            Repeater {
              model: Math.min(root.authController.currentText.length, 30);
              Rectangle {
                width: 8;
                height: 8;
                radius: 4;
                color: Theme.surfaceForeground;
              }
            }
          }

          // Clear text display (when toggled visible)
          Text {
            anchors.verticalCenter: parent.verticalCenter;
            text: root.authController.currentText;
            font.pointSize: Theme.fontSizeMedium;
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

        // Submit button
        Rectangle {
          Layout.alignment: Qt.AlignVCenter;
          width: 40;
          height: 40;
          radius: width / 2;
          color: submitMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.primary, 0.8);
          opacity: root.authController.unlockInProgress ? 0.5 : 1.0;

          Text {
            anchors.centerIn: parent;
            text: "\uf061"; // arrow right
            font.pointSize: Theme.fontSizeLarge;
            font.family: "Symbols Nerd Font";
            color: Theme.primaryForeground;
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
