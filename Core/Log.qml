pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root;

  readonly property bool debug: Quickshell.env("AEGIS_DEBUG") === "1";

  function _fmt(level, tag, args) {
    var parts = [];
    for (var i = 0; i < args.length; i++) {
      parts.push(String(args[i]));
    }
    return "[" + level + "] [" + tag + "] " + parts.join(" ");
  }

  function d(tag) {
    if (!debug) return;
    var args = Array.prototype.slice.call(arguments, 1);
    console.log(_fmt("DEBUG", tag, args));
  }

  function i(tag) {
    var args = Array.prototype.slice.call(arguments, 1);
    console.log(_fmt("INFO", tag, args));
  }

  function w(tag) {
    var args = Array.prototype.slice.call(arguments, 1);
    console.warn(_fmt("WARN", tag, args));
  }

  function e(tag) {
    var args = Array.prototype.slice.call(arguments, 1);
    console.error(_fmt("ERROR", tag, args));
  }
}
