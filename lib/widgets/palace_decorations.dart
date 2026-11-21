import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';

/// Pointed Indo-Saracenic / Mughal-Gothic arch clipper for hero & card images.
class PointedArchClipper extends CustomClipper<Path> {
  final double shoulderRatio;

  const PointedArchClipper({this.shoulderRatio = 0.18});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final shoulderY = h * shoulderRatio;

    // Start at bottom-left
    path.moveTo(0, h);
    // Line to bottom-right
    path.lineTo(w, h);
    // Line up to right shoulder
    path.lineTo(w, shoulderY);

    // Right curve up to pointed apex at top center (w / 2, 0)
    path.cubicTo(
      w * 0.9,
      shoulderY * 0.45,
      w * 0.65,
      0,
      w * 0.5,
      0,
    );

    // Left curve from pointed apex down to left shoulder
    path.cubicTo(
      w * 0.35,
      0,
      w * 0.1,
      shoulderY * 0.45,
      0,
      shoulderY,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant PointedArchClipper oldClipper) =>
      oldClipper.shoulderRatio != shoulderRatio;
}

/// Thin gold ornamental divider between sections with a central diamond motif.
class GoldOrnamentalDivider extends StatelessWidget {
  final double width;

  const GoldOrnamentalDivider({super.key, this.width = 150});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width,
        height: 18,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.antiqueGold.withValues(alpha: 0.0),
                      AppColors.antiqueGold.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Transform.rotate(
              angle: 45 * 3.14159 / 180,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.antiqueGold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.antiqueGold.withValues(alpha: 0.45),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.antiqueGold.withValues(alpha: 0.8),
                      AppColors.antiqueGold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle repeating geometric jali (lattice) pattern drawn in code at ~5% opacity.
class JaliPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;

  const JaliPatternPainter({
    this.color = AppColors.antiqueGold,
    this.spacing = 26.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw intersecting diagonal lattice lines forming diamond jali
    for (double x = -size.height; x < size.width + size.height; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }

    final accentPaint = Paint()
      ..color = color.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.4, accentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant JaliPatternPainter oldDelegate) => false;
}

/// Fallback warm maroon-to-gold gradient with jali pattern when an asset is missing.
class ExhibitImagePlaceholder extends StatelessWidget {
  final String title;
  final double? width;
  final double? height;
  final bool isHeader;

  const ExhibitImagePlaceholder({
    super.key,
    required this.title,
    this.width,
    this.height,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.royalMaroon,
            Color(0xFF8B2038),
            AppColors.antiqueGold,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(
            painter: JaliPatternPainter(
              color: AppColors.ivory,
              spacing: 24,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHeader
                        ? Icons.museum_rounded
                        : Icons.account_balance_rounded,
                    color: AppColors.ivory.withValues(alpha: 0.85),
                    size: isHeader ? 32 : 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.ivory,
                      fontSize: isHeader ? 17 : 13.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
