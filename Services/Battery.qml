pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
  id: root;

  property bool available: false;
  property int percentage: 0;
  property bool charging: false;
  property string icon: "\uf240"; // battery-full

  function init() {
    readCapacity.running = true;
    readStatus.running = true;
    pollTimer.start();
  }

  Timer {
    id: pollTimer;
    interval: 30000;
    repeat: true;
    onTriggered: {
      readCapacity.running = true;
      readStatus.running = true;
    }
  }

  Process {
    id: readCapacity;
    command: ["cat", "/sys/class/power_supply/BAT0/capacity"];
    running: false;

    stdout: StdioCollector {
      onStreamFinished: {
        var val = parseInt(text.trim());
        if (!isNaN(val)) {
          root.available = true;
          root.percentage = val;
          root._updateIcon();
        }
      }
    }

    onExited: (exitCode) => {
      if (exitCode !== 0) {
        // Try BAT1
        readCapacityAlt.running = true;
      }
    }
  }

  Process {
    id: readCapacityAlt;
    command: ["cat", "/sys/class/power_supply/BAT1/capacity"];
    running: false;

    stdout: StdioCollector {
      onStreamFinished: {
        var val = parseInt(text.trim());
        if (!isNaN(val)) {
          root.available = true;
          root.percentage = val;
          root._updateIcon();
        }
      }
    }
  }

  Process {
    id: readStatus;
    command: ["cat", "/sys/class/power_supply/BAT0/status"];
    running: false;

    stdout: StdioCollector {
      onStreamFinished: {
        var status = text.trim().toLowerCase();
        root.charging = (status === "charging");
        root._updateIcon();
      }
    }

    onExited: (exitCode) => {
      if (exitCode !== 0) {
        readStatusAlt.running = true;
      }
    }
  }

  Process {
    id: readStatusAlt;
    command: ["cat", "/sys/class/power_supply/BAT1/status"];
    running: false;

    stdout: StdioCollector {
      onStreamFinished: {
        var status = text.trim().toLowerCase();
        root.charging = (status === "charging");
        root._updateIcon();
      }
    }
  }

  function _updateIcon() {
    if (charging) {
      icon = "\uf0e7"; // bolt
    } else if (percentage > 75) {
      icon = "\uf240"; // battery-full
    } else if (percentage > 50) {
      icon = "\uf241"; // battery-three-quarters
    } else if (percentage > 25) {
      icon = "\uf242"; // battery-half
    } else if (percentage > 10) {
      icon = "\uf243"; // battery-quarter
    } else {
      icon = "\uf244"; // battery-empty
    }
  }
}
