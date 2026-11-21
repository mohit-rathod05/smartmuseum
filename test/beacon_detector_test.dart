import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:museum_guide/data/exhibits.dart';
import 'package:museum_guide/services/beacon_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BeaconDetector detector;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    detector = BeaconDetector.instance;
    detector.resetForTest();
  });

  group('BeaconDetector Median, Opening, Switching, & Override Tests', () {
    test('1. Median smoothing ignores single spikes and uses newest when < 3 readings exist', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      // 1 reading: newest reading used (-50 dBm)
      detector.processReading('53:1A:7A:82:B4:83', -50, timestamp: t0);
      expect(detector.getBeaconAverage('exhibit_1', now: t0), equals(-50.0));

      // 2 readings: newest reading used (-48 dBm)
      final t1 = t0.add(const Duration(milliseconds: 200));
      detector.processReading('53:1A:7A:82:B4:83', -48, timestamp: t1);
      expect(detector.getBeaconAverage('exhibit_1', now: t1), equals(-48.0));

      // 3 readings with a SINGLE SPIKE: -20 dBm (spike)
      // Readings in last 1000ms: [-50, -48, -20]. Sorted: [-50, -48, -20]. Median = -48.0
      final t2 = t0.add(const Duration(milliseconds: 400));
      detector.processReading('53:1A:7A:82:B4:83', -20, timestamp: t2);
      expect(detector.getBeaconAverage('exhibit_1', now: t2), equals(-48.0));

      // 4 readings with another normal reading: -52 dBm
      // Readings in last 1000ms: [-50, -48, -20, -52]. Sorted: [-52, -50, -48, -20]. Median = (-50 + -48)/2 = -49.0
      final t3 = t0.add(const Duration(milliseconds: 600));
      detector.processReading('53:1A:7A:82:B4:83', -52, timestamp: t3);
      expect(detector.getBeaconAverage('exhibit_1', now: t3), equals(-49.0));

      // 5 readings: -50 dBm
      // Sorted: [-52, -50, -50, -48, -20]. Median = -50.0 (Spike at -20 is completely rejected!)
      final t4 = t0.add(const Duration(milliseconds: 800));
      detector.processReading('53:1A:7A:82:B4:83', -50, timestamp: t4);
      expect(detector.getBeaconAverage('exhibit_1', now: t4), equals(-50.0));
    });

    test('2. Default config parameters match spec', () {
      expect(detector.config.leadTimeMs, equals(600));
      expect(detector.config.hysteresisDb, equals(7.0));
      expect(detector.config.outOfRangeMs, equals(1500));
      expect(detector.config.thresholdDbm, equals(-55.0));
      expect(detector.config.nearOverrideDbm, equals(-45.0));
      expect(detector.config.cooldownMs, equals(5000));
    });

    test('3. Opening first exhibit: requires at least 2 readings above threshold within 800 ms; no single-reading opens', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      Exhibit? openedExhibit;
      detector.onNavigateToExhibit = (exhibit) async {
        openedExhibit = exhibit;
      };

      // Reading 1: -48 dBm (above -55 threshold)
      detector.processReading('53:1A:7A:82:B4:83', -48, timestamp: t0);
      // Single reading -> MUST NOT OPEN
      expect(openedExhibit, isNull);

      // Reading 2: at t0 + 200ms (within 800 ms): -46 dBm
      final t1 = t0.add(const Duration(milliseconds: 200));
      detector.processReading('53:1A:7A:82:B4:83', -46, timestamp: t1);

      // Now 2 readings above threshold within 800 ms -> OPENS!
      expect(openedExhibit?.id, equals('exhibit_1'));
      expect(detector.decisionLog.isNotEmpty, isTrue);
      expect(detector.decisionLog.first.reason, contains('open Entrance Gate'));
      expect(detector.decisionLog.first.reason, contains('2+ readings'));
    });

    test('4. Opening first exhibit: readings > 800 ms apart do not trigger open', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      Exhibit? openedExhibit;
      detector.onNavigateToExhibit = (exhibit) async {
        openedExhibit = exhibit;
      };

      // Reading 1 at t0
      detector.processReading('53:1A:7A:82:B4:83', -48, timestamp: t0);
      expect(openedExhibit, isNull);

      // Reading 2 at t0 + 900 ms (> 800 ms window)
      final t1 = t0.add(const Duration(milliseconds: 900));
      detector.processReading('53:1A:7A:82:B4:83', -48, timestamp: t1);

      // Only 1 reading within the 800 ms window -> does NOT open
      expect(openedExhibit, isNull);

      // Reading 3 at t0 + 1000 ms (100 ms after Reading 2, within 800 ms window)
      final t2 = t0.add(const Duration(milliseconds: 1000));
      detector.processReading('53:1A:7A:82:B4:83', -48, timestamp: t2);

      // Readings 2 and 3 are within 800 ms -> OPENS!
      expect(openedExhibit?.id, equals('exhibit_1'));
    });

    test('5. Opening first exhibit: beacon with strongest median wins when multiple qualify', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      Exhibit? openedExhibit;
      detector.onNavigateToExhibit = (exhibit) async {
        openedExhibit = exhibit;
      };

      // Beacon 1: two readings at -50 dBm
      detector.processReading('53:1A:7A:82:B4:83', -50, timestamp: t0);
      detector.processReading('53:1A:7A:82:B4:83', -50, timestamp: t0.add(const Duration(milliseconds: 100)));

      // Beacon 2: two readings at -40 dBm (stronger median)
      detector.processReading('76:06:07:E1:A8:C3', -40, timestamp: t0);
      detector.processReading('76:06:07:E1:A8:C3', -40, timestamp: t0.add(const Duration(milliseconds: 100)));

      // Beacon 2 has the stronger median (-40 > -50), so Beacon 2 opens!
      expect(openedExhibit?.id, equals('exhibit_2'));
    });

    test('6. Switching while open: candidate median must beat open exhibit by >= 7 dB hysteresis for continuous 600 ms lead time', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      Exhibit? switchedExhibit;
      detector.onNavigateToExhibit = (exhibit) async {
        switchedExhibit = exhibit;
      };

      // Open Exhibit 1 at -54 dBm (above -55 threshold)
      detector.processReading('53:1A:7A:82:B4:83', -54, timestamp: t0);
      detector.processReading('53:1A:7A:82:B4:83', -54, timestamp: t0.add(const Duration(milliseconds: 100)));
      expect(switchedExhibit?.id, equals('exhibit_1'));
      detector.onExhibitOpened(allExhibits[0]);

      // Exhibit 2 arrives with -49 dBm (Delta = -49 - (-54) = 5 dB < 7 dB hysteresis)
      switchedExhibit = null;
      final t1 = t0.add(const Duration(milliseconds: 200));
      detector.processReading('76:06:07:E1:A8:C3', -49, timestamp: t1);
      expect(switchedExhibit, isNull);
      expect(detector.decisionLog.first.reason, contains('blocked hysteresis'));
      expect(detector.decisionLog.first.reason, contains('vs Entrance Gate'));
      expect(detector.decisionLog.first.reason, contains('lead: +5.0 dB'));

      // Exhibit 2 arrives with -46 dBm (Delta = -46 - (-54) = 8 dB >= 7 dB hysteresis)
      // Note: -46 dBm is below near override level (-45.0 dBm), so normal lead time applies!
      final t2 = t0.add(const Duration(milliseconds: 300));
      detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t2);
      expect(switchedExhibit, isNull); // Must wait 600 ms lead time
      expect(detector.decisionLog.first.reason, contains('leading:'));
      expect(detector.decisionLog.first.reason, contains('0ms / 600ms'));

      // At t2 + 300 ms (< 600 ms lead time)
      final t3 = t2.add(const Duration(milliseconds: 300));
      detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t3);
      expect(switchedExhibit, isNull);

      // At t2 + 650 ms (>= 600 ms lead time)
      final t4 = t2.add(const Duration(milliseconds: 650));
      detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t4);
      expect(switchedExhibit?.id, equals('exhibit_2'));
      expect(detector.decisionLog.first.reason, contains('switch:'));
      expect(detector.decisionLog.first.reason, contains('led: 650ms'));
    });

    test('7. Lead timer reset: if candidate lead breaks, the timer resets to 0', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      Exhibit? switchedExhibit;
      detector.onNavigateToExhibit = (exhibit) async {
        switchedExhibit = exhibit;
      };

      // Open Exhibit 1 at -54 dBm
      detector.processReading('53:1A:7A:82:B4:83', -54, timestamp: t0);
      detector.processReading('53:1A:7A:82:B4:83', -54, timestamp: t0.add(const Duration(milliseconds: 100)));
      detector.onExhibitOpened(allExhibits[0]);

      // Exhibit 2 takes lead with -46 dBm (8 dB lead >= 7 dB, but < -45 dBm near override) at t1
      switchedExhibit = null;
      final t1 = t0.add(const Duration(milliseconds: 200));
      detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t1);

      // Lead time reaches 400 ms at t1 + 400 ms
      final t2 = t1.add(const Duration(milliseconds: 400));
      detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t2);
      expect(switchedExhibit, isNull);

      // Lead breaks at t1 + 450 ms! Exhibit 2 drops to -60 dBm
      final t3 = t1.add(const Duration(milliseconds: 450));
      detector.processReading('76:06:07:E1:A8:C3', -60, timestamp: t3);
      detector.processReading('76:06:07:E1:A8:C3', -60, timestamp: t3.add(const Duration(milliseconds: 10)));
      expect(detector.decisionLog.first.reason, contains('blocked hysteresis'));

      // Exhibit 2 regains lead with readings at -46 dBm at t1 + 500 ms (Lead timer MUST reset to 0!)
      final t4 = t1.add(const Duration(milliseconds: 500));
      detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t4);
      detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t4.add(const Duration(milliseconds: 10)));
      expect(detector.decisionLog.first.reason, contains('0ms / 600ms'));

      // At t4 + 300 ms (300 ms into new lead < 600 ms): should NOT switch
      final t5 = t4.add(const Duration(milliseconds: 300));
      detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t5);
      expect(switchedExhibit, isNull);

      // At t4 + 650 ms (>= 600 ms continuous lead time from t4): SWITCHES!
      final t6 = t4.add(const Duration(milliseconds: 650));
      detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t6);
      expect(switchedExhibit?.id, equals('exhibit_2'));
    });

    test('8. Very Near Override: requires 2 consecutive readings above override level and median lead >= 3 dB', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      Exhibit? switchedExhibit;
      detector.onNavigateToExhibit = (exhibit) async {
        switchedExhibit = exhibit;
      };

      // Open Exhibit 1 at -50 dBm
      detector.processReading('53:1A:7A:82:B4:83', -50, timestamp: t0);
      detector.processReading('53:1A:7A:82:B4:83', -50, timestamp: t0.add(const Duration(milliseconds: 100)));
      detector.onExhibitOpened(allExhibits[0]);

      // Exhibit 2 arrives with 1 reading at -42 dBm (above override -45 dBm)
      switchedExhibit = null;
      final t1 = t0.add(const Duration(milliseconds: 200));
      detector.processReading('76:06:07:E1:A8:C3', -42, timestamp: t1);

      // Only 1 reading above override level -> Does NOT trigger Very Near Override yet!
      expect(switchedExhibit, isNull);

      // Exhibit 2 arrives with second consecutive reading at -41 dBm (>= -45 dBm)
      // Delta = (-41) - (-50) = 9 dB >= 3 dB lead
      final t2 = t0.add(const Duration(milliseconds: 300));
      detector.processReading('76:06:07:E1:A8:C3', -41, timestamp: t2);

      // Both conditions satisfied -> WINS IMMEDIATELY on 2nd reading!
      expect(switchedExhibit?.id, equals('exhibit_2'));
      expect(detector.decisionLog.first.reason, contains('switch near override'));
      expect(detector.decisionLog.first.reason, contains('lead: +9.0 dB'));
    });

    test('9. Very Near Override: blocked if 2 consecutive readings are not maintained', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      Exhibit? switchedExhibit;
      detector.onNavigateToExhibit = (exhibit) async {
        switchedExhibit = exhibit;
      };

      // Open Exhibit 1 at -50 dBm
      detector.processReading('53:1A:7A:82:B4:83', -50, timestamp: t0);
      detector.processReading('53:1A:7A:82:B4:83', -50, timestamp: t0.add(const Duration(milliseconds: 100)));
      detector.onExhibitOpened(allExhibits[0]);

      switchedExhibit = null;
      // Reading 1: -42 dBm (>= -45)
      detector.processReading('76:06:07:E1:A8:C3', -42, timestamp: t0.add(const Duration(milliseconds: 200)));
      // Reading 2: -48 dBm (< -45)
      detector.processReading('76:06:07:E1:A8:C3', -48, timestamp: t0.add(const Duration(milliseconds: 300)));
      // Reading 3: -42 dBm (>= -45, but previous was -48, so only 1 consecutive)
      detector.processReading('76:06:07:E1:A8:C3', -42, timestamp: t0.add(const Duration(milliseconds: 400)));

      // Should not trigger very near override
      expect(switchedExhibit, isNull);
    });

    test('10. Stale readings timeout: only count beacons under 1500 ms old', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: t0);
      expect(detector.currentLeader?.id, equals('exhibit_1'));

      // At t0 + 1400 ms (< 1500 ms): still counted
      final t1400 = t0.add(const Duration(milliseconds: 1400));
      detector.tick(timestamp: t1400);
      expect(detector.currentLeader?.id, equals('exhibit_1'));

      // At t0 + 1550 ms (>= 1500 ms): dropped out of contention
      final t1550 = t0.add(const Duration(milliseconds: 1550));
      detector.tick(timestamp: t1550);
      expect(detector.currentLeader, isNull);
      expect(detector.decisionLog.first.reason, contains('blocked: stale reading (>1.5s)'));
    });

    test('11. Decision log records up to 15 latest decisions with both beacons medians and lead info', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: t0);
      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: t0.add(const Duration(milliseconds: 100)));
      detector.onExhibitOpened(allExhibits[0]);

      for (int i = 1; i <= 20; i++) {
        final t = t0.add(Duration(seconds: i * 2));
        detector.processReading('76:06:07:E1:A8:C3', -46, timestamp: t);
      }

      // Max 15 items kept
      expect(detector.decisionLog.length, lessThanOrEqualTo(15));
      expect(detector.decisionLog.first.reason, isNotEmpty);
      expect(detector.decisionLog.first.timeFormatted, isNotEmpty);
      expect(detector.decisionLog.first.reason, contains('vs Entrance Gate'));
      expect(detector.decisionLog.first.reason, contains('lead:'));
      expect(detector.decisionLog.first.reason, contains('led:'));
    });

    test('12. 5000ms same-exhibit cooldown blocks reopening until expired', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      Exhibit? openedExhibit;
      detector.onNavigateToExhibit = (exhibit) async {
        openedExhibit = exhibit;
      };

      // Open Exhibit 1 (2 readings in 800 ms)
      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: t0);
      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: t0.add(const Duration(milliseconds: 100)));
      expect(openedExhibit?.id, equals('exhibit_1'));
      detector.onExhibitOpened(allExhibits[0]);

      // User closes Exhibit 1 at t0 + 1000ms
      final tClose = t0.add(const Duration(milliseconds: 1000));
      detector.onExhibitClosed('exhibit_1', timestamp: tClose);

      // At tClose + 3000ms (< 5000ms cooldown) -> blocked
      openedExhibit = null;
      final tAttempt1 = tClose.add(const Duration(milliseconds: 3000));
      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: tAttempt1);
      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: tAttempt1.add(const Duration(milliseconds: 50)));
      expect(openedExhibit, isNull);
      expect(detector.cooldownRemainingSeconds, equals(2));
      expect(detector.decisionLog.first.reason, contains('blocked cooldown'));

      // At tClose + 5100ms (>= 5000ms cooldown) -> reopens!
      final tAttempt2 = tClose.add(const Duration(milliseconds: 5100));
      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: tAttempt2);
      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: tAttempt2.add(const Duration(milliseconds: 50)));
      expect(openedExhibit?.id, equals('exhibit_1'));
      expect(detector.cooldownRemainingSeconds, equals(0));
    });

    test('13. Scan restart warning logged properly in decision log', () {
      detector.logWarning('scan restart detected');
      expect(detector.decisionLog.first.reason, contains('warning: scan restart detected'));
    });
  });
}
