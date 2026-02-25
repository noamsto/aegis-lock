import QtQuick
import Quickshell
import Quickshell.Services.Pam
import qs.Core

Scope {
  id: root;

  signal unlocked;
  signal failed;
  signal fingerprintFailed;

  property string currentText: "";
  property bool waitingForPassword: false;
  property bool showFailure: false;
  property bool showInfo: false;
  property string errorMessage: "";
  property string infoMessage: "";
  property bool pamAvailable: typeof PamContext !== "undefined";

  // Fingerprint state
  readonly property bool fingerprintMode: FingerprintDetector.ready;
  property bool fingerprintActive: false;
  property bool passwordActive: false;
  property bool _unlockHandled: false;

  // Only password auth blocks input/shows pulsing. Fingerprint runs passively.
  readonly property bool unlockInProgress: passwordActive;

  // Show fingerprint indicator when fingerprint PAM is actively scanning
  readonly property bool showFingerprintIndicator: fingerprintMode && fingerprintActive;

  // PAM config resolution — split into separate configs for each context
  readonly property bool _useSystemPamConfig: !!Quickshell.env("AEGIS_PAM_CONFIG");

  readonly property string _systemPamConfigDir: "/etc/pam.d";
  readonly property string _systemPamConfig: Quickshell.env("AEGIS_PAM_CONFIG") || "";

  readonly property string fingerprintPamConfig: _useSystemPamConfig ? _systemPamConfig : "fingerprint-only.conf";
  readonly property string fingerprintPamConfigDir: _useSystemPamConfig ? _systemPamConfigDir : Config.pamDir;

  readonly property string passwordPamConfig: _useSystemPamConfig ? _systemPamConfig : "password-only.conf";
  readonly property string passwordPamConfigDir: _useSystemPamConfig ? _systemPamConfigDir : Config.pamDir;

  onCurrentTextChanged: {
    if (currentText !== "") {
      showInfo = false;
      infoMessage = "";
      showFailure = false;
      errorMessage = "";
    }
  }

  function resetForNewSession() {
    Log.i("Auth", "Resetting state for new lock session");
    if (fingerprintActive) {
      fingerprintPam.abort();
    }
    if (passwordActive) {
      passwordPam.abort();
    }
    fingerprintActive = false;
    passwordActive = false;
    _unlockHandled = false;
    waitingForPassword = false;
    showFailure = false;
    errorMessage = "";
    infoMessage = "";
    currentText = "";
  }

  function startFingerprintAuth() {
    Log.i("Auth", "startFingerprintAuth - fingerprintMode:", fingerprintMode, "fingerprintActive:", fingerprintActive);

    if (!fingerprintMode) {
      Log.d("Auth", "Fingerprint not available, skipping");
      return;
    }
    if (fingerprintActive) {
      Log.d("Auth", "Fingerprint PAM already active, skipping");
      return;
    }
    // System PAM config handles both in one PAM stack — don't start separate fingerprint PAM
    if (_useSystemPamConfig) {
      Log.d("Auth", "Using system PAM config, skipping separate fingerprint PAM");
      return;
    }

    if (!pamAvailable) {
      Log.i("Auth", "PAM not available");
      return;
    }

    Log.i("Auth", "Starting fingerprint PAM - configDir:", fingerprintPamConfigDir, "config:", fingerprintPamConfig);
    fingerprintActive = true;
    fingerprintPam.start();
  }

  function tryUnlock(fromEnterPress) {
    fromEnterPress = fromEnterPress || false;
    Log.i("Auth", "tryUnlock - fromEnterPress:", fromEnterPress, "waitingForPassword:", waitingForPassword, "currentText:", currentText !== "" ? "[has text]" : "[empty]", "passwordActive:", passwordActive);

    if (!pamAvailable) {
      Log.i("Auth", "PAM not available");
      errorMessage = L10n.tr("auth.pam-unavailable");
      showFailure = true;
      return;
    }

    // Respond with password if PAM is waiting
    if (waitingForPassword && currentText !== "") {
      Log.i("Auth", "Responding to password PAM with password");
      passwordPam.respond(currentText);
      waitingForPassword = false;
      return;
    }

    // Start password PAM if not already active and we have text
    if (!passwordActive && currentText !== "") {
      Log.i("Auth", "Starting password PAM - configDir:", passwordPamConfigDir, "config:", passwordPamConfig);
      passwordActive = true;
      errorMessage = "";
      showFailure = false;
      passwordPam.start();
      return;
    }

    Log.d("Auth", "tryUnlock: nothing to do (passwordActive:", passwordActive, "currentText empty:", currentText === "", ")");
  }

  PamContext {
    id: fingerprintPam;
    configDirectory: root.fingerprintPamConfigDir;
    config: root.fingerprintPamConfig;
    user: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "unknown";

    onPamMessage: {
      Log.i("Auth", "Fingerprint PAM message:", message, "isError:", messageIsError, "responseRequired:", responseRequired);

      var msgLower = message.toLowerCase();

      if (messageIsError) {
        if (msgLower.includes("failed") && msgLower.includes("fingerprint")) {
          Log.i("Auth", "Fingerprint failure detected");
          root.fingerprintFailed();
        }
      }
      // Don't show fingerprint PAM info messages — the fingerprint indicator icon is sufficient.

      // Fingerprint PAM should never need a text response — fprintd handles sensor input.
      // If it does ask, we have nothing to send.
    }

    onCompleted: result => {
      Log.i("Auth", "Fingerprint PAM completed - result:", result);

      if (result === PamResult.Success) {
        if (!root._unlockHandled) {
          root._unlockHandled = true;
          Log.i("Auth", "Fingerprint authentication successful");
          if (root.passwordActive) {
            passwordPam.abort();
          }
          root.fingerprintActive = false;
          root.unlocked();
        }
      } else {
        Log.i("Auth", "Fingerprint PAM ended (non-success), deactivating");
        root.fingerprintActive = false;
      }
    }

    onError: {
      Log.i("Auth", "Fingerprint PAM error:", error, "message:", message);
      root.fingerprintActive = false;
    }
  }

  PamContext {
    id: passwordPam;
    configDirectory: root.passwordPamConfigDir;
    config: root.passwordPamConfig;
    user: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "unknown";

    onPamMessage: {
      Log.i("Auth", "Password PAM message:", message, "isError:", messageIsError, "responseRequired:", responseRequired);

      if (messageIsError) {
        root.errorMessage = message;
      } else {
        root.infoMessage = message;
        root.showInfo = true;
      }

      if (responseRequired) {
        if (root.currentText !== "") {
          Log.i("Auth", "Responding with password");
          passwordPam.respond(root.currentText);
        } else {
          Log.i("Auth", "Waiting for password input");
          root.waitingForPassword = true;
        }
      }
    }

    onCompleted: result => {
      Log.i("Auth", "Password PAM completed - result:", result);

      if (result === PamResult.Success) {
        if (!root._unlockHandled) {
          root._unlockHandled = true;
          Log.i("Auth", "Password authentication successful");
          if (root.fingerprintActive) {
            fingerprintPam.abort();
          }
          root.passwordActive = false;
          root.unlocked();
        }
      } else {
        Log.i("Auth", "Password authentication failed");
        root.errorMessage = L10n.tr("auth.failed");
        root.showFailure = true;
        root.passwordActive = false;
        root.waitingForPassword = false;
        root.failed();
      }
    }

    onError: {
      Log.i("Auth", "Password PAM error:", error, "message:", message);
      root.errorMessage = message || L10n.tr("auth.error");
      root.showFailure = true;
      root.passwordActive = false;
      root.waitingForPassword = false;
      root.failed();
    }
  }
}
