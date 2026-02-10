import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core

Item {
  id: root;
  anchors.horizontalCenter: parent.horizontalCenter;
  anchors.bottom: parent.bottom;
  anchors.bottomMargin: parent.height * 0.15;
  width: buttonRow.implicitWidth;
  height: buttonRow.implicitHeight;

  property bool timerActive: countdownTimer.running;
  property string pendingAction: "";
  property real timeRemaining: 0;

  function cancelTimer() {
    countdownTimer.stop();
    pendingAction = "";
    timeRemaining = 0;
  }

  function _startAction(action) {
    var countdownEnabled = Config.data.general ? Config.data.general.countdownEnabled !== false : true;
    var duration = Config.data.general ? Config.data.general.countdownDuration || 10000 : 10000;

    // If countdown disabled or same action pressed again, execute immediately
    if (!countdownEnabled || (timerActive && pendingAction === action)) {
      _execute(action);
      return;
    }

    // If different action while timer running, switch
    if (timerActive && pendingAction !== action) {
      cancelTimer();
    }

    pendingAction = action;
    timeRemaining = duration;
    countdownTimer.start();
  }

  function _execute(action) {
    cancelTimer();
    var cmd;
    switch (action) {
    case "suspend":
      cmd = ["systemctl", "suspend"];
      break;
    case "reboot":
      cmd = ["systemctl", "reboot"];
      break;
    case "shutdown":
      cmd = ["systemctl", "poweroff"];
      break;
    case "logout":
      cmd = ["loginctl", "terminate-session", Quickshell.env("XDG_SESSION_ID") || "self"];
      break;
    default:
      return;
    }
    Log.i("Session", "Executing:", action);
    actionProc.command = cmd;
    actionProc.running = true;
  }

  Timer {
    id: countdownTimer;
    interval: 100;
    repeat: true;
    onTriggered: {
      root.timeRemaining -= 100;
      if (root.timeRemaining <= 0) {
        root._execute(root.pendingAction);
      }
    }
  }

  Process {
    id: actionProc;
    running: false;
    onExited: (exitCode) => {
      if (exitCode !== 0) {
        Log.w("Session", "Action failed with exit code:", exitCode);
      }
    }
  }

  // Countdown banner
  Rectangle {
    anchors.bottom: buttonRow.top;
    anchors.bottomMargin: Theme.spacingM;
    anchors.horizontalCenter: parent.horizontalCenter;
    width: countdownContent.implicitWidth + Theme.spacingXL;
    height: 44;
    radius: Theme.radiusL;
    color: Theme.panelBackground;
    visible: root.timerActive;
    opacity: visible ? 1.0 : 0.0;

    RowLayout {
      id: countdownContent;
      anchors.centerIn: parent;
      spacing: Theme.spacingM;

      Text {
        text: {
          var action = root.pendingAction;
          action = action.charAt(0).toUpperCase() + action.slice(1);
          return action + " in " + Math.ceil(root.timeRemaining / 1000) + "s";
        }
        font.pointSize: Theme.fontSizeMedium;
        font.weight: Font.Bold;
        color: Theme.surfaceForeground;
      }

      Rectangle {
        width: 28;
        height: 28;
        radius: 14;
        color: cancelMouse.containsMouse ? Qt.alpha(Theme.error, 0.2) : "transparent";

        Text {
          anchors.centerIn: parent;
          text: "\uf00d"; // x icon
          font.pointSize: Theme.fontSizeSmall;
          font.family: "Symbols Nerd Font";
          color: Theme.error;
        }

        MouseArea {
          id: cancelMouse;
          anchors.fill: parent;
          hoverEnabled: true;
          cursorShape: Qt.PointingHandCursor;
          onClicked: root.cancelTimer();
        }
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: Theme.animNormal;
        easing.type: Easing.OutCubic;
      }
    }
  }

  RowLayout {
    id: buttonRow;
    spacing: Theme.spacingM;

    // Logout
    Rectangle {
      width: logoutRow.implicitWidth + Theme.spacingL * 2;
      height: 40;
      radius: Theme.radiusXL;
      color: logoutMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.15) : "transparent";
      border.color: Qt.alpha(Theme.outline, 0.3);
      border.width: 1;

      Behavior on color { ColorAnimation { duration: 100; } }

      RowLayout {
        id: logoutRow;
        anchors.centerIn: parent;
        spacing: Theme.spacingM;

        Text {
          text: "\uf2f5"; // sign-out icon
          font.pointSize: Theme.fontSizeMedium;
          font.family: "Symbols Nerd Font";
          color: Theme.surfaceVariantForeground;
        }

        Text {
          text: L10n.tr("session.logout");
          font.pointSize: Theme.fontSizeSmall;
          color: Theme.surfaceVariantForeground;
        }
      }

      MouseArea {
        id: logoutMouse;
        anchors.fill: parent;
        hoverEnabled: true;
        cursorShape: Qt.PointingHandCursor;
        onClicked: root._startAction("logout");
      }
    }

    // Suspend
    Rectangle {
      width: suspendRow.implicitWidth + Theme.spacingL * 2;
      height: 40;
      radius: Theme.radiusXL;
      color: suspendMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.15) : "transparent";
      border.color: Qt.alpha(Theme.outline, 0.3);
      border.width: 1;

      Behavior on color { ColorAnimation { duration: 100; } }

      RowLayout {
        id: suspendRow;
        anchors.centerIn: parent;
        spacing: Theme.spacingM;

        Text {
          text: "\uf186"; // moon icon
          font.pointSize: Theme.fontSizeMedium;
          font.family: "Symbols Nerd Font";
          color: Theme.surfaceVariantForeground;
        }

        Text {
          text: L10n.tr("session.suspend");
          font.pointSize: Theme.fontSizeSmall;
          color: Theme.surfaceVariantForeground;
        }
      }

      MouseArea {
        id: suspendMouse;
        anchors.fill: parent;
        hoverEnabled: true;
        cursorShape: Qt.PointingHandCursor;
        onClicked: root._startAction("suspend");
      }
    }

    // Reboot
    Rectangle {
      width: rebootRow.implicitWidth + Theme.spacingL * 2;
      height: 40;
      radius: Theme.radiusXL;
      color: rebootMouse.containsMouse ? Qt.alpha(Theme.surfaceForeground, 0.15) : "transparent";
      border.color: Qt.alpha(Theme.outline, 0.3);
      border.width: 1;

      Behavior on color { ColorAnimation { duration: 100; } }

      RowLayout {
        id: rebootRow;
        anchors.centerIn: parent;
        spacing: Theme.spacingM;

        Text {
          text: "\uf021"; // refresh icon
          font.pointSize: Theme.fontSizeMedium;
          font.family: "Symbols Nerd Font";
          color: Theme.surfaceVariantForeground;
        }

        Text {
          text: L10n.tr("session.reboot");
          font.pointSize: Theme.fontSizeSmall;
          color: Theme.surfaceVariantForeground;
        }
      }

      MouseArea {
        id: rebootMouse;
        anchors.fill: parent;
        hoverEnabled: true;
        cursorShape: Qt.PointingHandCursor;
        onClicked: root._startAction("reboot");
      }
    }

    // Shutdown — filled background to stand out
    Rectangle {
      width: shutdownRow.implicitWidth + Theme.spacingL * 2;
      height: 40;
      radius: Theme.radiusXL;
      color: shutdownMouse.containsMouse ? Theme.primary : Qt.alpha(Theme.surfaceVariant, 0.6);

      Behavior on color { ColorAnimation { duration: 100; } }

      RowLayout {
        id: shutdownRow;
        anchors.centerIn: parent;
        spacing: Theme.spacingM;

        Text {
          text: "\uf011"; // power icon
          font.pointSize: Theme.fontSizeMedium;
          font.family: "Symbols Nerd Font";
          color: shutdownMouse.containsMouse ? Theme.primaryForeground : Theme.surfaceForeground;
          Behavior on color { ColorAnimation { duration: 100; } }
        }

        Text {
          text: L10n.tr("session.shutdown");
          font.pointSize: Theme.fontSizeSmall;
          font.weight: Font.DemiBold;
          color: shutdownMouse.containsMouse ? Theme.primaryForeground : Theme.surfaceForeground;
          Behavior on color { ColorAnimation { duration: 100; } }
        }
      }

      MouseArea {
        id: shutdownMouse;
        anchors.fill: parent;
        hoverEnabled: true;
        cursorShape: Qt.PointingHandCursor;
        onClicked: root._startAction("shutdown");
      }
    }
  }
}
