pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
  id: root;

  readonly property string pamDir: Config.pamDir;

  function init() {
    // Skip if using system PAM config
    if (Quickshell.env("AEGIS_PAM_CONFIG")) {
      Log.i("PamConfigs", "Using system PAM config:", Quickshell.env("AEGIS_PAM_CONFIG"));
      return;
    }
    Log.i("PamConfigs", "Ensuring PAM configs in:", pamDir);
    _ensureConfigs();
  }

  function _ensureConfigs() {
    checkFingerprintProc.command = ["test", "-f", pamDir + "fingerprint-only.conf"];
    checkFingerprintProc.running = true;

    checkPasswordProc.command = ["test", "-f", pamDir + "password-only.conf"];
    checkPasswordProc.running = true;

    checkOtherProc.command = ["test", "-f", pamDir + "other"];
    checkOtherProc.running = true;
  }

  function _createFingerprintOnly() {
    var dirEsc = pamDir.replace(/'/g, "'\\''");
    var fileEsc = (pamDir + "fingerprint-only.conf").replace(/'/g, "'\\''");
    var content = "auth sufficient pam_fprintd.so timeout=-1 max-tries=-1\n";
    content += "auth sufficient /run/current-system/sw/lib/security/pam_fprintd.so timeout=-1 max-tries=-1\n";
    content += "auth required pam_deny.so\n";
    var script = "mkdir -p '" + dirEsc + "' && chmod 700 '" + dirEsc + "' && ";
    script += "cat > '" + fileEsc + "' << 'EOF'\n" + content + "EOF\n";
    script += "chmod 600 '" + fileEsc + "'";
    Quickshell.execDetached(["sh", "-c", script]);
    Log.i("PamConfigs", "Created fingerprint-only.conf");
  }

  function _createPasswordOnly() {
    var dirEsc = pamDir.replace(/'/g, "'\\''");
    var fileEsc = (pamDir + "password-only.conf").replace(/'/g, "'\\''");
    var content = "auth required pam_unix.so\n";
    var script = "mkdir -p '" + dirEsc + "' && chmod 700 '" + dirEsc + "' && ";
    script += "cat > '" + fileEsc + "' << 'EOF'\n" + content + "EOF\n";
    script += "chmod 600 '" + fileEsc + "'";
    Quickshell.execDetached(["sh", "-c", script]);
    Log.i("PamConfigs", "Created password-only.conf");
  }

  function _createOther() {
    var dirEsc = pamDir.replace(/'/g, "'\\''");
    var fileEsc = (pamDir + "other").replace(/'/g, "'\\''");
    var content = "auth required pam_deny.so\n";
    var script = "mkdir -p '" + dirEsc + "' && chmod 700 '" + dirEsc + "' && ";
    script += "cat > '" + fileEsc + "' << 'EOF'\n" + content + "EOF\n";
    script += "chmod 600 '" + fileEsc + "'";
    Quickshell.execDetached(["sh", "-c", script]);
    Log.i("PamConfigs", "Created 'other' fallback config");
  }

  Process {
    id: checkFingerprintProc;
    running: false;
    onExited: (exitCode) => {
      if (exitCode !== 0) root._createFingerprintOnly();
    }
  }

  Process {
    id: checkPasswordProc;
    running: false;
    onExited: (exitCode) => {
      if (exitCode !== 0) root._createPasswordOnly();
    }
  }

  Process {
    id: checkOtherProc;
    running: false;
    onExited: (exitCode) => {
      if (exitCode !== 0) root._createOther();
    }
  }
}
