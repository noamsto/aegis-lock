pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root;

  // -- Colors (Material-style naming) --
  property color primary: "#8B7EC8"
  property color primaryForeground: "#FFFFFF"
  property color primaryContainer: "#E8DEF8"
  property color surface: "#1C1B1F"
  property color surfaceForeground: "#E6E1E5"
  property color surfaceVariant: "#49454F"
  property color surfaceVariantForeground: "#CAC4D0"
  property color error: "#F44336"
  property color errorForeground: "#FFFFFF"
  property color outline: "#938F99"

  // -- Derived colors --
  readonly property color shieldBackground: Qt.alpha(surface, 0.7);
  readonly property color inputBackground: Qt.alpha(surface, 0.85);
  readonly property color inputBorder: Qt.alpha(primary, 0.4);
  readonly property color inputBorderFocused: primary;
  readonly property color panelBackground: Qt.alpha(surface, 0.8);
  readonly property color indicatorBackground: surfaceVariant;

  // -- Typography --
  readonly property int fontSizeSmall: 11;
  readonly property int fontSizeMedium: 13;
  readonly property int fontSizeLarge: 16;
  readonly property int fontSizeXL: 20;
  readonly property int fontSizeXXL: 24;
  readonly property int fontSizeClock: 64;

  // -- Spacing --
  readonly property int spacingS: 4;
  readonly property int spacingM: 8;
  readonly property int spacingL: 16;
  readonly property int spacingXL: 24;
  readonly property int spacingXXL: 32;

  // -- Geometry --
  readonly property int radiusS: 4;
  readonly property int radiusM: 8;
  readonly property int radiusL: 16;
  readonly property int radiusXL: 24;
  readonly property int borderThin: 1;
  readonly property int borderMedium: 2;

  // -- Animation --
  readonly property int animFast: 150;
  readonly property int animNormal: 250;
  readonly property int animSlow: 400;

  property bool ready: false;

  function init() {
    _tryLoadColors();
    root.ready = true;
  }

  // Try loading colors from noctalia's colors.json or own override
  function _tryLoadColors() {
    // Priority 1: own override
    var ownPath = Config.configDir + "colors.json";
    // Priority 2: noctalia's colors
    var home = Quickshell.env("HOME") || "/tmp";
    var xdg = Quickshell.env("XDG_CONFIG_HOME");
    var noctaliaBase = xdg ? xdg : (home + "/.config");
    var noctaliaPath = noctaliaBase + "/noctalia/colors.json";

    // Try own first, then noctalia
    ownColorsView.path = ownPath;
    noctaliaColorsView.path = noctaliaPath;
  }

  function _applyColors(jsonText) {
    if (!jsonText || !jsonText.trim()) return false;
    try {
      var colors = JSON.parse(jsonText);
      // Map noctalia color scheme to our properties
      if (colors.primary) root.primary = colors.primary;
      if (colors.onPrimary) root.primaryForeground = colors.onPrimary;
      if (colors.primaryContainer) root.primaryContainer = colors.primaryContainer;
      if (colors.surface) root.surface = colors.surface;
      if (colors.onSurface) root.surfaceForeground = colors.onSurface;
      if (colors.surfaceVariant) root.surfaceVariant = colors.surfaceVariant;
      if (colors.onSurfaceVariant) root.surfaceVariantForeground = colors.onSurfaceVariant;
      if (colors.error) root.error = colors.error;
      if (colors.onError) root.errorForeground = colors.onError;
      if (colors.outline) root.outline = colors.outline;
      Log.i("Theme", "Colors loaded from file");
      return true;
    } catch (e) {
      Log.d("Theme", "Failed to parse colors:", e);
      return false;
    }
  }

  // Own colors override (highest priority)
  FileView {
    id: ownColorsView;
    watchChanges: true;
    onTextChanged: {
      var text = ownColorsView.text();
      if (text && text.trim()) {
        root._applyColors(text);
      }
    }
  }

  // Noctalia colors sync (lower priority, only if own not present)
  FileView {
    id: noctaliaColorsView;
    watchChanges: true;
    onTextChanged: {
      // Only use noctalia colors if own override doesn't exist
      var ownText = ownColorsView.text();
      if (ownText && ownText.trim()) return;
      var text = noctaliaColorsView.text();
      if (text && text.trim()) {
        root._applyColors(text);
      }
    }
  }
}
