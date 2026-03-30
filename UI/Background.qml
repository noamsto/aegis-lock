import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.Core

Item {
  id: root;
  anchors.fill: parent;
  z: -1;

  // Solid fallback (always present under the wallpaper)
  Rectangle {
    anchors.fill: parent;
    color: Theme.surface;
  }

  // Wallpaper path from noctalia
  FileView {
    id: wallpaperPathFile;
    path: {
      var home = Quickshell.env("HOME") || "/tmp";
      var xdg = Quickshell.env("XDG_CONFIG_HOME");
      var base = xdg ? xdg : (home + "/.config");
      return base + "/noctalia/last-wallpaper";
    }
    watchChanges: true;
  }

  property string wallpaperPath: {
    var raw = wallpaperPathFile.text();
    return raw ? raw.trim() : "";
  }

  Image {
    id: wallpaperImage;
    anchors.fill: parent;
    source: root.wallpaperPath ? ("file://" + root.wallpaperPath) : "";
    fillMode: Image.PreserveAspectCrop;
    visible: false; // rendered via the blur effect
    asynchronous: true;
  }

  MultiEffect {
    anchors.fill: wallpaperImage;
    source: wallpaperImage;
    blurEnabled: true;
    blurMax: 64;
    blur: 0.6;
    visible: wallpaperImage.status === Image.Ready;
    opacity: visible ? 1.0 : 0.0;
    Behavior on opacity { NumberAnimation { duration: Theme.animSlow; } }
  }

  // Dim overlay so text stays readable
  Rectangle {
    anchors.fill: parent;
    color: Qt.alpha(Theme.surface, 0.55);
    visible: wallpaperImage.status === Image.Ready;
  }
}
