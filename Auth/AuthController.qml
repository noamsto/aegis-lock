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
  property bool unlockInProgress: false;
  property bool showFailure: false;
  property bool showInfo: false;
  property string errorMessage: "";
  property string infoMessage: "";
  property bool pamAvailable: typeof PamContext !== "undefined";

  // Fingerprint state
  readonly property bool fingerprintMode: FingerprintDetector.ready;
  property bool pamStarted: false;
  property bool usePasswordOnly: false;
  property bool abortInProgress: false;

  // Show fingerprint indicator when scanning (hide when typing switches to password mode)
  readonly property bool showFingerprintIndicator: fingerprintMode && unlockInProgress && !waitingForPassword && !showFailure && !usePasswordOnly;

  // PAM config resolution
  readonly property string pamConfigDirectory: {
    var envConfig = Quickshell.env("AEGIS_PAM_CONFIG");
    if (envConfig) return "/etc/pam.d";
    return Config.pamDir;
  }

  readonly property string pamConfig: {
    var envConfig = Quickshell.env("AEGIS_PAM_CONFIG");
    if (envConfig) return envConfig;
    return (usePasswordOnly || !fingerprintMode) ? "password-only.conf" : "fingerprint-only.conf";
  }

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
    abortTimer.stop();
    fingerprintRestartTimer.stop();
    pamStarted = false;
    waitingForPassword = false;
    usePasswordOnly = false;
    abortInProgress = false;
    showFailure = false;
    errorMessage = "";
    infoMessage = "";
    currentText = "";
  }

  // Abort timeout — forces state reset if PAM doesn't respond to abort
  Timer {
    id: abortTimer;
    interval: 150;
    repeat: false;
    onTriggered: {
      if (root.abortInProgress) {
        Log.i("Auth", "PAM abort timeout, forcing state reset");
        root.abortInProgress = false;
        root.unlockInProgress = false;
        root.usePasswordOnly = true;
        root.pamStarted = false;
        root.tryUnlock();
      }
    }
  }

  // Delay before restarting fingerprint auth (prevents tight loops)
  Timer {
    id: fingerprintRestartTimer;
    interval: 500;
    repeat: false;
    onTriggered: root.startFingerprintAuth();
  }

  function startFingerprintAuth() {
    Log.i("Auth", "startFingerprintAuth - fingerprintMode:", fingerprintMode, "pamStarted:", pamStarted, "unlockInProgress:", unlockInProgress);

    if (!fingerprintMode) {
      Log.d("Auth", "Fingerprint not available, skipping");
      return;
    }
    if (pamStarted || unlockInProgress) {
      Log.d("Auth", "PAM already started, skipping");
      return;
    }

    Log.i("Auth", "Starting fingerprint authentication");
    pamStarted = true;
    tryUnlock();
  }

  function tryUnlock(fromEnterPress) {
    fromEnterPress = fromEnterPress || false;
    Log.i("Auth", "tryUnlock - fromEnterPress:", fromEnterPress, "waitingForPassword:", waitingForPassword, "currentText:", currentText !== "" ? "[has text]" : "[empty]", "unlockInProgress:", unlockInProgress);

    if (!pamAvailable) {
      Log.i("Auth", "PAM not available");
      errorMessage = L10n.tr("auth.pam-unavailable");
      showFailure = true;
      return;
    }

    // Respond with password if PAM is waiting
    if (waitingForPassword && currentText !== "") {
      Log.i("Auth", "Responding to PAM with password");
      pam.respond(currentText);
      waitingForPassword = false;
      return;
    }

    // Switch from fingerprint to password mode on Enter press during scan
    if (fromEnterPress && unlockInProgress && currentText !== "" && !waitingForPassword && !abortInProgress && !Quickshell.env("AEGIS_PAM_CONFIG")) {
      Log.i("Auth", "Switching to password-only mode");
      abortInProgress = true;
      abortTimer.start();
      pam.abort();
      return;
    }

    if (unlockInProgress) {
      Log.i("Auth", "Already in progress, ignoring");
      return;
    }

    unlockInProgress = true;
    errorMessage = "";
    showFailure = false;

    Log.i("Auth", "Starting PAM - configDir:", pamConfigDirectory, "config:", pamConfig, "fingerprintMode:", fingerprintMode, "usePasswordOnly:", usePasswordOnly);
    pam.start();
  }

  PamContext {
    id: pam;
    configDirectory: root.pamConfigDirectory;
    config: root.pamConfig;
    user: Quickshell.env("USER") || Quickshell.env("LOGNAME") || "unknown";

    onPamMessage: {
      Log.i("Auth", "PAM message:", message, "isError:", messageIsError, "responseRequired:", responseRequired);

      var msgLower = message.toLowerCase();

      if (messageIsError) {
        root.errorMessage = message;
        if (msgLower.includes("failed") && msgLower.includes("fingerprint")) {
          Log.i("Auth", "Fingerprint failure detected");
          root.fingerprintFailed();
        }
      } else {
        root.infoMessage = message;
      }

      if (responseRequired) {
        var isFingerprintPrompt = msgLower.includes("finger") || msgLower.includes("swipe") || msgLower.includes("touch") || msgLower.includes("scan");

        if (isFingerprintPrompt) {
          Log.i("Auth", "Fingerprint prompt, waiting for sensor");
        } else if (root.currentText !== "") {
          Log.i("Auth", "Responding with password");
          pam.respond(root.currentText);
        } else {
          Log.i("Auth", "Waiting for password input");
          root.waitingForPassword = true;
        }
      }
    }

    onCompleted: result => {
      Log.i("Auth", "PAM completed - result:", result, "abortInProgress:", root.abortInProgress);

      if (root.abortInProgress) {
        Log.i("Auth", "PAM aborted, restarting with password-only");
        abortTimer.stop();
        root.abortInProgress = false;
        root.unlockInProgress = false;
        root.usePasswordOnly = true;
        root.pamStarted = false;
        root.tryUnlock();
        return;
      }

      if (result === PamResult.Success) {
        Log.i("Auth", "Authentication successful");
        root.unlocked();
      } else {
        Log.i("Auth", "Authentication failed");
        root.currentText = "";
        if (root.usePasswordOnly || !root.fingerprintMode) {
          root.errorMessage = L10n.tr("auth.failed");
          root.showFailure = true;
        }
        root.failed();
      }
      root.unlockInProgress = false;
      root.waitingForPassword = false;
      root.usePasswordOnly = false;
      root.pamStarted = false;
    }

    onError: {
      Log.i("Auth", "PAM error:", error, "message:", message);

      if (root.abortInProgress) {
        Log.i("Auth", "PAM abort error, restarting with password-only");
        abortTimer.stop();
        root.abortInProgress = false;
        root.unlockInProgress = false;
        root.usePasswordOnly = true;
        root.pamStarted = false;
        root.tryUnlock();
        return;
      }

      if (root.usePasswordOnly || !root.fingerprintMode) {
        root.errorMessage = message || L10n.tr("auth.error");
        root.showFailure = true;
      }
      root.unlockInProgress = false;
      root.waitingForPassword = false;
      root.usePasswordOnly = false;
      root.pamStarted = false;
      root.failed();
    }
  }
}
