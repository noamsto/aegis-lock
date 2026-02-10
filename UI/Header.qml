import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core

Item {
  id: root;
  anchors.horizontalCenter: parent.horizontalCenter;
  anchors.top: parent.top;
  anchors.topMargin: parent.height * 0.15;
  width: 400;
  height: headerColumn.implicitHeight;

  property date currentTime: new Date();

  Timer {
    interval: 1000;
    running: true;
    repeat: true;
    onTriggered: root.currentTime = new Date();
  }

  ColumnLayout {
    id: headerColumn;
    anchors.horizontalCenter: parent.horizontalCenter;
    spacing: Theme.spacingM;

    // Clock
    Text {
      Layout.alignment: Qt.AlignHCenter;
      text: Qt.formatTime(root.currentTime, Config.data.general ? Config.data.general.clockFormat || "HH:mm" : "HH:mm");
      font.pointSize: Theme.fontSizeClock;
      font.weight: Font.Light;
      color: Theme.surfaceForeground;
    }

    // Date
    Text {
      Layout.alignment: Qt.AlignHCenter;
      text: Qt.formatDate(root.currentTime, Config.data.general ? Config.data.general.dateFormat || "dddd, MMMM d" : "dddd, MMMM d");
      font.pointSize: Theme.fontSizeXL;
      font.weight: Font.Normal;
      color: Theme.surfaceVariantForeground;
    }

    // Welcome message
    Text {
      Layout.alignment: Qt.AlignHCenter;
      Layout.topMargin: Theme.spacingL;
      text: L10n.tr("welcome.greeting") + ", " + (Quickshell.env("USER") || "User")
      font.pointSize: Theme.fontSizeLarge;
      font.weight: Font.Normal;
      color: Qt.alpha(Theme.surfaceForeground, 0.7);
    }
  }
}
