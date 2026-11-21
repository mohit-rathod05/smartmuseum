import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import 'palace_decorations.dart';

/// In-app animated intro shown once per app launch.
/// Fades & scales the logo in over 600 ms, fades in "SmartMuseum", holds for 800 ms,
/// and fades out to the home screen (total duration ~1700 ms < 2.0s).
class AnimatedIntroOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const AnimatedIntroOverlay({super.key, required this.onComplete});

  /// Allows unit tests to disable or bypass the intro animation.
  static bool skipForTesting = false;

  @override
  State<AnimatedIntroOverlay> createState() => _AnimatedIntroOverlayState();
}

class _AnimatedIntroOverlayState extends State<AnimatedIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _textFadeAnimation;
  late final Animation<double> _exitFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    // 0 to 600 ms: Logo scales & fades in
    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.353, curve: Curves.easeOutCubic),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.353, curve: Curves.easeIn),
      ),
    );

    // 200 to 600 ms: Text fades in
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.118, 0.353, curve: Curves.easeIn),
      ),
    );

    // 1400 to 1700 ms: Overlay fades out to HomeScreen
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.824, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });

    if (AnimatedIntroOverlay.skipForTesting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onComplete();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _exitFadeAnimation.value,
          child: child,
        );
      },
      child: Container(
        color: AppColors.royalMaroon,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Subtle geometric lattice background
            const Positioned.fill(
              child: CustomPaint(
                painter: JaliPatternPainter(
                  color: AppColors.antiqueGold,
                  spacing: 28.0,
                ),
              ),
            ),

            // Centered Logo & Branding
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with scaling and fading
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _logoFadeAnimation.value,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/branding/logo.png',
                                width: 110,
                                height: 110,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.antiqueGold,
                                    ),
                                    child: const Icon(
                                      Icons.museum_rounded,
                                      size: 64,
                                      color: AppColors.royalMaroon,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  // App Title "SmartMuseum" fading in
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Opacity(
                        opacity: _textFadeAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              AppConstants.appName,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ivory,
                                letterSpacing: 1.2,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const GoldOrnamentalDivider(width: 140),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
