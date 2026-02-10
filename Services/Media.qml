pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core

Singleton {
  id: root;

  property string title: "";
  property string artist: "";
  property string artUrl: "";
  property bool playing: false;
  property bool available: false;

  property string _statusBuffer: ""
  property string _metaBuffer: ""

  function playPause() {
    controlProc.command = ["playerctl", "play-pause"];
    controlProc.running = true;
  }

  function next() {
    controlProc.command = ["playerctl", "next"];
    controlProc.running = true;
  }

  function previous() {
    controlProc.command = ["playerctl", "previous"];
    controlProc.running = true;
  }

  function init() {
    _pollStatus();
    pollTimer.start();
  }

  function _pollStatus() {
    root._statusBuffer = "";
    statusProc.running = true;
  }

  Timer {
    id: pollTimer;
    interval: 3000;
    repeat: true;
    onTriggered: root._pollStatus();
  }

  Process {
    id: statusProc;
    command: ["playerctl", "status"];
    running: false;
    stdout: SplitParser {
      onRead: (line) => { root._statusBuffer += line; }
    }
    onExited: (exitCode) => {
      if (exitCode === 0) {
        var status = root._statusBuffer.trim().toLowerCase();
        root.playing = (status === "playing");
        root.available = (status === "playing" || status === "paused");
        if (root.available) {
          root._metaBuffer = "";
          metadataProc.running = true;
        } else {
          root.title = "";
          root.artist = "";
          root.artUrl = "";
        }
      } else {
        root.available = false;
        root.playing = false;
      }
    }
  }

  Process {
    id: metadataProc;
    command: ["playerctl", "metadata", "--format", "{{artist}}\t{{title}}\t{{mpris:artUrl}}"];
    running: false;
    stdout: SplitParser {
      onRead: (line) => { root._metaBuffer += line; }
    }
    onExited: (exitCode) => {
      if (exitCode === 0) {
        var parts = root._metaBuffer.trim().split("\t");
        root.artist = parts[0] || "";
        root.title = parts[1] || "";
        root.artUrl = parts[2] || "";
      }
    }
  }

  Process {
    id: controlProc;
    running: false;
    onExited: root._pollStatus();  // refresh state after control action
  }
}
