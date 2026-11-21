import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import '../data/exhibits.dart';
import '../theme/app_theme.dart';
import '../widgets/palace_decorations.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const List<Map<String, String>> informationSources = [
    {
      'title': 'Wikipedia',
      'detail':
          'Lakshmi Vilas Palace, Vadodara; Maharaja Fateh Singh Museum',
    },
    {
      'title': 'historyofvadodara.in',
      'detail': 'Historical documentation of Baroda state and royal architecture',
    },
    {
      'title': 'Business Standard',
      'detail': 'Heritage features, royal lineage records, and archival reports',
    },
    {
      'title': 'Incredible India',
      'detail': 'Ministry of Tourism, Government of India heritage listings',
    },
    {
      'title': 'Gujarat Tourism',
      'detail': 'Official travel and heritage records of Vadodara monuments',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmSandstone,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/branding/logo.png',
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Photo Credits',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.ivory,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.royalMaroon,
        foregroundColor: AppColors.ivory,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          physics: const BouncingScrollPhysics(),
          children: [
            // Section 1: Header Info Card for Photo Credits
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: AppTheme.cardRadius,
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppTheme.cardElevation,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/branding/logo.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.photo_library_outlined,
                            size: 20,
                            color: AppColors.antiqueGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'IMAGE ATTRIBUTIONS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: AppColors.antiqueGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Photographs and visual archives presented in this guide are curated under Creative Commons licenses or public domain heritage records.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      color: AppColors.deepCharcoal,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Photo Credits Grouped By Exhibit
            ...allExhibits.map((exhibit) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: AppTheme.cardRadius,
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppTheme.cardElevation,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.antiqueGold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              exhibit.title,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.royalMaroon,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const GoldOrnamentalDivider(width: 120),
                      const SizedBox(height: 12),

                      if (exhibit.imageCredits.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.warmSandstone.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.borderLight, width: 0.8),
                          ),
                          child: Text(
                            'Credits will be added',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      else
                        ...exhibit.imageCredits.map((credit) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  credit.file,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: AppColors.deepCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Author: ${credit.author} • Licence: ${credit.licence}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                if (credit.sourceUrl.isNotEmpty)
                                  Text(
                                    credit.sourceUrl,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.antiqueGold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),
            const GoldOrnamentalDivider(width: 180),
            const SizedBox(height: 24),

            // Section 2: Information Sources
            Container(
              decoration: BoxDecoration(
                color: AppColors.ivory,
                borderRadius: AppTheme.cardRadius,
                border: Border.all(color: AppColors.borderLight),
                boxShadow: AppTheme.cardElevation,
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.royalMaroon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 20,
                          color: AppColors.royalMaroon,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'HISTORICAL & ARCHIVAL SOURCES',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                              color: AppColors.royalMaroon,
                            ),
                          ),
                          Text(
                            'Information sources',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepCharcoal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const GoldOrnamentalDivider(width: 140),
                  const SizedBox(height: 14),

                  // Entries list
                  ...informationSources.map((source) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.antiqueGold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  source['title']!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.deepCharcoal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  source['detail']!,
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
                    );
                  }),

                  const SizedBox(height: 10),
                  // Disclaimer Callout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.warmSandstone.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.antiqueGold.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.royalMaroon,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is a student demo and is not affiliated with Laxmi Vilas Palace.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.royalMaroon,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                AppConstants.homeFooter,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
