import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'data/exhibits.dart';
import 'screens/home_screen.dart';
import 'services/asset_checker.dart';
import 'services/beacon_detector.dart';
import 'services/exhibit_navigator.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AssetChecker.initialize();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  _setupNavigation();
  runApp(const MuseumGuideApp());
}

void _setupNavigation() {
  BeaconDetector.instance.onNavigateToExhibit = (Exhibit exhibit) async {
    await ExhibitNavigator.openExhibit(exhibit, isAutomatic: true);
  };
}

class MuseumGuideApp extends StatelessWidget {
  const MuseumGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: ExhibitNavigator.navigatorKey,
      navigatorObservers: [ExhibitRouteObserver.instance],
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const HomeScreen(),
    );
  }
}
