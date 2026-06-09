pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import qs.Core

Singleton {
  id: root;

  // The active device. Wired wins over wifi when both are up, since the wired
  // route is the one actually carrying traffic. Null when nothing is connected.
  readonly property var _device: {
    const devs = Networking.devices.values;
    let wifi = null;
    for (let i = 0; i < devs.length; i++) {
      const d = devs[i];
      if (!d.connected) continue;
      if (d.type === DeviceType.Wired) return d;
      if (d.type === DeviceType.Wifi) wifi = d;
    }
    return wifi;
  }

  readonly property bool available: _device !== null;
  readonly property bool isWifi: available && _device.type === DeviceType.Wifi;

  // The connected network on the active wifi device — carries ssid and strength.
  readonly property var _wifiNetwork: {
    if (!isWifi) return null;
    const nets = _device.networks.values;
    for (let i = 0; i < nets.length; i++) {
      if (nets[i].connected) return nets[i];
    }
    return null;
  }

  readonly property string ssid: _wifiNetwork ? _wifiNetwork.name : "";
  readonly property real signalStrength: _wifiNetwork ? _wifiNetwork.signalStrength : 0;

  // Nerd Font (Material Design) glyphs built from codepoints — literal PUA bytes
  // get mangled on save. Comments name each glyph for editing.
  readonly property string icon: {
    if (!available) return String.fromCodePoint(0xF05AA);            // nf-md-wifi_off
    if (!isWifi) return String.fromCodePoint(0xF0200);               // nf-md-ethernet
    if (signalStrength > 0.75) return String.fromCodePoint(0xF0928); // nf-md-wifi_strength_4
    if (signalStrength > 0.5) return String.fromCodePoint(0xF0925);  // nf-md-wifi_strength_3
    if (signalStrength > 0.25) return String.fromCodePoint(0xF0922); // nf-md-wifi_strength_2
    return String.fromCodePoint(0xF091F);                            // nf-md-wifi_strength_1
  }

  onAvailableChanged: Log.d("Network", "available:", available, "wifi:", isWifi, "ssid:", ssid)
}
