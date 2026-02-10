pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root;

  // Resolved config directory
  readonly property string configDir: {
    var dir = Quickshell.env("AEGIS_CONFIG_DIR");
    if (dir) return dir.endsWith("/") ? dir : dir + "/";
    var xdg = Quickshell.env("XDG_CONFIG_HOME");
    var home = Quickshell.env("HOME");
    var base = xdg ? xdg : (home + "/.config");
    return base + "/aegis-lock/";
  }

  readonly property string configFile: configDir + "config.json";
  readonly property string pamDir: configDir + "pam/";

  // Parsed config data — components bind to this
  property var data: ({})

  // Whether config has loaded at least once
  property bool ready: false;

  function init() {
    Log.i("Config", "Config directory:", configDir);
    Log.i("Config", "Config file:", configFile);
    configView.path = configFile;
    initTimer.start();
  }

  // Deep merge: overlay takes priority over base
  function _deepMerge(base, overlay) {
    if (typeof base !== "object" || base === null) return overlay;
    if (typeof overlay !== "object" || overlay === null) return overlay;
    var result = {};
    // Copy all base keys
    var keys = Object.keys(base);
    for (var i = 0; i < keys.length; i++) {
      result[keys[i]] = base[keys[i]];
    }
    // Merge overlay keys
    keys = Object.keys(overlay);
    for (var j = 0; j < keys.length; j++) {
      var k = keys[j];
      if (typeof result[k] === "object" && result[k] !== null && typeof overlay[k] === "object" && overlay[k] !== null && !Array.isArray(result[k])) {
        result[k] = _deepMerge(result[k], overlay[k]);
      } else {
        result[k] = overlay[k];
      }
    }
    return result;
  }

  function _loadDefaults() {
    try {
      var text = defaultsView.text();
      if (text && text.trim()) {
        return JSON.parse(text);
      }
    } catch (e) {
      Log.w("Config", "Failed to parse defaults:", e);
    }
    return {};
  }

  function _apply(jsonText) {
    var defaults = _loadDefaults();
    var user = {};
    if (jsonText && jsonText.trim()) {
      try {
        user = JSON.parse(jsonText);
      } catch (e) {
        Log.w("Config", "Failed to parse user config:", e);
      }
    }
    root.data = _deepMerge(defaults, user);
    root.ready = true;
    Log.i("Config", "Config loaded, ready:", ready);
  }

  // Bundled defaults
  FileView {
    id: defaultsView;
    path: Qt.resolvedUrl("../Assets/config-default.json");
  }

  // User config with file watching
  FileView {
    id: configView;
    watchChanges: true;
    onTextChanged: {
      if (configView.path !== "") {
        root._apply(configView.text());
      }
    }
  }

  // If file doesn't exist yet, apply defaults only
  Timer {
    id: initTimer;
    interval: 100;
    running: false;
    repeat: false;
    onTriggered: {
      if (!root.ready) {
        Log.i("Config", "No user config found, using defaults");
        root._apply("");
      }
    }
  }

  // initTimer is started from init(), not Component.onCompleted,
  // to avoid races when init() hasn't been called yet.
}
