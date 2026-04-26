pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.Core

Singleton {
  id: root;

  // Re-evaluates when players appear/disappear on the bus.
  readonly property var _player: {
    var players = Mpris.players.values;
    return (players && players.length > 0) ? players[0] : null;
  }

  readonly property bool available: _player !== null;
  readonly property bool playing: available && _player.isPlaying;
  readonly property string title: available ? _player.trackTitle : "";
  readonly property string artist: available ? _player.trackArtist : "";
  readonly property string artUrl: available ? _player.trackArtUrl : "";

  function playPause() { if (_player) _player.togglePlaying(); }
  function next() { if (_player) _player.next(); }
  function previous() { if (_player) _player.previous(); }

  onAvailableChanged: Log.d("Media", "available:", available, "player:", _player ? _player.identity : "(none)")
  onPlayingChanged: Log.d("Media", "playing:", playing, "title:", title)
}
