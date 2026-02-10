pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
  id: root;

  // Detection state
  property bool available: false;
  property bool hasDevice: false;
  property bool hasEnrolledFingers: false;
  readonly property bool ready: hasDevice && hasEnrolledFingers;

  function refresh() {
    detectProc.retryCount = 0;
    detectProc.running = true;
  }

  function init() {
    var username = _getUsername();
    Log.i("Fingerprint", "Detecting fingerprint reader for user:", username);
    detectProc.command = ["fprintd-list", username];
    detectProc.running = true;
  }

  function _getUsername() {
    return Quickshell.env("USER") || Quickshell.env("LOGNAME") || "unknown";
  }

  Timer {
    id: retryTimer;
    interval: 1000;
    repeat: false;
    onTriggered: detectProc.running = true;
  }

  Process {
    id: detectProc;
    command: ["fprintd-list", root._getUsername()];

    property int retryCount: 0;
    property int maxRetries: 3;

    stdout: StdioCollector {
      onStreamFinished: {
        var output = text.trim();
        if (output.length > 10000) {
          Log.w("Fingerprint", "fprintd-list output too large, truncating");
          output = output.substring(0, 10000);
        }
        Log.d("Fingerprint", "fprintd-list output:", output);

        root.hasDevice = output.includes("found") && output.includes("device");

        if (!root.hasDevice) {
          Log.i("Fingerprint", "No fingerprint device found");
          root.available = false;
          root.hasEnrolledFingers = false;
          return;
        }

        root.available = true;
        detectProc.retryCount = 0;

        var hasFingers = output.includes("Fingerprints for user") && !output.includes("no fingerprints enrolled") && /- #\d+:/.test(output);
        root.hasEnrolledFingers = hasFingers;

        if (root.hasEnrolledFingers) {
          Log.i("Fingerprint", "Device found with enrolled fingerprints - ready");
        } else {
          Log.i("Fingerprint", "Device found but no fingerprints enrolled");
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") {
          Log.w("Fingerprint", "fprintd-list stderr:", text.trim());
        }
      }
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0) {
        if (detectProc.retryCount < detectProc.maxRetries) {
          detectProc.retryCount++;
          Log.i("Fingerprint", "fprintd-list failed, retry", detectProc.retryCount, "of", detectProc.maxRetries);
          retryTimer.start();
        } else {
          Log.i("Fingerprint", "fprintd-list failed after", detectProc.maxRetries, "retries - unavailable");
          root.available = false;
          root.hasDevice = false;
          root.hasEnrolledFingers = false;
        }
      }
    }
  }
}
