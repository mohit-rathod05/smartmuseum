import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:museum_guide/main.dart';
import 'package:museum_guide/screens/credits_screen.dart';
import 'package:museum_guide/services/asset_checker.dart';
import 'package:museum_guide/theme/app_theme.dart';
import 'package:museum_guide/widgets/animated_intro_overlay.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeScreen branding and palace theme smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MuseumGuideApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppConstants.appName), findsWidgets);
    expect(find.text(AppConstants.appTagline), findsOneWidget);
    expect(find.text('Start Tour'), findsOneWidget);
    expect(find.text('Your Tour'), findsOneWidget);
    expect(find.text(AppConstants.homeFooter, skipOffstage: false), findsOneWidget);
    expect(find.text('Photo Credits', skipOffstage: false), findsOneWidget);
  });

  testWidgets('AnimatedIntroOverlay scales and fades in logo and SmartMuseum title', (WidgetTester tester) async {
    bool completed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedIntroOverlay(
          onComplete: () {
            completed = true;
          },
        ),
      ),
    );

    // Initial state: Logo and SmartMuseum are in tree
    expect(find.text('SmartMuseum'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Advance 600 ms: Logo & text visible
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('SmartMuseum'), findsOneWidget);
    expect(completed, isFalse);

    // Advance beyond 1700 ms: onComplete triggered
    await tester.pump(const Duration(milliseconds: 1200));
    expect(completed, isTrue);
  });

  testWidgets('CreditsScreen displays photo credits and information sources', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CreditsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Photo Credits'), findsOneWidget);
    expect(find.text('Credits will be added'), findsWidgets);
    expect(find.text('Information sources', skipOffstage: false), findsOneWidget);
    expect(find.text('Wikipedia', skipOffstage: false), findsOneWidget);
    expect(find.text('historyofvadodara.in', skipOffstage: false), findsOneWidget);
    expect(find.text('Business Standard', skipOffstage: false), findsOneWidget);
    expect(find.text('Incredible India', skipOffstage: false), findsOneWidget);
    expect(find.text('Gujarat Tourism', skipOffstage: false), findsOneWidget);
    expect(
      find.text('This is a student demo and is not affiliated with Laxmi Vilas Palace.', skipOffstage: false),
      findsOneWidget,
    );
  });

  test('AssetChecker behaves correctly when finding missing files', () {
    AssetChecker.mockAssetsForTest([
      'assets/images/header.jpg',
      'assets/images/exhibit1/hero.jpg',
    ]);

    expect(AssetChecker.hasAsset('assets/images/header.jpg'), isTrue);
    expect(AssetChecker.hasAsset('assets/audio/durbar_hall.mp3'), isFalse);

    final filtered = AssetChecker.filterExisting([
      'assets/images/header.jpg',
      'assets/audio/durbar_hall.mp3',
    ]);
    expect(filtered, equals(['assets/images/header.jpg']));

    final missing = AssetChecker.findMissing([
      'assets/images/header.jpg',
      'assets/audio/durbar_hall.mp3',
      'assets/video/royal_gallery.mp4',
    ]);
    expect(
      missing,
      equals([
        'assets/audio/durbar_hall.mp3',
        'assets/video/royal_gallery.mp4',
      ]),
    );

    AssetChecker.resetForTest();
  });
}
