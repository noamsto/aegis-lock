pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.Core

Singleton {
  id: root;

  // UPower's aggregate primary device. Always non-null; .ready flips true
  // once the daemon has populated its initial state.
  readonly property var _device: UPower.displayDevice;

  readonly property bool available: _device.ready && _device.isPresent;
  // UPowerDevice.percentage is energy/energyCapacity, normalized 0.0–1.0.
  readonly property int percentage: available ? Math.round(_device.percentage * 100) : 0;
  readonly property bool charging: available && _device.state === UPowerDeviceState.Charging;

  readonly property string icon: {
    if (charging) return "";       // bolt
    if (percentage > 75) return ""; // battery-full
    if (percentage > 50) return ""; // battery-three-quarters
    if (percentage > 25) return ""; // battery-half
    if (percentage > 10) return ""; // battery-quarter
    return "";                      // battery-empty
  }

  onChargingChanged: Log.d("Battery", "charging:", charging, "percentage:", percentage)
}
