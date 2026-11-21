import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../data/exhibits.dart';
import '../screens/arrival_banner.dart';
import '../screens/exhibit_screen.dart';

class DetectorConfig {
  final double alpha;
  final int outOfRangeMs;
  final double hysteresisDb;
  final int leadTimeMs;
  final int cooldownMs;
  final double thresholdDbm;
  final double nearOverrideDbm;

  const DetectorConfig({
    this.alpha = 0.7,
    this.outOfRangeMs = 1500,
    this.hysteresisDb = 7.0,
    this.leadTimeMs = 600,
    this.cooldownMs = 5000,
    this.thresholdDbm = -55.0,
    this.nearOverrideDbm = -45.0,
  });

  DetectorConfig copyWith({
    double? alpha,
    int? outOfRangeMs,
    double? hysteresisDb,
    int? leadTimeMs,
    int? cooldownMs,
    double? thresholdDbm,
    double? nearOverrideDbm,
  }) {
    return DetectorConfig(
      alpha: alpha ?? this.alpha,
      outOfRangeMs: outOfRangeMs ?? this.outOfRangeMs,
      hysteresisDb: hysteresisDb ?? this.hysteresisDb,
      leadTimeMs: leadTimeMs ?? this.leadTimeMs,
      cooldownMs: cooldownMs ?? this.cooldownMs,
      thresholdDbm: thresholdDbm ?? this.thresholdDbm,
      nearOverrideDbm: nearOverrideDbm ?? this.nearOverrideDbm,
    );
  }
}

class BeaconReading {
  final int rssi;
  final DateTime timestamp;

  const BeaconReading(this.rssi, this.timestamp);
}

class BeaconTracker {
  final Exhibit exhibit;
  int? latestRawRssi;
  DateTime? lastSeen;
  final List<BeaconReading> _readings = [];

  BeaconTracker({required this.exhibit, this.lastSeen});

  /// Ingest reading. Prunes readings older than 10 seconds.
  void addReading(int rssi, DateTime timestamp, {double? alpha}) {
    lastSeen = timestamp;
    latestRawRssi = rssi;
    _readings.add(BeaconReading(rssi, timestamp));
    _pruneOldReadings(timestamp);
  }

  void _pruneOldReadings(DateTime now) {
    final cutoff = now.subtract(const Duration(seconds: 10));
    _readings.removeWhere((r) => r.timestamp.isBefore(cutoff));
  }

  /// Calculates the median RSSI of readings within the last 1000 ms.
  /// If fewer than 3 readings exist in the window, uses the newest reading.
  /// If no readings exist in the window, falls back to latestRawRssi.
  double? getMedianRssi({DateTime? now}) {
    if (_readings.isEmpty) return latestRawRssi?.toDouble();
    final current = now ?? DateTime.now();
    final cutoff = current.subtract(const Duration(milliseconds: 1000));
    final recent = _readings
        .where((r) =>
            !r.timestamp.isBefore(cutoff) && !r.timestamp.isAfter(current))
        .toList();

    if (recent.isEmpty) {
      return latestRawRssi?.toDouble();
    }
    if (recent.length < 3) {
      return recent.last.rssi.toDouble();
    }
    final values = recent.map((r) => r.rssi).toList()..sort();
    final mid = values.length ~/ 2;
    if (values.length.isOdd) {
      return values[mid].toDouble();
    } else {
      return (values[mid - 1] + values[mid]) / 2.0;
    }
  }

  double? get smoothedRssi => getMedianRssi();

  /// Count of readings above [thresholdDbm] in the last [windowMs] milliseconds.
  int countReadingsAboveThreshold(DateTime now,
      {required double thresholdDbm, required int windowMs}) {
    final cutoff = now.subtract(Duration(milliseconds: windowMs));
    return _readings
        .where((r) =>
            !r.timestamp.isBefore(cutoff) &&
            !r.timestamp.isAfter(now) &&
            r.rssi >= thresholdDbm)
        .length;
  }

  /// Checks if the last [count] readings are all >= [overrideLevelDbm].
  bool hasConsecutiveReadingsAbove(int count, double overrideLevelDbm) {
    if (_readings.length < count) return false;
    for (int i = _readings.length - count; i < _readings.length; i++) {
      if (_readings[i].rssi < overrideLevelDbm) return false;
    }
    return true;
  }

  /// Readings per second over the last 10 seconds
  double getReadingsPerSecond(DateTime now) {
    _pruneOldReadings(now);
    return _readings.length / 10.0;
  }

  /// Milliseconds since the last new reading
  int? getMsSinceLastReading(DateTime now) {
    if (lastSeen == null) return null;
    return now.difference(lastSeen!).inMilliseconds;
  }

  /// A beacon with newest reading under outOfRangeMs (default 1500 ms) is counted
  bool isSeenRecently(DateTime now, {required int outOfRangeMs}) {
    if (lastSeen == null) return false;
    return now.difference(lastSeen!).inMilliseconds < outOfRangeMs;
  }

  void reset() {
    latestRawRssi = null;
    lastSeen = null;
    _readings.clear();
  }
}

class DetectorDecision {
  final DateTime timestamp;
  final String reason;
  final bool isSwitch;

  const DetectorDecision({
    required this.timestamp,
    required this.reason,
    this.isSwitch = false,
  });

  String get timeFormatted {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = (timestamp.millisecond ~/ 100).toString();
    return '$h:$m:$s.$ms';
  }
}

class BeaconDetector extends ChangeNotifier {
  static final BeaconDetector instance = BeaconDetector._internal();

  BeaconDetector._internal() {
    _initTrackers();
    loadSettings();
  }

  static const String _prefThresholdKey = 'beacon_rssi_threshold';
  static const String _prefNearOverrideKey = 'beacon_near_override_dbm';
  static const String _prefHysteresisKey = 'beacon_hysteresis_db';
  static const String _prefLeadTimeKey = 'beacon_lead_time_ms';
  static const String _prefCooldownKey = 'beacon_cooldown_ms';
  static const String _prefVibrationKey = 'beacon_vibration_enabled';

  DetectorConfig _config = const DetectorConfig();
  DetectorConfig get config => _config;
  double get threshold => _config.thresholdDbm;

  // Single source of truth for tour active status
  bool _tourActive = false;
  bool get tourActive => _tourActive;

  void setTourActive(bool active) {
    if (_tourActive == active) return;
    _tourActive = active;
    if (!active) {
      resetAll();
      ExhibitScreen.stopAllMedia();
      ArrivalBanner.dismiss();
    }
    notifyListeners();
  }

  void resetAll() {
    for (final tracker in _trackers.values) {
      tracker.reset();
    }
    _currentlyOpenExhibit = null;
    _currentLeader = null;
    _currentLeaderAvg = null;
    _leadingExhibitId = null;
    _leadStartTime = null;
    _currentLeadDurationMs = 0;
    _closedTimestamps.clear();
    _cooldownRemainingMs = 0;
    notifyListeners();
  }

  void logBleSubscriptionEvent(String message) {
    _logDecision('subscription: $message', timestamp: DateTime.now());
  }

  bool _vibrationEnabled = true;
  bool get vibrationEnabled => _vibrationEnabled;

  final Map<String, BeaconTracker> _trackers = {}; // key: exhibit.id
  final Map<String, DateTime> _closedTimestamps = {}; // key: exhibit.id
  final List<DetectorDecision> _decisionLog = [];

  List<DetectorDecision> get decisionLog => List.unmodifiable(_decisionLog);

  Exhibit? _currentlyOpenExhibit;
  Exhibit? get currentlyOpenExhibit => _currentlyOpenExhibit;

  // Leader & switching state
  String? _leadingExhibitId;
  String? get leadingExhibitId => _leadingExhibitId;
  DateTime? _leadStartTime;
  int _currentLeadDurationMs = 0;

  Exhibit? _currentLeader;
  Exhibit? get currentLeader => _currentLeader;

  double? _currentLeaderAvg;
  double? get currentLeaderAvg => _currentLeaderAvg;

  int _cooldownRemainingMs = 0;
  int get cooldownRemainingMs => _cooldownRemainingMs;
  int get cooldownRemainingSeconds => (_cooldownRemainingMs / 1000).ceil();

  // Navigation callback
  Future<void> Function(Exhibit exhibit)? onNavigateToExhibit;

  void _initTrackers() {
    for (final exhibit in allExhibits) {
      _trackers[exhibit.id] = BeaconTracker(exhibit: exhibit);
    }
  }

  void _logDecision(String reason,
      {required DateTime timestamp, bool isSwitch = false}) {
    if (_decisionLog.isNotEmpty) {
      final last = _decisionLog.first;
      if (last.reason == reason &&
          timestamp.difference(last.timestamp).inMilliseconds < 1500) {
        return; // Avoid spamming duplicate consecutive decisions
      }
    }
    _decisionLog.insert(
      0,
      DetectorDecision(
        timestamp: timestamp,
        reason: reason,
        isSwitch: isSwitch,
      ),
    );
    if (_decisionLog.length > 15) {
      _decisionLog.removeLast();
    }
  }

  void logWarning(String message, {DateTime? timestamp}) {
    _logDecision('warning: $message', timestamp: timestamp ?? DateTime.now());
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final threshold = prefs.getDouble(_prefThresholdKey);
      final nearOverride = prefs.getDouble(_prefNearOverrideKey);
      final hysteresis = prefs.getDouble(_prefHysteresisKey);
      final leadTime = prefs.getInt(_prefLeadTimeKey);
      final cooldown = prefs.getInt(_prefCooldownKey);
      final vibration = prefs.getBool(_prefVibrationKey);

      if (vibration != null) {
        _vibrationEnabled = vibration;
      }

      _config = _config.copyWith(
        thresholdDbm: threshold,
        nearOverrideDbm: nearOverride,
        hysteresisDb: hysteresis,
        leadTimeMs: leadTime,
        cooldownMs: cooldown,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('BeaconDetector: Error loading settings: $e');
    }
  }

  Future<void> setThreshold(double value) async {
    _config = _config.copyWith(thresholdDbm: value);
    notifyListeners();
    _saveDouble(_prefThresholdKey, value);
  }

  Future<void> setNearOverride(double value) async {
    _config = _config.copyWith(nearOverrideDbm: value);
    notifyListeners();
    _saveDouble(_prefNearOverrideKey, value);
  }

  Future<void> setHysteresis(double value) async {
    _config = _config.copyWith(hysteresisDb: value);
    notifyListeners();
    _saveDouble(_prefHysteresisKey, value);
  }

  Future<void> setLeadTime(int value) async {
    _config = _config.copyWith(leadTimeMs: value);
    notifyListeners();
    _saveInt(_prefLeadTimeKey, value);
  }

  Future<void> setCooldown(int value) async {
    _config = _config.copyWith(cooldownMs: value);
    notifyListeners();
    _saveInt(_prefCooldownKey, value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefVibrationKey, value);
    } catch (_) {}
  }

  void _saveDouble(String key, double val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, val);
    } catch (_) {}
  }

  void _saveInt(String key, int val) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, val);
    } catch (_) {}
  }

  void onExhibitOpened(Exhibit exhibit) {
    _currentlyOpenExhibit = exhibit;
    _leadingExhibitId = null;
    _leadStartTime = null;
    _currentLeadDurationMs = 0;
    notifyListeners();
  }

  void onExhibitClosed(String exhibitId, {DateTime? timestamp}) {
    final now = timestamp ?? DateTime.now();
    _closedTimestamps[exhibitId] = now;
    if (_currentlyOpenExhibit?.id == exhibitId) {
      _currentlyOpenExhibit = null;
    }
    _leadingExhibitId = null;
    _leadStartTime = null;
    _currentLeadDurationMs = 0;
    _updateCooldown(now);
    notifyListeners();
  }

  /// Ingest scan reading: evaluate beacon triggers on every scan result
  void processReading(String mac, int rssi, {DateTime? timestamp}) {
    if (!_tourActive) return; // Ignore all input when tour is stopped
    final now = timestamp ?? DateTime.now();
    final exhibit = findExhibitByMac(mac);
    if (exhibit == null) return; // Only consider known beacons

    final tracker = _trackers.putIfAbsent(
      exhibit.id,
      () => BeaconTracker(exhibit: exhibit, lastSeen: now),
    );
    tracker.addReading(rssi, now, alpha: _config.alpha);

    evaluate(timestamp: now);
  }

  void tick({DateTime? timestamp}) {
    if (!_tourActive) return; // Ignore all input when tour is stopped
    evaluate(timestamp: timestamp);
  }

  void evaluate({DateTime? timestamp}) {
    if (!_tourActive) return; // Never evaluate or navigate when tour is stopped
    final now = timestamp ?? DateTime.now();
    _updateCooldown(now);

    // 1. In-range beacons: newest reading under outOfRangeMs (1500 ms) and median >= threshold
    final inRangeTrackers = <BeaconTracker>[];
    for (final tracker in _trackers.values) {
      if (tracker.isSeenRecently(now, outOfRangeMs: _config.outOfRangeMs)) {
        final median = tracker.getMedianRssi(now: now);
        if (median != null && median >= _config.thresholdDbm) {
          inRangeTrackers.add(tracker);
        }
      }
    }

    if (inRangeTrackers.isEmpty) {
      if (_currentLeader != null) {
        _logDecision('blocked: stale reading (>1.5s)', timestamp: now);
      }
      _currentLeader = null;
      _currentLeaderAvg = null;
      _leadingExhibitId = null;
      _leadStartTime = null;
      _currentLeadDurationMs = 0;
      notifyListeners();
      return;
    }

    // 2. Case A: Opening the first exhibit (none open)
    // Require at least 2 readings above the threshold within 800 ms from the same beacon,
    // and that this beacon has the strongest median. No single-reading opens.
    if (_currentlyOpenExhibit == null) {
      final openingCandidates = <BeaconTracker>[];
      for (final tracker in inRangeTrackers) {
        if (tracker.countReadingsAboveThreshold(
              now,
              thresholdDbm: _config.thresholdDbm,
              windowMs: 800,
            ) >=
            2) {
          openingCandidates.add(tracker);
        }
      }

      if (openingCandidates.isEmpty) {
        // No beacon has >= 2 readings above threshold in 800 ms -> do not open
        inRangeTrackers.sort((a, b) => (b.getMedianRssi(now: now) ?? -999.0)
            .compareTo(a.getMedianRssi(now: now) ?? -999.0));
        _currentLeader = inRangeTrackers.first.exhibit;
        _currentLeaderAvg = inRangeTrackers.first.getMedianRssi(now: now);
        _leadingExhibitId = null;
        _leadStartTime = null;
        _currentLeadDurationMs = 0;
        notifyListeners();
        return;
      }

      // Strongest median among qualified opening candidates wins
      openingCandidates.sort((a, b) => (b.getMedianRssi(now: now) ?? -999.0)
          .compareTo(a.getMedianRssi(now: now) ?? -999.0));

      final topTracker = openingCandidates.first;
      final topCandidate = topTracker.exhibit;
      final topMedian = topTracker.getMedianRssi(now: now)!;

      _currentLeader = topCandidate;
      _currentLeaderAvg = topMedian;

      // Same-exhibit cooldown: default 5000 ms after closing
      final closedAt = _closedTimestamps[topCandidate.id];
      if (closedAt != null) {
        final elapsedMs = now.difference(closedAt).inMilliseconds;
        if (elapsedMs < _config.cooldownMs) {
          final remainingSec = (_config.cooldownMs - elapsedMs) / 1000.0;
          _logDecision(
            'blocked cooldown: ${topCandidate.title} (${remainingSec.toStringAsFixed(1)}s remaining)',
            timestamp: now,
          );
          _leadingExhibitId = null;
          _leadStartTime = null;
          _currentLeadDurationMs = 0;
          notifyListeners();
          return;
        }
      }

      // Trigger open
      final reason =
          'open ${topCandidate.title}: median ${topMedian.toStringAsFixed(1)} dBm (2+ readings >= ${_config.thresholdDbm.toInt()} dBm in 800ms)';
      _logDecision(reason, timestamp: now, isSwitch: true);
      _leadingExhibitId = null;
      _leadStartTime = null;
      _currentLeadDurationMs = 0;
      _triggerExhibit(topCandidate);
      notifyListeners();
      return;
    }

    // 3. Case B & C: Switching while an exhibit is open
    final openExhibit = _currentlyOpenExhibit!;
    final openTracker = _trackers[openExhibit.id];
    final double openMedian = (openTracker != null &&
            openTracker.isSeenRecently(now,
                outOfRangeMs: _config.outOfRangeMs))
        ? (openTracker.getMedianRssi(now: now) ?? -999.0)
        : -999.0;

    // Candidate beacons to switch to (must be different from open exhibit)
    final switchCandidates = inRangeTrackers
        .where((t) => t.exhibit.id != openExhibit.id)
        .toList();

    if (switchCandidates.isEmpty) {
      // Open exhibit is the only one in range (or others are out of range / below threshold)
      _currentLeader = openExhibit;
      _currentLeaderAvg = openMedian > -900 ? openMedian : null;
      if (_leadingExhibitId != null) {
        // Lead broken
        _leadingExhibitId = null;
        _leadStartTime = null;
        _currentLeadDurationMs = 0;
      }
      notifyListeners();
      return;
    }

    // Strongest candidate beacon by median
    switchCandidates.sort((a, b) => (b.getMedianRssi(now: now) ?? -999.0)
        .compareTo(a.getMedianRssi(now: now) ?? -999.0));

    final topTracker = switchCandidates.first;
    final topCandidate = topTracker.exhibit;
    final topMedian = topTracker.getMedianRssi(now: now)!;
    final delta = topMedian - openMedian;

    _currentLeader = topCandidate;
    _currentLeaderAvg = topMedian;

    // Check cooldown on switch candidate
    final closedAt = _closedTimestamps[topCandidate.id];
    if (closedAt != null) {
      final elapsedMs = now.difference(closedAt).inMilliseconds;
      if (elapsedMs < _config.cooldownMs) {
        _logDecision(
          'blocked cooldown: ${topCandidate.title} (${topMedian.toStringAsFixed(1)} dBm) vs ${openExhibit.title} (${openMedian.toStringAsFixed(1)} dBm) | lead: ${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)} dB | led: 0ms',
          timestamp: now,
        );
        _leadingExhibitId = null;
        _leadStartTime = null;
        _currentLeadDurationMs = 0;
        notifyListeners();
        return;
      }
    }

    // Very Near Override:
    // Require 2 consecutive readings above override level from that beacon,
    // and a median lead of at least 3 dB.
    final isVeryNearOverride =
        topTracker.hasConsecutiveReadingsAbove(2, _config.nearOverrideDbm) &&
            delta >= 3.0;

    if (isVeryNearOverride) {
      _logDecision(
        'switch near override: ${topCandidate.title} (${topMedian.toStringAsFixed(1)} dBm) vs ${openExhibit.title} (${openMedian.toStringAsFixed(1)} dBm) | lead: +${delta.toStringAsFixed(1)} dB | led: 0ms',
        timestamp: now,
        isSwitch: true,
      );
      _leadingExhibitId = null;
      _leadStartTime = null;
      _currentLeadDurationMs = 0;
      _triggerExhibit(topCandidate);
      notifyListeners();
      return;
    }

    // Normal switching:
    // New leader's median must beat open exhibit's beacon median by at least hysteresis (default 7 dB)
    // for a continuous lead time (default 600 ms).
    // If the lead breaks, reset the timer.
    final isStrongerByHysteresis = delta >= _config.hysteresisDb;

    if (!isStrongerByHysteresis) {
      // Lead broke or not strong enough! Reset lead timer.
      _leadingExhibitId = null;
      _leadStartTime = null;
      _currentLeadDurationMs = 0;
      _logDecision(
        'blocked hysteresis: ${topCandidate.title} (${topMedian.toStringAsFixed(1)} dBm) vs ${openExhibit.title} (${openMedian.toStringAsFixed(1)} dBm) | lead: ${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)} dB | led: 0ms',
        timestamp: now,
      );
      notifyListeners();
      return;
    }

    // Delta >= hysteresisDb: check continuous lead time
    if (_config.leadTimeMs <= 0) {
      // Immediate switch
      _logDecision(
        'switch: ${topCandidate.title} (${topMedian.toStringAsFixed(1)} dBm) vs ${openExhibit.title} (${openMedian.toStringAsFixed(1)} dBm) | lead: +${delta.toStringAsFixed(1)} dB | led: 0ms',
        timestamp: now,
        isSwitch: true,
      );
      _leadingExhibitId = null;
      _leadStartTime = null;
      _currentLeadDurationMs = 0;
      _triggerExhibit(topCandidate);
      notifyListeners();
      return;
    }

    if (_leadingExhibitId == topCandidate.id && _leadStartTime != null) {
      final leadMs = now.difference(_leadStartTime!).inMilliseconds;
      _currentLeadDurationMs = leadMs;
      if (leadMs >= _config.leadTimeMs) {
        _logDecision(
          'switch: ${topCandidate.title} (${topMedian.toStringAsFixed(1)} dBm) vs ${openExhibit.title} (${openMedian.toStringAsFixed(1)} dBm) | lead: +${delta.toStringAsFixed(1)} dB | led: ${leadMs}ms',
          timestamp: now,
          isSwitch: true,
        );
        _leadingExhibitId = null;
        _leadStartTime = null;
        _currentLeadDurationMs = 0;
        _triggerExhibit(topCandidate);
        notifyListeners();
        return;
      } else {
        _logDecision(
          'leading: ${topCandidate.title} (${topMedian.toStringAsFixed(1)} dBm) vs ${openExhibit.title} (${openMedian.toStringAsFixed(1)} dBm) | lead: +${delta.toStringAsFixed(1)} dB | led: ${leadMs}ms / ${_config.leadTimeMs}ms',
          timestamp: now,
        );
      }
    } else {
      // Leading started or candidate changed -> reset timer and start new lead
      _leadingExhibitId = topCandidate.id;
      _leadStartTime = now;
      _currentLeadDurationMs = 0;
      _logDecision(
        'leading: ${topCandidate.title} (${topMedian.toStringAsFixed(1)} dBm) vs ${openExhibit.title} (${openMedian.toStringAsFixed(1)} dBm) | lead: +${delta.toStringAsFixed(1)} dB | led: 0ms / ${_config.leadTimeMs}ms',
        timestamp: now,
      );
    }

    notifyListeners();
  }

  void _updateCooldown(DateTime now) {
    int maxRemainingMs = 0;
    for (final closedAt in _closedTimestamps.values) {
      final elapsedMs = now.difference(closedAt).inMilliseconds;
      if (elapsedMs < _config.cooldownMs) {
        final remaining = _config.cooldownMs - elapsedMs;
        if (remaining > maxRemainingMs) {
          maxRemainingMs = remaining;
        }
      }
    }
    _cooldownRemainingMs = maxRemainingMs;
  }

  void _triggerExhibit(Exhibit exhibit) {
    if (!_tourActive) return;
    _currentlyOpenExhibit = exhibit; // Set immediately to block duplicate opens
    onNavigateToExhibit?.call(exhibit);
    _vibrateShortPulse();
  }

  Future<void> _vibrateShortPulse() async {
    if (!_vibrationEnabled) return;
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 150);
      }
    } catch (_) {}
  }

  String get statusLine {
    final leaderStr = _currentLeader != null
        ? '${_currentLeader!.title} (${_currentLeaderAvg?.toStringAsFixed(1)} dBm)'
        : 'None (out of range)';

    final ledStr = _config.leadTimeMs <= 0
        ? (_currentLeader != null ? 'Immediate' : '0ms')
        : (_leadingExhibitId != null
            ? '${_currentLeadDurationMs}ms / ${_config.leadTimeMs}ms'
            : '0ms');

    final cooldownStr = _cooldownRemainingMs > 0
        ? '${(_cooldownRemainingMs / 1000).toStringAsFixed(1)}s'
        : 'None';

    return 'Leader: $leaderStr | Led: $ledStr | Cooldown: $cooldownStr';
  }

  // Diagnostics helpers per known beacon
  double getReadingsPerSecond(String exhibitId, {DateTime? now}) {
    final tracker = _trackers[exhibitId];
    if (tracker == null) return 0.0;
    return tracker.getReadingsPerSecond(now ?? DateTime.now());
  }

  int? getMsSinceLastReading(String exhibitId, {DateTime? now}) {
    final tracker = _trackers[exhibitId];
    if (tracker == null) return null;
    return tracker.getMsSinceLastReading(now ?? DateTime.now());
  }

  int? getLatestRawRssi(String exhibitId) {
    return _trackers[exhibitId]?.latestRawRssi;
  }

  double? getMedianRssi(String exhibitId, {DateTime? now}) {
    return _trackers[exhibitId]?.getMedianRssi(now: now);
  }

  double? getSmoothedRssi(String exhibitId, {DateTime? now}) {
    return _trackers[exhibitId]?.getMedianRssi(now: now);
  }

  double? getBeaconAverage(String exhibitId, {DateTime? now}) {
    return _trackers[exhibitId]?.getMedianRssi(now: now);
  }

  BeaconTracker? getTracker(String exhibitId) => _trackers[exhibitId];

  void resetForTest() {
    _tourActive = true;
    for (final tracker in _trackers.values) {
      tracker.reset();
    }
    _closedTimestamps.clear();
    _decisionLog.clear();
    _currentlyOpenExhibit = null;
    _leadingExhibitId = null;
    _leadStartTime = null;
    _currentLeadDurationMs = 0;
    _currentLeader = null;
    _currentLeaderAvg = null;
    _cooldownRemainingMs = 0;
    _config = const DetectorConfig();
  }
}
