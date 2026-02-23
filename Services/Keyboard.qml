pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Core

Singleton {
  id: root;

  property string layout: "";       // full keymap name, e.g. "English (US)"
  property string layoutShort: "";   // short code, e.g. "EN"
  property bool available: false;

  // Map common XKB keymap names to short codes
  readonly property var _langMap: ({
    "english": "EN",
    "hebrew": "HE",
    "arabic": "AR",
    "russian": "RU",
    "german": "DE",
    "french": "FR",
    "spanish": "ES",
    "italian": "IT",
    "portuguese": "PT",
    "dutch": "NL",
    "polish": "PL",
    "czech": "CZ",
    "swedish": "SE",
    "norwegian": "NO",
    "danish": "DK",
    "finnish": "FI",
    "turkish": "TR",
    "greek": "GR",
    "japanese": "JA",
    "korean": "KO",
    "chinese": "ZH",
    "thai": "TH",
    "vietnamese": "VI",
    "ukrainian": "UK",
    "romanian": "RO",
    "hungarian": "HU",
    "bulgarian": "BG",
    "croatian": "HR",
    "serbian": "SR",
    "slovak": "SK",
    "slovenian": "SI",
    "latvian": "LV",
    "lithuanian": "LT",
    "estonian": "ET",
    "icelandic": "IS",
    "persian": "FA",
    "hindi": "HI",
  })

  function _toShortCode(keymap) {
    if (!keymap) return "";
    // Extract first word (language name) — "English (US)" → "English"
    var lang = keymap.split(/[\s(]/)[0].toLowerCase();
    if (_langMap[lang]) return _langMap[lang];
    // Fallback: first 2 chars uppercase
    return lang.substring(0, 2).toUpperCase();
  }

  function _setLayout(keymap) {
    if (!keymap) return;
    root.layout = keymap;
    root.layoutShort = root._toShortCode(keymap);
    root.available = true;
    Log.d("Keyboard", "Layout:", root.layoutShort, "(" + keymap + ")");
  }

  function refresh() {
    _hyprBuffer = "";
    hyprProc.running = true;
  }

  function init() {
    // Listen to Hyprland activelayout events for real-time updates
    Hyprland.rawEvent.connect(function(event) {
      if (event.name === "activelayout") {
        // Format: keyboard_name,layout_name
        var args = event.parse(2);
        if (args.length >= 2) {
          root._setLayout(args[1]);
        }
      }
    });

    // Initial state: one-time poll
    refresh();
  }

  // One-time initial poll to get current layout
  property string _hyprBuffer: ""

  Process {
    id: hyprProc;
    command: ["hyprctl", "devices", "-j"];
    running: false;
    stdout: SplitParser {
      onRead: (line) => { root._hyprBuffer += line + "\n"; }
    }
    onExited: (exitCode) => {
      if (exitCode === 0) {
        try {
          var data = JSON.parse(root._hyprBuffer);
          var keyboards = data.keyboards;
          if (!keyboards || keyboards.length === 0) return;
          var kb = null;
          for (var i = 0; i < keyboards.length; i++) {
            if (keyboards[i].main) { kb = keyboards[i]; break; }
          }
          if (!kb) kb = keyboards[0];
          root._setLayout(kb.active_keymap || "");
        } catch (e) {
          Log.d("Keyboard", "Failed to parse hyprctl output:", e);
        }
      }
    }
  }
}
