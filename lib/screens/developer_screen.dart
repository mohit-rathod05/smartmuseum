import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import '../data/exhibits.dart';
import '../services/beacon_detector.dart';
import '../services/beacon_service.dart';
import '../services/exhibit_navigator.dart';
import 'exhibit_screen.dart';

class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  final BeaconService _beaconService = BeaconService.instance;
  final BeaconDetector _detector = BeaconDetector.instance;
  bool _showAllDevices = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _beaconService.checkPermissionsAndStart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_beaconService, _detector]),
      builder: (context, _) {
        // Zero computation in build(): pre-filtered and pre-sorted in the 500ms service tick
        final List<DiscoveredDevice> displayDevices = _showAllDevices
            ? _beaconService.top15Devices
            : _beaconService.knownBeacons;

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Developer Screen',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'BLE Diagnostics & Throttled Live Stream',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Clear list',
                icon: const Icon(Icons.delete_sweep),
                onPressed: _beaconService.clearDevices,
              ),
              IconButton(
                tooltip: _beaconService.isScanning ? 'Pause scan' : 'Start scan',
                icon: Icon(
                  _beaconService.isScanning
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: _beaconService.isScanning ? Colors.greenAccent : null,
                ),
                onPressed: () {
                  if (_beaconService.isScanning) {
                    _beaconService.stopScan();
                  } else {
                    _beaconService.startScan();
                  }
                },
              ),
              IconButton(
                tooltip: 'Restart scan',
                icon: const Icon(Icons.refresh),
                onPressed: _beaconService.restartScan,
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // Top Controls & Status
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Permission Warning Banner
                      if (!_beaconService.hasPermissions)
                        Card(
                          color: Colors.red.shade900.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                                color: Colors.redAccent, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Colors.redAccent),
                                    SizedBox(width: 8),
                                    Text(
                                      'Permissions Required',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _beaconService.isPermissionPermanentlyDenied
                                      ? 'Bluetooth scanning and location permissions are permanently denied. Please allow them in system App Settings.'
                                      : 'Bluetooth scan/connect and location permissions are needed to detect museum beacons.',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.settings),
                                  label: Text(
                                    _beaconService.isPermissionPermanentlyDenied
                                        ? 'Open App Settings'
                                        : 'Grant Permissions',
                                  ),
                                  onPressed: () {
                                    if (_beaconService
                                        .isPermissionPermanentlyDenied) {
                                      _beaconService.openSettings();
                                    } else {
                                      _beaconService.requestPermissions();
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 2. Bluetooth Disabled Banner
                      if (!_beaconService.isBluetoothOn)
                        Card(
                          color: Colors.orange.shade900.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                                color: Colors.orangeAccent, width: 1.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.bluetooth_disabled,
                                        color: Colors.orangeAccent),
                                    SizedBox(width: 8),
                                    Text(
                                      'Bluetooth is Turned Off',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orangeAccent),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Bluetooth must be enabled to discover nearby exhibits and beacons.',
                                  style: TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.bluetooth),
                                  label: const Text('Turn On Bluetooth'),
                                  onPressed: _beaconService.turnOnBluetooth,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 3. Fast Exhibit Detection Tuning (Threshold, Hysteresis, Lead Time, Cooldown)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.tune, size: 18, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text(
                                    'Fast Detection & Switching Controls',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Slider 1: RSSI Threshold (-100 to -40 dBm, default -55)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('RSSI Threshold',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                      '${_detector.config.thresholdDbm.toInt()} dBm',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amberAccent)),
                                ],
                              ),
                              Slider(
                                value: _detector.config.thresholdDbm,
                                min: -100.0,
                                max: -40.0,
                                divisions: 60,
                                label:
                                    '${_detector.config.thresholdDbm.toInt()} dBm',
                                onChanged: (val) =>
                                    _detector.setThreshold(val),
                              ),

                              // Slider 2: Very Near Override (-70 to -30 dBm, default -45)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Very Near Override',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                      '${_detector.config.nearOverrideDbm.toInt()} dBm',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.cyanAccent)),
                                ],
                              ),
                              Slider(
                                value: _detector.config.nearOverrideDbm,
                                min: -70.0,
                                max: -30.0,
                                divisions: 40,
                                activeColor: Colors.cyanAccent,
                                label:
                                    '${_detector.config.nearOverrideDbm.toInt()} dBm',
                                onChanged: (val) =>
                                    _detector.setNearOverride(val),
                              ),

                              // Slider 3: Hysteresis (0 to 8 dB, default 3 dB)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Hysteresis',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                      '${_detector.config.hysteresisDb.toStringAsFixed(1)} dB',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amberAccent)),
                                ],
                              ),
                              Slider(
                                value: _detector.config.hysteresisDb,
                                min: 0.0,
                                max: 12.0,
                                divisions: 24,
                                label:
                                    '${_detector.config.hysteresisDb.toStringAsFixed(1)} dB',
                                onChanged: (val) =>
                                    _detector.setHysteresis(val),
                              ),

                              // Slider 4: Lead Time (0 to 3000 ms, default 0 ms)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Lead Time',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text('${_detector.config.leadTimeMs} ms',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amberAccent)),
                                ],
                              ),
                              Slider(
                                value: _detector.config.leadTimeMs.toDouble(),
                                min: 0.0,
                                max: 3000.0,
                                divisions: 30,
                                label: '${_detector.config.leadTimeMs} ms',
                                onChanged: (val) =>
                                    _detector.setLeadTime(val.toInt()),
                              ),

                              // Slider 5: Cooldown (0 to 20 s, default 5 s)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Same-Exhibit Cooldown',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  Text(
                                      '${(_detector.config.cooldownMs / 1000).toInt()} s',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amberAccent)),
                                ],
                              ),
                              Slider(
                                value: (_detector.config.cooldownMs / 1000)
                                    .toDouble(),
                                min: 0.0,
                                max: 20.0,
                                divisions: 20,
                                label:
                                    '${(_detector.config.cooldownMs / 1000).toInt()} s',
                                onChanged: (val) => _detector
                                    .setCooldown((val * 1000).toInt()),
                              ),

                              const SizedBox(height: 8),

                              // 7. Status Line showing current leader, average, how long it has led, cooldown remaining
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color:
                                          Colors.amber.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.radar,
                                        size: 16, color: Colors.amberAccent),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _detector.statusLine,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontFamily: 'monospace',
                                          color: Colors.amberAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Active Subscriptions & Tour State Diagnostics
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.cyanAccent
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'ACTIVE SUBSCRIPTIONS',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_beaconService.activeSubscriptionCount} stream(s)',
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.cyanAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: _detector.tourActive
                                                ? Colors.greenAccent
                                                    .withValues(alpha: 0.3)
                                                : Colors.orangeAccent
                                                    .withValues(alpha: 0.3)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'TOUR ACTIVE FLAG',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _detector.tourActive
                                                ? 'ACTIVE'
                                                : 'STOPPED',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: _detector.tourActive
                                                  ? Colors.greenAccent
                                                  : Colors.orangeAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. Known Beacons Real-Time Diagnostics
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.analytics_outlined,
                                      size: 18, color: Colors.cyanAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    'Known Beacons Real-Time Diagnostics',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Readings/sec (10s), time since last packet, raw RSSI, and EMA (α=0.6). Beacons >2s stale drop out of contention.',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 10),
                              ...allExhibits.map((exhibit) {
                                final now = DateTime.now();
                                final rps = _detector.getReadingsPerSecond(
                                    exhibit.id,
                                    now: now);
                                final msSince = _detector.getMsSinceLastReading(
                                    exhibit.id,
                                    now: now);
                                final rawRssi =
                                    _detector.getLatestRawRssi(exhibit.id);
                                final smoothed =
                                    _detector.getSmoothedRssi(exhibit.id);

                                final bool hasReading = msSince != null;
                                final bool isStale = hasReading &&
                                    msSince > _detector.config.outOfRangeMs;
                                final bool isVeryNear = smoothed != null &&
                                    smoothed >=
                                        _detector.config.nearOverrideDbm;
                                final bool isInRange = smoothed != null &&
                                    smoothed >=
                                        _detector.config.thresholdDbm &&
                                    !isStale;

                                Color statusColor = Colors.grey;
                                String statusText = 'NO PACKET';
                                if (hasReading) {
                                  if (isVeryNear && !isStale) {
                                    statusColor = Colors.cyanAccent;
                                    statusText = 'VERY NEAR';
                                  } else if (isInRange) {
                                    statusColor = Colors.greenAccent;
                                    statusText = 'IN RANGE';
                                  } else if (isStale) {
                                    statusColor = Colors.orangeAccent;
                                    statusText = 'STALE (>2s)';
                                  } else {
                                    statusColor = Colors.redAccent;
                                    statusText = 'BELOW THRESH';
                                  }
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isInRange
                                          ? Colors.amber.withValues(alpha: 0.5)
                                          : Colors.white12,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              exhibit.title,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13.5),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: statusColor
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              border: Border.all(
                                                  color: statusColor,
                                                  width: 0.8),
                                            ),
                                            child: Text(
                                              statusText,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: statusColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        'MAC: ${exhibit.mac}',
                                        style: const TextStyle(
                                            fontSize: 10.5,
                                            fontFamily: 'monospace',
                                            color: Colors.grey),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _MetricBadge(
                                              label: 'Rate (10s)',
                                              value:
                                                  '${rps.toStringAsFixed(1)} rx/s',
                                              color: rps > 0
                                                  ? Colors.greenAccent
                                                  : Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _MetricBadge(
                                              label: 'Age',
                                              value: msSince == null
                                                  ? 'Never'
                                                  : '${msSince}ms',
                                              color: (msSince != null &&
                                                      msSince <=
                                                          _detector.config
                                                              .outOfRangeMs)
                                                  ? Colors.greenAccent
                                                  : Colors.orangeAccent,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _MetricBadge(
                                              label: 'Raw',
                                              value: rawRssi == null
                                                  ? 'N/A'
                                                  : '$rawRssi dBm',
                                              color: Colors.amberAccent,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: _MetricBadge(
                                              label: 'Smoothed',
                                              value: smoothed == null
                                                  ? 'N/A'
                                                  : '${smoothed.toStringAsFixed(1)} dBm',
                                              color: Colors.cyanAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      // 5. Detector Decisions Log (Last 10)
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.history,
                                          size: 18, color: Colors.amberAccent),
                                      SizedBox(width: 8),
                                      Text(
                                        'Detector Decisions Log (Last 15)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '${_detector.decisionLog.length}/15',
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        icon: const Icon(Icons.copy,
                                            size: 16, color: Colors.amberAccent),
                                        tooltip: 'Copy Log',
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(4),
                                        onPressed: () {
                                          final logText = _detector.decisionLog
                                              .map((d) =>
                                                  '${d.timeFormatted} - ${d.reason}')
                                              .join('\n');
                                          Clipboard.setData(
                                              ClipboardData(text: logText));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Decision log copied to clipboard'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (_detector.decisionLog.isEmpty)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'No decisions recorded yet. BLE scanning is active.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                )
                              else
                                ..._detector.decisionLog.map((decision) {
                                  final isSwitch = decision.isSwitch;
                                  final isBlocked =
                                      decision.reason.startsWith('blocked');
                                  final isWarning =
                                      decision.reason.startsWith('warning');
                                  final Color iconColor = isSwitch
                                      ? Colors.greenAccent
                                      : (isWarning
                                          ? Colors.yellowAccent
                                          : (isBlocked
                                              ? Colors.orangeAccent
                                              : Colors.lightBlueAccent));
                                  final IconData icon = isSwitch
                                      ? Icons.swap_horiz
                                      : (isWarning
                                          ? Icons.warning_amber
                                          : (isBlocked
                                              ? Icons.block
                                              : Icons.info_outline));

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSwitch
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.white
                                              .withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSwitch
                                            ? Colors.greenAccent
                                                .withValues(alpha: 0.4)
                                            : Colors.white10,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(icon, size: 14, color: iconColor),
                                        const SizedBox(width: 6),
                                        Text(
                                          decision.timeFormatted,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontFamily: 'monospace',
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            decision.reason,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontFamily: 'monospace',
                                              fontWeight: isSwitch
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isSwitch
                                                  ? Colors.greenAccent
                                                  : (isBlocked
                                                      ? Colors.orange.shade200
                                                      : Colors.white),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ),

                      // 6. Simulate Exhibit List
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.science_outlined,
                                      size: 20, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text(
                                    'Simulate Exhibit (Open without BLE)',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap any exhibit below to preview the screen, audio narration, and video without requiring physical beacons.',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade400),
                              ),
                              const SizedBox(height: 10),
                              ...allExhibits.map((exhibit) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.amber.shade900
                                          .withValues(alpha: 0.4),
                                      child: const Icon(Icons.museum,
                                          color: Colors.amberAccent, size: 20),
                                    ),
                                    title: Text(
                                      exhibit.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    subtitle: Text(
                                      'MAC: ${exhibit.mac}\nMedia: ${exhibit.audioAsset != null ? "Audio ✓" : "No audio"} | ${exhibit.videoAsset != null ? "Video ✓" : "No video"}',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                    trailing: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                      ),
                                      icon: const Icon(Icons.launch, size: 14),
                                      label: const Text('Open',
                                          style: TextStyle(fontSize: 12)),
                                      onPressed: () {
                                        _beaconService.simulateExhibit(exhibit);
                                        ExhibitNavigator.openExhibit(exhibit,
                                            isAutomatic: false);
                                      },
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),

                      // 5. Scan Status & Toggle: Show Known Only vs Show All (Top 15)
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              if (_beaconService.isScanning)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              else
                                const Icon(Icons.circle,
                                    size: 12, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _showAllDevices
                                          ? 'Showing Top 15 of ${_beaconService.totalDevicesCount} devices'
                                          : 'Showing Known Beacons (${_beaconService.knownBeaconsCount})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    Text(
                                      _beaconService.statusMessage,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              FilterChip(
                                selected: _showAllDevices,
                                label: const Text('Show all devices'),
                                onSelected: (val) {
                                  setState(() {
                                    _showAllDevices = val;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Devices List with ListView.builder / SliverList.builder & Stable Keys
              if (displayDevices.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          _showAllDevices
                              ? Icons.bluetooth_searching
                              : Icons.star_border,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _showAllDevices
                              ? (_beaconService.isScanning
                                  ? 'Scanning for nearby BLE devices...\n(Throttled UI updates every 500ms)'
                                  : 'No devices found.\nTap play to start scanning.')
                              : 'No known museum beacons detected.\n(Looking for MAC: 53:1A:7A:82:B4:83, 76:06:07:E1:A8:C3, or B5:3A:0C:BA:70:97)\nToggle "Show all devices" to inspect all nearby BLE devices.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  sliver: SliverList.builder(
                    itemCount: displayDevices.length,
                    itemBuilder: (context, index) {
                      final device = displayDevices[index];
                      // 3. Rebuild only changed cards using stable keys per device MAC
                      return DeviceCard(
                        key: ValueKey(device.remoteId),
                        device: device,
                      );
                    },
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Standalone Device Card with const sub-widgets and stable ValueKey
class DeviceCard extends StatelessWidget {
  final DiscoveredDevice device;

  const DeviceCard({
    required super.key,
    required this.device,
  });

  Color _getRssiColor(int rssi) {
    if (rssi >= -65) return Colors.green;
    if (rssi >= -80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final isKnown = device.isKnownBeacon;
    final rssiColor = _getRssiColor(device.rssi);

    return Card(
      elevation: isKnown ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: isKnown ? Colors.amber.shade900.withValues(alpha: 0.15) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isKnown ? Colors.amber : Colors.grey.withValues(alpha: 0.2),
          width: isKnown ? 2.0 : 1.0,
        ),
      ),
      child: ExpansionTile(
        key: PageStorageKey('tile_${device.remoteId}'),
        initiallyExpanded: isKnown,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            if (isKnown) ...[
              const Icon(Icons.star, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isKnown)
                    Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '★ KNOWN: ${device.matchedExhibit!.title.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  Text(
                    device.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isKnown ? Colors.amberAccent : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'MAC: ${device.remoteId}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: rssiColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: rssiColor, width: 1),
                  ),
                  child: Text(
                    '${device.rssi} dBm',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: rssiColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'avg: ${device.smoothedRssi.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (device.parsedUuids.isNotEmpty) ...[
                const Text(
                  'Detected UUIDs (Service / iBeacon):',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                ...device.parsedUuids.map((uuid) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tag,
                          size: 14,
                          color: Colors.cyanAccent,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SelectableText(
                            uuid,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else
                const Text(
                  'No beacon UUID detected',
                  style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey),
                ),
            ],
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Raw Manufacturer Data (Hex):',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent),
                ),
                SelectableText(
                  device.rawManufacturerDataHex,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Raw Advertised Service UUIDs (Hex/GUID):',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent),
                ),
                SelectableText(
                  device.rawServiceUuidsHex,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
                if (device.rawServiceData.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Raw Service Data (Hex):',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.cyanAccent),
                  ),
                  SelectableText(
                    device.rawServiceDataHex,
                    style:
                        const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  'Last seen: ${device.lastSeen.hour.toString().padLeft(2, '0')}:${device.lastSeen.minute.toString().padLeft(2, '0')}:${device.lastSeen.second.toString().padLeft(2, '0')} (History: ${device.rssiHistory.join(", ")} dBm)',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (isKnown) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text('Open ${device.matchedExhibit!.title} Page'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ExhibitScreen(exhibit: device.matchedExhibit!),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
