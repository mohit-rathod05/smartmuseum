import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:museum_guide/data/exhibits.dart';
import 'package:museum_guide/main.dart';
import 'package:museum_guide/screens/arrival_banner.dart';
import 'package:museum_guide/screens/exhibit_screen.dart';
import 'package:museum_guide/services/beacon_detector.dart';
import 'package:museum_guide/services/beacon_service.dart';
import 'package:museum_guide/services/exhibit_navigator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ExhibitRouteObserver.instance.clearForTest();
  });

  group('BUG 1: Tour Active, Stop Tour & Subscription Lifecycle', () {
    late BeaconDetector detector;
    late BeaconService beaconService;

    setUp(() {
      detector = BeaconDetector.instance;
      beaconService = BeaconService.instance;
      detector.setTourActive(false);
    });

    test('Detector ignores all readings and never triggers when tourActive is false', () {
      expect(detector.tourActive, isFalse);

      bool didTrigger = false;
      detector.onNavigateToExhibit = (exhibit) async {
        didTrigger = true;
      };

      final now = DateTime.now();
      // Send 5 strong readings for Exhibit 1
      for (int i = 0; i < 5; i++) {
        detector.processReading(
          '53:1A:7A:82:B4:83',
          -40,
          timestamp: now.add(Duration(milliseconds: i * 100)),
        );
      }

      detector.tick(timestamp: now.add(const Duration(milliseconds: 600)));

      expect(didTrigger, isFalse);
      expect(detector.currentlyOpenExhibit, isNull);
      expect(detector.currentLeader, isNull);
      expect(detector.getBeaconAverage('exhibit_1'), isNull);
    });

    test('Stop Tour resets all detector state and stops media', () {
      detector.setTourActive(true);
      expect(detector.tourActive, isTrue);

      final now = DateTime.now();
      detector.processReading('53:1A:7A:82:B4:83', -45, timestamp: now);
      detector.processReading(
        '53:1A:7A:82:B4:83',
        -45,
        timestamp: now.add(const Duration(milliseconds: 200)),
      );

      // Stop Tour
      detector.setTourActive(false);

      expect(detector.tourActive, isFalse);
      expect(detector.currentlyOpenExhibit, isNull);
      expect(detector.currentLeader, isNull);
      expect(detector.leadingExhibitId, isNull);
      expect(detector.cooldownRemainingMs, equals(0));
      expect(detector.getBeaconAverage('exhibit_1'), isNull);
    });

    test('Starting tour twice does not create duplicate subscriptions', () async {
      detector.setTourActive(true);

      // First start
      await beaconService.startScan();
      final countAfterFirst = beaconService.activeScanSubscriptionCount;

      // Second start (must not duplicate)
      await beaconService.startScan();
      final countAfterSecond = beaconService.activeScanSubscriptionCount;

      expect(countAfterSecond, equals(countAfterFirst));

      // Stop tour
      detector.setTourActive(false);
      await beaconService.stopScan();
      expect(beaconService.activeScanSubscriptionCount, equals(0));
    });

    test('Manual opening from card works while tour is stopped', () async {
      detector.setTourActive(false);
      expect(detector.tourActive, isFalse);

      // Manual open sets onExhibitOpened without requiring tourActive
      detector.onExhibitOpened(allExhibits[0]);
      expect(detector.currentlyOpenExhibit?.id, equals('exhibit_1'));
    });
  });

  group('BUG 2: Single Exhibit Route & Navigator Stack Integrity', () {
    testWidgets('Navigator stack never contains more than Home + one Exhibit route',
        (WidgetTester tester) async {
      final observer = ExhibitRouteObserver.instance;

      await tester.pumpWidget(const MuseumGuideApp());
      await tester.pump(const Duration(milliseconds: 100));

      // Initially only HomeScreen is in the stack
      expect(observer.routeCount, equals(1));
      expect(observer.exhibitRouteCount, equals(0));

      // 1. Open Exhibit 1 (Entrance Gate)
      await ExhibitNavigator.openExhibit(allExhibits[0], isAutomatic: false);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ExhibitScreen), findsOneWidget);
      expect(find.text('Heritage & History'), findsOneWidget);
      expect(observer.routeCount, equals(2));
      expect(observer.exhibitRouteCount, equals(1));

      // 2. Switch to Exhibit 2 (Durbar Hall) while Exhibit 1 is open
      await ExhibitNavigator.openExhibit(allExhibits[1], isAutomatic: false);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ExhibitScreen), findsOneWidget);
      // Stack MUST STILL be Home + Durbar Hall (never stacked!)
      expect(observer.routeCount, equals(2));
      expect(observer.exhibitRouteCount, equals(1));

      // 3. Switch to Exhibit 3 (Royal Gallery) while Exhibit 2 is open
      await ExhibitNavigator.openExhibit(allExhibits[2], isAutomatic: false);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ExhibitScreen), findsOneWidget);
      // Stack MUST STILL be Home + Royal Gallery
      expect(observer.routeCount, equals(2));
      expect(observer.exhibitRouteCount, equals(1));

      // 4. Pressing Back from Exhibit 3 must return DIRECTLY to Home Screen
      final NavigatorState nav = ExhibitNavigator.navigatorKey.currentState!;
      nav.pop();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      // No ExhibitScreen remaining, only HomeScreen
      expect(find.byType(ExhibitScreen), findsNothing);
      expect(find.text('Start Tour'), findsOneWidget);

      // Stack contains only HomeScreen
      expect(observer.routeCount, equals(1));
      expect(observer.exhibitRouteCount, equals(0));
    });

    testWidgets('Arrival banner overlay does not add extra routes to navigator stack',
        (WidgetTester tester) async {
      final observer = ExhibitRouteObserver.instance;

      await tester.pumpWidget(const MuseumGuideApp());
      await tester.pump(const Duration(milliseconds: 100));

      final context = ExhibitNavigator.navigatorKey.currentContext!;
      ArrivalBanner.show(context, allExhibits[0]);
      await tester.pump(const Duration(milliseconds: 100));

      // Arrival banner is an OverlayEntry, not a Route: stack routeCount stays 1
      expect(observer.routeCount, equals(1));
      expect(observer.exhibitRouteCount, equals(0));

      ArrivalBanner.dismiss();
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
