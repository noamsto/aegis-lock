pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root;

  property var strings: ({});
  property bool ready: false;

  function init() {
    translationsView.path = Qt.resolvedUrl("../Assets/translations/en.json");
  }

  // Simple key lookup with optional interpolation
  // Usage: L10n.tr("auth.failed") or L10n.tr("session.countdown", { action: "Reboot", seconds: "5" })
  function tr(key, params) {
    var text = strings[key] || key;
    if (params) {
      var keys = Object.keys(params);
      for (var i = 0; i < keys.length; i++) {
        text = text.replace("{" + keys[i] + "}", params[keys[i]]);
      }
    }
    return text;
  }

  FileView {
    id: translationsView;
    watchChanges: false;
    onTextChanged: {
      if (translationsView.text()) {
        try {
          root.strings = JSON.parse(translationsView.text());
          root.ready = true;
          Log.i("Locale", "Translations loaded:", Object.keys(root.strings).length, "keys");
        } catch (e) {
          Log.w("Locale", "Failed to parse translations:", e);
        }
      }
    }
  }
}
