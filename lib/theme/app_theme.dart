import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// Royal Indo-Saracenic Heritage Palette & Typography for Laxmi Vilas Palace Guide.
class AppColors {
  // Royal Indo-Saracenic Palette
  static const Color royalMaroon = Color(0xFF6B1426);
  static const Color warmSandstone = Color(0xFFF3E7D3);
  static const Color antiqueGold = Color(0xFFC9962B);
  static const Color ivory = Color(0xFFFBF7EF);
  static const Color deepCharcoal = Color(0xFF1B1613);

  // Surface & Accent Variants
  static const Color cardSurface = ivory;
  static const Color cardSurfaceAlt = warmSandstone;
  static const Color goldLight = Color(0xFFE2B04A);
  static const Color maroonLight = Color(0xFF8A1E34);
  static const Color textMuted = Color(0xFF6E625A);
  static const Color borderLight = Color(0xFFE5D5BC);
  static const Color successGreen = Color(0xFF2E7D32);

  // Backwards compatibility aliases
  static const Color charcoal = deepCharcoal;
  static const Color charcoalLight = Color(0xFF3A312B);
  static const Color offWhite = warmSandstone;
  static const Color warmGold = antiqueGold;
  static const Color deepMaroon = royalMaroon;
  static const Color sandstone = warmSandstone;
  static const Color maroon = royalMaroon;
  static const Color maroonDark = royalMaroon;
  static const Color gold = antiqueGold;
  static const Color darkBrown = deepCharcoal;
}

class AppConstants {
  static const String appName = 'SmartMuseum';
  static const String appTagline = 'Walk the palace. Hear its story.';
  static const String homeFooter = 'A BLE beacon demo - Makerfest Vadodara';
  static const String hiddenSettingsPin = '1234';

  // Default Detection Settings
  static const double defaultThreshold = -65.0;
  static const double defaultNearOverride = -50.0;
  static const double defaultHysteresis = 7.0;
  static const int defaultLeadTime = 600;
  static const int defaultCooldown = 5000;
}

class AppTheme {
  static final BorderRadius cardRadius = BorderRadius.circular(20);
  static const BorderRadius sheetRadius =
      BorderRadius.vertical(top: Radius.circular(28));

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.deepCharcoal.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get cardElevation => [
        BoxShadow(
          color: AppColors.deepCharcoal.withValues(alpha: 0.06),
          blurRadius: 14,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: AppColors.antiqueGold.withValues(alpha: 0.28),
          blurRadius: 16,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.warmSandstone,
      primaryColor: AppColors.royalMaroon,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.royalMaroon,
        onPrimary: AppColors.ivory,
        secondary: AppColors.antiqueGold,
        onSecondary: AppColors.deepCharcoal,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: AppColors.cardSurface,
        onSurface: AppColors.deepCharcoal,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.royalMaroon,
        foregroundColor: AppColors.ivory,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.ivory,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: cardRadius,
          side: const BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      textTheme: TextTheme(
        // Large titles use Playfair Display / Cormorant Garamond
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.deepCharcoal,
          letterSpacing: 0.2,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.deepCharcoal,
          letterSpacing: 0.2,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.deepCharcoal,
        ),
        // Everything else uses Plus Jakarta Sans / Poppins
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.deepCharcoal,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          color: AppColors.deepCharcoal,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13.5,
          color: AppColors.deepCharcoal,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.ivory,
        ),
      ),
    );
  }
}
