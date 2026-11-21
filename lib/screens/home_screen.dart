import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import '../data/exhibits.dart';
import '../services/asset_checker.dart';
import '../services/beacon_detector.dart';
import '../services/beacon_service.dart';
import '../services/exhibit_navigator.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_intro_overlay.dart';
import '../widgets/palace_decorations.dart';
import 'credits_screen.dart';
import 'pin_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  /// Tracks visited exhibits in this session.
  static final Set<String> visitedExhibitIds = {};

  /// Ensures in-app animated intro displays only once per app launch.
  static bool hasShownIntro = false;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final BeaconService _beaconService = BeaconService.instance;

  bool _isTourActive = false;
  Timer? _longPressTimer;
  late bool _showIntro;

  // Radar animation controller
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _showIntro = !HomeScreen.hasShownIntro;
    if (_showIntro) {
      HomeScreen.hasShownIntro = true;
    }

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    // Check permissions and adapter state silently on launch without scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _beaconService.checkPermissionsOnly();
    });
  }

  @override
  void dispose() {
    _radarController.dispose();
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _startLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(seconds: 2), () {
      PinDialog.show(context);
    });
  }

  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
  }

  void _toggleTour() async {
    final newActive = !_isTourActive;
    setState(() {
      _isTourActive = newActive;
    });

    if (newActive) {
      BeaconDetector.instance.setTourActive(true);
      await _beaconService.startScan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Palace tour started. Detecting nearby exhibits...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      BeaconDetector.instance.setTourActive(false);
      ExhibitNavigator.cancelPendingNavigation();
      await _beaconService.stopScan();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Palace tour stopped.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _openExhibit(Exhibit exhibit) async {
    await ExhibitNavigator.openExhibit(exhibit, isAutomatic: false);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: AppColors.warmSandstone,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // App Header with Jali & Ornamental Divider
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: _buildHeader(),
              ),
            ),

            // Large Radar Status Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildStatusCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // Start/Stop Tour Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTourActionButton(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // "Your Tour" Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTourSectionHeader(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            // Exhibit Cards List
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final exhibit = allExhibits[index];
                    final isVisited =
                        HomeScreen.visitedExhibitIds.contains(exhibit.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildExhibitCard(exhibit, isVisited),
                    );
                  },
                  childCount: allExhibits.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // "How It Works" Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildHowItWorksCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Palace Footer & Credits Link
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildFooter(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );

    if (!_showIntro) {
      return scaffold;
    }

    return Stack(
      children: [
        scaffold,
        AnimatedIntroOverlay(
          onComplete: () {
            if (mounted) {
              setState(() {
                _showIntro = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startLongPressTimer(),
      onTapUp: (_) => _cancelLongPressTimer(),
      onTapCancel: _cancelLongPressTimer,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.royalMaroon,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppColors.borderLight, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Header Image or Fallback Gradient
            Positioned.fill(
              child: AssetChecker.hasAsset(ExhibitAssetPaths.homeHeader)
                  ? Image.asset(
                      ExhibitAssetPaths.homeHeader,
                      fit: BoxFit.cover,
                      cacheWidth: 1200,
                    )
                  : const ExhibitImagePlaceholder(
                      title: AppConstants.appName,
                      isHeader: true,
                    ),
            ),

            // Royal Maroon / Charcoal overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.deepCharcoal.withValues(alpha: 0.65),
                      AppColors.royalMaroon.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
            ),

            // Repeating Jali lattice pattern drawn in code at ~5% opacity
            const Positioned.fill(
              child: CustomPaint(
                painter: JaliPatternPainter(
                  color: AppColors.antiqueGold,
                  spacing: 24.0,
                ),
              ),
            ),

            // Header Typography & Motifs
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                children: [
                  const GoldOrnamentalDivider(width: 140),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/branding/logo.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.museum_rounded,
                            size: 36,
                            color: AppColors.antiqueGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppConstants.appName,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ivory,
                          letterSpacing: 0.4,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.appTagline,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ivory.withValues(alpha: 0.9),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const GoldOrnamentalDivider(width: 140),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return ListenableBuilder(
      listenable: _beaconService,
      builder: (context, _) {
        final hasPermissions = _beaconService.hasPermissions;
        final isBluetoothOn = _beaconService.isBluetoothOn;

        String statusTitle;
        String statusSubtitle;
        IconData icon;
        Color accentColor;
        VoidCallback? onTap;

        if (!hasPermissions) {
          statusTitle = 'Permission Needed';
          statusSubtitle = 'Tap to allow Bluetooth & location permissions';
          icon = Icons.security_rounded;
          accentColor = Colors.orangeAccent.shade700;
          onTap = _beaconService.requestPermissions;
        } else if (!isBluetoothOn) {
          statusTitle = 'Bluetooth is Off';
          statusSubtitle = 'Tap to enable Bluetooth for exhibit detection';
          icon = Icons.bluetooth_disabled_rounded;
          accentColor = Colors.redAccent.shade700;
          onTap = _beaconService.turnOnBluetooth;
        } else if (!_isTourActive) {
          statusTitle = 'Palace Tour is Paused';
          statusSubtitle =
              "Tap 'Start Tour' below to begin automatic audio guide";
          icon = Icons.explore_off_rounded;
          accentColor = AppColors.royalMaroon;
          onTap = _toggleTour;
        } else {
          statusTitle = 'Exploring Palace Grounds...';
          statusSubtitle =
              'Walk up to any palace stop — the story opens automatically';
          icon = Icons.radar_rounded;
          accentColor = AppColors.antiqueGold;
          onTap = null;
        }

        final isScanningNow =
            _isTourActive && hasPermissions && isBluetoothOn;

        return InkWell(
          borderRadius: AppTheme.cardRadius,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: AppTheme.cardRadius,
              border: Border.all(
                color: isScanningNow
                    ? AppColors.antiqueGold
                    : AppColors.borderLight,
                width: isScanningNow ? 1.5 : 1.0,
              ),
              boxShadow:
                  isScanningNow ? AppTheme.goldGlow : AppTheme.cardElevation,
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Radar / Status Icon
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isScanningNow) ...[
                        AnimatedBuilder(
                          animation: _radarController,
                          builder: (context, _) {
                            final progress = _radarController.value;
                            return Container(
                              width: 58 * progress,
                              height: 58 * progress,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.antiqueGold
                                    .withValues(alpha: (1.0 - progress) * 0.35),
                                border: Border.all(
                                  color: AppColors.antiqueGold.withValues(
                                      alpha: (1.0 - progress) * 0.7),
                                  width: 1.2,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isScanningNow
                              ? AppColors.royalMaroon
                              : accentColor.withValues(alpha: 0.12),
                          border: Border.all(
                            color: isScanningNow
                                ? AppColors.antiqueGold
                                : accentColor.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isScanningNow ? AppColors.ivory : accentColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Text Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              statusTitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepCharcoal,
                              ),
                            ),
                          ),
                          if (isScanningNow)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.antiqueGold,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        statusSubtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTourActionButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _isTourActive ? AppColors.deepCharcoal : AppColors.royalMaroon,
        foregroundColor: AppColors.ivory,
        elevation: 2,
        shadowColor: AppColors.royalMaroon.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.antiqueGold, width: 1.4),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: _toggleTour,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isTourActive
                ? Icons.stop_circle_rounded
                : Icons.play_circle_fill_rounded,
            size: 22,
            color: AppColors.antiqueGold,
          ),
          const SizedBox(width: 10),
          Text(
            _isTourActive ? 'Stop Tour' : 'Start Tour',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: AppColors.ivory,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourSectionHeader() {
    final visitedCount = HomeScreen.visitedExhibitIds.length;
    final totalCount = allExhibits.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Your Tour',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.deepCharcoal,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight, width: 1.0),
          ),
          child: Text(
            '$visitedCount of $totalCount palace stops explored',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.royalMaroon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExhibitCard(Exhibit exhibit, bool isVisited) {
    final hasThumb = AssetChecker.hasAsset(exhibit.thumbImage);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.cardRadius,
        onTap: () => _openExhibit(exhibit),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: AppTheme.cardRadius,
            border: Border.all(
              color: isVisited
                  ? AppColors.antiqueGold
                  : AppColors.borderLight,
              width: isVisited ? 1.5 : 1.0,
            ),
            boxShadow: AppTheme.cardElevation,
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Pointed Arch Clipped Thumbnail
              Hero(
                tag: 'exhibit_hero_${exhibit.id}',
                child: SizedBox(
                  width: 78,
                  height: 84,
                  child: ClipPath(
                    clipper: const PointedArchClipper(shoulderRatio: 0.16),
                    child: hasThumb
                        ? Image.asset(
                            exhibit.thumbImage,
                            width: 78,
                            height: 84,
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                          )
                        : ExhibitImagePlaceholder(
                            title: exhibit.title,
                            width: 78,
                            height: 84,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title & One-line description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exhibit.title,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepCharcoal,
                            ),
                          ),
                        ),
                        if (isVisited)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 13,
                                  color: AppColors.successGreen,
                                ),
                                SizedBox(width: 3),
                                Text(
                                  'Visited',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      exhibit.shortDescription,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.antiqueGold,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.borderLight, width: 1.0),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.royalMaroon),
              const SizedBox(width: 6),
              Text(
                'How It Works',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.deepCharcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildHowItWorksStep(
            step: '1',
            text: 'Start the palace tour using the button above.',
          ),
          const SizedBox(height: 6),
          _buildHowItWorksStep(
            step: '2',
            text: 'Walk through the royal gates, halls, and galleries.',
          ),
          const SizedBox(height: 6),
          _buildHowItWorksStep(
            step: '3',
            text: 'Stories and audio narration open automatically as you approach.',
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksStep({required String step, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.royalMaroon,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppColors.ivory,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.deepCharcoal,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const GoldOrnamentalDivider(width: 120),
        const SizedBox(height: 12),
        Text(
          AppConstants.homeFooter,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreditsScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Photo Credits',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.royalMaroon,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
