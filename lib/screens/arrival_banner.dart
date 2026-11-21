import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import '../data/exhibits.dart';
import '../theme/app_theme.dart';

class ArrivalBanner {
  static OverlayEntry? _currentEntry;

  static void show(BuildContext context, Exhibit exhibit) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _ArrivalBannerWidget(
        exhibit: exhibit,
        onDismiss: () {
          try {
            entry.remove();
          } catch (_) {}
          if (_currentEntry == entry) _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (_currentEntry == entry) {
        try {
          entry.remove();
        } catch (_) {}
        _currentEntry = null;
      }
    });
  }

  static void dismiss() {
    try {
      _currentEntry?.remove();
    } catch (_) {}
    _currentEntry = null;
  }
}

class _ArrivalBannerWidget extends StatelessWidget {
  final Exhibit exhibit;
  final VoidCallback onDismiss;

  const _ArrivalBannerWidget({
    required this.exhibit,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.maroon,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gold, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Gold Icon with Ripple
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.maroonDark,
                  border: Border.all(color: AppColors.gold, width: 1.2),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Banner Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "YOU'VE ARRIVED AT",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.3,
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exhibit.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandstone,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.gold,
              ),
            ],
          ),
        )
            .animate()
            .slideY(
              begin: -1.2,
              end: 0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
            )
            .fadeIn(duration: const Duration(milliseconds: 400))
            .shimmer(
              duration: const Duration(milliseconds: 600),
              color: AppColors.goldLight.withValues(alpha: 0.35),
            ),
      ),
    );
  }
}
