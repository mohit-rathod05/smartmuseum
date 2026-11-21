import 'package:material_ui/material_ui.dart';
import '../data/exhibits.dart';
import '../screens/arrival_banner.dart';
import '../screens/exhibit_screen.dart';
import '../screens/home_screen.dart';
import 'beacon_detector.dart';

/// Observer that monitors the navigator stack to verify Rule:
/// The stack must NEVER contain more than Home + one Exhibit route.
class ExhibitRouteObserver extends NavigatorObserver {
  static final ExhibitRouteObserver instance = ExhibitRouteObserver._();
  ExhibitRouteObserver._();

  final List<Route<dynamic>> _routeStack = [];

  List<Route<dynamic>> get routeStack => List.unmodifiable(_routeStack);
  int get routeCount => _routeStack.length;

  int get exhibitRouteCount =>
      _routeStack.where((r) => r.settings.name == '/exhibit').length;

  void _verifyStack() {
    assert(() {
      final exhibitCount = exhibitRouteCount;
      if (exhibitCount > 1) {
        debugPrint(
            '[NAV ERROR] Stacking detected! Stack contains $exhibitCount exhibit routes:');
        for (final r in _routeStack) {
          debugPrint('  - ${r.settings.name ?? r.runtimeType}');
        }
      }
      return exhibitCount <= 1;
    }(), 'Navigator stack contains more than one exhibit route ($exhibitRouteCount)');
  }

  void clearForTest() {
    _routeStack.clear();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _routeStack.add(route);
    _verifyStack();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _routeStack.remove(route);
    _verifyStack();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _routeStack.remove(route);
    _verifyStack();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _routeStack.remove(oldRoute);
    if (newRoute != null) _routeStack.add(newRoute);
    _verifyStack();
  }
}

/// Centralized exhibit navigation manager ensuring:
/// 1. Exactly ONE exhibit route exists in the stack at any time.
/// 2. Back from an exhibit returns directly to the home screen.
/// 3. If an exhibit is already open, it replaces it (or pops to home first).
/// 4. If automatic detection, checks tourActive and aborts if tour stopped.
/// 5. Manual card taps & Simulate tool work regardless of tourActive.
class ExhibitNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static int _inFlightToken = 0;

  static Future<void> openExhibit(
    Exhibit exhibit, {
    bool isAutomatic = false,
  }) async {
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    if (isAutomatic) {
      // Must not navigate when tour is stopped
      if (!BeaconDetector.instance.tourActive) return;

      // Show arrival banner on top overlay (not a route)
      if (nav.context.mounted) {
        ArrivalBanner.show(nav.context, exhibit);
      }

      final token = ++_inFlightToken;
      await Future.delayed(const Duration(milliseconds: 600));

      // Re-verify tourActive and token after delay
      if (!BeaconDetector.instance.tourActive || token != _inFlightToken) {
        return;
      }
      if (nav.mounted != true) return;
    } else {
      // Manual or simulated open cancels any pending automatic navigation
      _inFlightToken++;
    }

    HomeScreen.visitedExhibitIds.add(exhibit.id);
    BeaconDetector.instance.onExhibitOpened(exhibit);

    // Dismiss arrival banner
    ArrivalBanner.dismiss();

    final isExhibitAlreadyOpen =
        ExhibitRouteObserver.instance.exhibitRouteCount > 0;

    final route = PageRouteBuilder(
      settings: const RouteSettings(name: '/exhibit'),
      transitionDuration: const Duration(milliseconds: 350),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) =>
          ExhibitScreen(exhibit: exhibit),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (isExhibitAlreadyOpen) {
      // Replace existing exhibit route so pressing back returns directly to home
      nav.pushReplacement(route);
    } else {
      // Pop any dialogs/bottom sheets back to home first, then push exhibit
      nav.popUntil((r) => r.isFirst);
      nav.push(route);
    }
  }

  /// Cancels any in-flight navigation timers
  static void cancelPendingNavigation() {
    _inFlightToken++;
    ArrivalBanner.dismiss();
  }
}
