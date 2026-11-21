import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import '../data/exhibits.dart';
import 'beacon_detector.dart';

class DiscoveredDevice {
  final String remoteId;
  final String name;
  final int rssi;
  final double smoothedRssi;
  final List<int> rssiHistory;
  final List<String> parsedUuids;
  final Exhibit? matchedExhibit;
  final Map<int, List<int>> rawManufacturerData;
  final List<Guid> rawServiceUuids;
  final Map<Guid, List<int>> rawServiceData;
  final DateTime lastSeen;

  DiscoveredDevice({
    required this.remoteId,
    required this.name,
    required this.rssi,
    required this.smoothedRssi,
    required this.rssiHistory,
    required this.parsedUuids,
    this.matchedExhibit,
    required this.rawManufacturerData,
    required this.rawServiceUuids,
    required this.rawServiceData,
    required this.lastSeen,
  });

  bool get isKnownBeacon => matchedExhibit != null;

  String get rawManufacturerDataHex {
    if (rawManufacturerData.isEmpty) return 'None';
    return rawManufacturerData.entries.map((entry) {
      final compId =
          '0x${entry.key.toRadixString(16).padLeft(4, '0').toUpperCase()}';
      final data = entry.value
          .map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      return '$compId: $data';
    }).join('\n');
  }

  String get rawServiceUuidsHex {
    if (rawServiceUuids.isEmpty) return 'None';
    return rawServiceUuids.map((g) => g.str128).join('\n');
  }

  String get rawServiceDataHex {
    if (rawServiceData.isEmpty) return 'None';
    return rawServiceData.entries.map((entry) {
      final uuid = entry.key.str128;
      final data = entry.value
          .map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      return '$uuid: $data';
    }).join('\n');
  }
}

class BeaconService extends ChangeNotifier {
  static final BeaconService instance = BeaconService._internal();

  BeaconService._internal() {
    _initAdapterState();
  }

  final Map<String, DiscoveredDevice> _devices = {};
  final Map<String, DateTime> _lastSeenTimestamps = {}; // key: remoteId
  final Map<String, List<int>> _beaconRssiHistory = {}; // key: exhibit.id
  final Map<String, DateTime> _lastOpenedTime = {}; // key: exhibit.id

  // Pre-cached lists to keep build() zero-work
  List<DiscoveredDevice> _cachedKnownBeacons = const [];
  List<DiscoveredDevice> _cachedTop15Devices = const [];
  int _totalDevicesCount = 0;
  int _knownBeaconsCount = 0;

  Timer? _throttleTimer;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  bool _isBluetoothOn = false;
  bool _hasPermissions = false;
  bool _isPermissionPermanentlyDenied = false;
  bool _isScanning = false;
  bool _hasStartedScanOnce = false;
  String _statusMessage = 'Initializing...';
  double _rssiThreshold = -70.0;
  Exhibit? _activeExhibit;

  final StreamController<Exhibit> _exhibitTriggerController =
      StreamController<Exhibit>.broadcast();

  // Getters - zero cost in build()
  List<DiscoveredDevice> get knownBeacons => _cachedKnownBeacons;
  List<DiscoveredDevice> get top15Devices => _cachedTop15Devices;
  List<DiscoveredDevice> get devices => _cachedTop15Devices; // compatibility alias

  int get totalDevicesCount => _totalDevicesCount;
  int get knownBeaconsCount => _knownBeaconsCount;

  int get activeSubscriptionCount {
    int count = 0;
    if (_scanSubscription != null) count++;
    if (_adapterSubscription != null) count++;
    return count;
  }

  int get activeScanSubscriptionCount => _scanSubscription != null ? 1 : 0;

  bool get isBluetoothOn => _isBluetoothOn;
  bool get hasPermissions => _hasPermissions;
  bool get isPermissionPermanentlyDenied => _isPermissionPermanentlyDenied;
  bool get isScanning => _isScanning;
  String get statusMessage => _statusMessage;
  double get rssiThreshold => _rssiThreshold;
  Exhibit? get activeExhibit => _activeExhibit;
  Stream<Exhibit> get onExhibitTriggered => _exhibitTriggerController.stream;

  set rssiThreshold(double value) {
    _rssiThreshold = value;
    notifyListeners();
  }

  void _startThrottleTimer() {
    _throttleTimer?.cancel();
    _throttleTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _tick();
    });
  }

  void _stopThrottleTimer() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
  }

  void _tick() {
    // 4. Drop devices not seen for 10 seconds
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(seconds: 10));
    _devices.removeWhere((key, device) {
      final isOld = device.lastSeen.isBefore(cutoff);
      if (isOld) {
        _lastSeenTimestamps.remove(key);
      }
      return isOld;
    });

    // Pre-sort and cache devices
    final all = _devices.values.toList(growable: false);
    final sorted = List<DiscoveredDevice>.from(all)
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    _cachedTop15Devices = sorted.length > 15 ? sorted.sublist(0, 15) : sorted;
    _cachedKnownBeacons =
        sorted.where((d) => d.isKnownBeacon).toList(growable: false);
    _totalDevicesCount = sorted.length;
    _knownBeaconsCount = _cachedKnownBeacons.length;

    // Evaluate exhibit triggers via BeaconDetector
    BeaconDetector.instance.tick(timestamp: now);

    // Notify listeners only on 500ms intervals
    notifyListeners();
  }

  void _initAdapterState() {
    if (!Platform.isAndroid) return;
    try {
      _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
        final isOn = (state == BluetoothAdapterState.on);
        if (_isBluetoothOn != isOn) {
          _isBluetoothOn = isOn;
          if (!_isBluetoothOn) {
            _isScanning = false;
            _statusMessage = 'Bluetooth is off';
          } else {
            _statusMessage = 'Bluetooth is on';
            // Only start scan if tour is currently active
            if (_hasPermissions && !_isScanning && BeaconDetector.instance.tourActive) {
              startScan();
            }
          }
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Adapter state error: $e');
      });
      debugPrint(
          '[BLE] Adapter subscription created. Active: $activeSubscriptionCount');
      BeaconDetector.instance.logBleSubscriptionEvent(
          'Adapter subscription created (active: $activeSubscriptionCount)');
    } catch (e) {
      debugPrint('Adapter state initialization skipped: $e');
    }
  }

  /// Request permissions on launch without starting BLE scanning
  Future<void> checkPermissionsOnly() async {
    await requestPermissions();
  }

  Future<void> checkPermissionsAndStart() async {
    await requestPermissions();
    if (_hasPermissions && _isBluetoothOn && BeaconDetector.instance.tourActive) {
      await startScan();
    }
  }

  Future<void> requestPermissions() async {
    if (!Platform.isAndroid) {
      _hasPermissions = true;
      notifyListeners();
      return;
    }

    _statusMessage = 'Requesting permissions...';
    notifyListeners();

    try {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final scanStatus = statuses[Permission.bluetoothScan];
      final locStatus = statuses[Permission.location];

      final scanGranted = scanStatus?.isGranted ?? false;
      final locGranted = locStatus?.isGranted ?? false;

      _hasPermissions = scanGranted || locGranted;
      _isPermissionPermanentlyDenied =
          (scanStatus?.isPermanentlyDenied ?? false) ||
              (locStatus?.isPermanentlyDenied ?? false);

      if (_hasPermissions) {
        _statusMessage = 'Permissions granted';
        // Only start scan if tour is active
        if (_isBluetoothOn && !_isScanning && BeaconDetector.instance.tourActive) {
          await startScan();
        }
      } else {
        _statusMessage = _isPermissionPermanentlyDenied
            ? 'Permissions permanently denied. Please enable in Settings.'
            : 'Permissions denied. Bluetooth scan requires permissions.';
      }
    } catch (e) {
      _statusMessage = 'Permission error: $e';
    }

    notifyListeners();
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<void> turnOnBluetooth() async {
    if (Platform.isAndroid) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        debugPrint('FlutterBluePlus.turnOn error: $e');
      }
    }
  }

  /// Make sure there is only ever one scan subscription. Starting twice must not create duplicates.
  Future<void> startScan() async {
    // Only scan when tour is active
    if (!BeaconDetector.instance.tourActive) {
      return;
    }

    // Do not restart scan or create duplicate subscriptions
    if (_isScanning || _scanSubscription != null) {
      return;
    }

    if (!Platform.isAndroid) {
      _isScanning = true;
      _statusMessage = 'Mock scanning (non-Android)';
      notifyListeners();
      return;
    }

    if (_hasStartedScanOnce) {
      BeaconDetector.instance.logWarning(
          'BLE scan restart detected (Android throttles repeated scan starts)');
    }
    _hasStartedScanOnce = true;

    if (!_hasPermissions) {
      await requestPermissions();
      if (!_hasPermissions) return;
    }

    if (!_isBluetoothOn) {
      _statusMessage = 'Bluetooth is off. Please enable Bluetooth.';
      notifyListeners();
      return;
    }

    if (_scanSubscription != null) {
      return;
    }

    try {
      _isScanning = true;
      _statusMessage = 'Scanning in low latency mode...';
      _startThrottleTimer();
      notifyListeners();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _onScanResults(results);
      }, onError: (e) {
        _statusMessage = 'Scan stream error: $e';
        _isScanning = false;
        notifyListeners();
      });

      debugPrint(
          '[BLE] Scan subscription created. Total active: $activeSubscriptionCount');
      BeaconDetector.instance.logBleSubscriptionEvent(
          'Scan subscription created (active: $activeSubscriptionCount)');

      if (!FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.startScan(
          androidScanMode: AndroidScanMode.lowLatency,
          continuousUpdates: true,
          continuousDivisor: 1,
          androidUsesFineLocation: true,
        );
      }
    } catch (e) {
      _statusMessage = 'Failed to start scan: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    _stopThrottleTimer();
    _lastSeenTimestamps.clear();

    if (_scanSubscription != null) {
      await _scanSubscription!.cancel();
      _scanSubscription = null;
      debugPrint(
          '[BLE] Scan subscription cancelled. Total active: $activeSubscriptionCount');
      BeaconDetector.instance.logBleSubscriptionEvent(
          'Scan subscription cancelled (active: $activeSubscriptionCount)');
    }

    if (Platform.isAndroid) {
      try {
        if (FlutterBluePlus.isScanningNow) {
          await FlutterBluePlus.stopScan();
        }
      } catch (e) {
        _statusMessage = 'Error stopping scan: $e';
      }
    }

    _isScanning = false;
    _statusMessage = 'Scan stopped';
    clearDevices();
    notifyListeners();
  }

  Future<void> restartScan() async {
    BeaconDetector.instance.logWarning('Manual scan restart triggered');
    await stopScan();
    await Future.delayed(const Duration(milliseconds: 200));
    await startScan();
  }

  void clearDevices() {
    _devices.clear();
    _lastSeenTimestamps.clear();
    _cachedKnownBeacons = const [];
    _cachedTop15Devices = const [];
    _totalDevicesCount = 0;
    _knownBeaconsCount = 0;
    _beaconRssiHistory.clear();
    notifyListeners();
  }

  /// Ingest scan results without triggering widget rebuilds.
  /// Deduplicate against cached buffer: only process NEW packets (result.timeStamp isAfter last seen).
  /// Cap each device's RSSI history to the last 5 readings.
  void _onScanResults(List<ScanResult> results) {
    for (final result in results) {
      final remoteId = result.device.remoteId.str;
      final packetTime = result.timeStamp;
      final lastTime = _lastSeenTimestamps[remoteId];

      // Stale data audit: flutter_blue_plus.scanResults re-emits the accumulated buffer
      // on every event. Only process when this device has actually received a fresh advertisement.
      if (lastTime != null && !packetTime.isAfter(lastTime)) {
        continue;
      }
      _lastSeenTimestamps[remoteId] = packetTime;

      final adv = result.advertisementData;
      final name = adv.advName.isNotEmpty
          ? adv.advName
          : (result.device.platformName.isNotEmpty
              ? result.device.platformName
              : 'Unknown Device');

      final parsedUuids = parseUuids(adv);

      // Match known beacon ONLY by MAC address (case-insensitively)
      final Exhibit? matchedExhibit = findExhibitByMac(remoteId);

      // 4. Cap each device's RSSI history to the last 5 readings
      final existingDevice = _devices[remoteId];
      final List<int> deviceRssiHistory = existingDevice != null
          ? List<int>.from(existingDevice.rssiHistory)
          : [];
      deviceRssiHistory.add(result.rssi);
      if (deviceRssiHistory.length > 5) {
        deviceRssiHistory.removeAt(0);
      }
      final double deviceSmoothedRssi =
          deviceRssiHistory.reduce((a, b) => a + b) / deviceRssiHistory.length;

      _devices[remoteId] = DiscoveredDevice(
        remoteId: remoteId,
        name: name,
        rssi: result.rssi,
        smoothedRssi: deviceSmoothedRssi,
        rssiHistory: deviceRssiHistory,
        parsedUuids: parsedUuids,
        matchedExhibit: matchedExhibit,
        rawManufacturerData: adv.manufacturerData,
        rawServiceUuids: adv.serviceUuids,
        rawServiceData: adv.serviceData,
        lastSeen: packetTime,
      );

      // Feed automatic beacon detector with exact packet timestamp
      // (Rule: only consider known beacons by MAC)
      if (matchedExhibit != null) {
        BeaconDetector.instance.processReading(
          remoteId,
          result.rssi,
          timestamp: packetTime,
        );
      }
    }
    // No notifyListeners() here: _tick() handles throttled notification every 500 ms.
  }

  void simulateExhibit(Exhibit exhibit) {
    _activeExhibit = exhibit;
    _lastOpenedTime[exhibit.id] = DateTime.now();
    _vibrateOnce();
    _exhibitTriggerController.add(exhibit);
    notifyListeners();
  }

  void clearActiveExhibit() {
    _activeExhibit = null;
    notifyListeners();
  }

  Future<void> _vibrateOnce() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 500);
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  static List<String> parseUuids(AdvertisementData adv) {
    final Set<String> uuids = {};

    adv.manufacturerData.forEach((companyId, bytes) {
      if (bytes.length >= 18 && bytes[0] == 0x02 && bytes[1] == 0x15) {
        final uuid = _formatUuidFromBytes(bytes.sublist(2, 18));
        if (uuid.isNotEmpty) uuids.add(uuid);
      } else {
        for (int i = 0; i <= bytes.length - 18; i++) {
          if (bytes[i] == 0x02 && bytes[i + 1] == 0x15) {
            final uuid = _formatUuidFromBytes(bytes.sublist(i + 2, i + 18));
            if (uuid.isNotEmpty) uuids.add(uuid);
          }
        }
      }
    });

    for (final guid in adv.serviceUuids) {
      uuids.add(guid.str128.toLowerCase());
    }

    for (final guid in adv.serviceData.keys) {
      uuids.add(guid.str128.toLowerCase());
    }

    return uuids.toList();
  }

  static String _formatUuidFromBytes(List<int> bytes) {
    if (bytes.length < 16) return '';
    final hex = bytes
        .sublist(0, 16)
        .map((b) => (b & 0xFF).toRadixString(16).padLeft(2, '0'))
        .join()
        .toLowerCase();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _throttleTimer = null;
    _adapterSubscription?.cancel();
    _adapterSubscription = null;
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _exhibitTriggerController.close();
    super.dispose();
  }
}
