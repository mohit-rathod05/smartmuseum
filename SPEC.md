# Smart Museum Guide - Demo APK (Android only)
Purpose: Makerfest demo. A phone app detects BLE beacons near "exhibits" and
automatically opens the matching exhibit page. No cloud, no login, fully offline.

Stack: Flutter (Dart), flutter_blue_plus, permission_handler, vibration,
video_player, audioplayers. Android only.

Beacons (ISC-beacon-v01). Match by UUID, NOT by MAC (MACs may rotate):
- d24d8a17-de93-4afb-bcf5-0db8e1435c3e -> Exhibit 1 "Entrance Gate"
- 933770bc-42a8-4917-8ddf-d3d2a10be215 -> Exhibit 2 "Durbar Hall"
- 20caf628-3e5e-44a8-9b4f-358eb910e2e3 -> Exhibit 3 "Royal Gallery"
The UUID may be in iBeacon manufacturer data (company ID 0x004C, bytes 02 15
then 16-byte UUID) or in advertised service UUIDs. Support both, and match
case-insensitively.

Screens:
1. Home: title, "Start Tour" button, scanning status animation
2. Exhibit: title, photo, story text, audio and video player. Opens automatically
   on detection.
3. Developer screen (hidden, opened by long-pressing the Home title): live list
   of all nearby BLE devices with name, MAC, RSSI, detected UUID; marks known
   beacons; a "Simulate exhibit" list; an RSSI threshold slider (-100 to -40 dBm,
   default -70).

Detection logic: moving average of last 5 RSSI readings per beacon; strongest
smoothed beacon above threshold wins; switch only if new beacon is >=5 dB
stronger than the current one; 20 second cooldown before reopening the same
exhibit; vibrate once when a new exhibit opens.

Content is bundled in assets/ (offline). Exhibit data lives in one Dart file
(lib/data/exhibits.dart) so it is easy to edit.
Not in v1: stats, language toggle, cloud, iOS.
