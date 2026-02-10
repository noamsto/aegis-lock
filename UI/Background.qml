import QtQuick
import qs.Core

Item {
  id: root;
  anchors.fill: parent;
  z: -1;

  // Solid background. In real lock mode, the compositor wallpaper
  // shows through WlSessionLockSurface natively.
  Rectangle {
    anchors.fill: parent;
    color: Theme.surface;
  }
}
