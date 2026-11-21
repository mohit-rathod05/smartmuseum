import 'package:material_ui/material_ui.dart';

/// Asset paths for all palace media.
class ExhibitAssetPaths {
  static const String logo = 'assets/branding/logo.png';
  static const String iconForeground = 'assets/branding/icon_foreground.png';
  static const String homeHeader = 'assets/images/header.jpg';

  // Exhibit 1: Entrance Gate
  static const String exhibit1Hero = 'assets/images/exhibit1/hero.jpg';
  static const String exhibit1Thumb = 'assets/images/exhibit1/thumb.jpg';
  static const String exhibit1Gallery1 = 'assets/images/exhibit1/gallery1.jpg';
  static const String exhibit1Gallery2 = 'assets/images/exhibit1/gallery2.jpg';
  static const String exhibit1Gallery3 = 'assets/images/exhibit1/gallery3.jpg';

  // Exhibit 2: Durbar Hall
  static const String exhibit2Hero = 'assets/images/exhibit2/hero.jpg';
  static const String exhibit2Thumb = 'assets/images/exhibit2/thumb.jpg';
  static const String exhibit2Gallery1 = 'assets/images/exhibit2/gallery1.jpg';
  static const String exhibit2Gallery2 = 'assets/images/exhibit2/gallery2.jpg';
  static const String exhibit2Gallery3 = 'assets/images/exhibit2/gallery3.jpg';
  static const String durbarHallAudio = 'assets/audio/durbar_hall.mp3';

  // Exhibit 3: Royal Gallery
  static const String exhibit3Hero = 'assets/images/exhibit3/hero.jpg';
  static const String exhibit3Thumb = 'assets/images/exhibit3/thumb.jpg';
  static const String exhibit3Gallery1 = 'assets/images/exhibit3/gallery1.jpg';
  static const String exhibit3Gallery2 = 'assets/images/exhibit3/gallery2.jpg';
  static const String exhibit3Gallery3 = 'assets/images/exhibit3/gallery3.jpg';
  static const String royalGalleryVideo = 'assets/video/royal_gallery.mp4';

  static const List<String> allExpectedFiles = [
    logo,
    iconForeground,
    homeHeader,
    exhibit1Hero,
    exhibit1Thumb,
    exhibit1Gallery1,
    exhibit1Gallery2,
    exhibit1Gallery3,
    exhibit2Hero,
    exhibit2Thumb,
    exhibit2Gallery1,
    exhibit2Gallery2,
    exhibit2Gallery3,
    exhibit3Hero,
    exhibit3Thumb,
    exhibit3Gallery1,
    exhibit3Gallery2,
    exhibit3Gallery3,
    durbarHallAudio,
    royalGalleryVideo,
  ];
}

class QuickFact {
  final IconData icon;
  final String label;
  final String value;

  const QuickFact({
    required this.icon,
    required this.label,
    required this.value,
  });
}

class TimelineEntry {
  final String year;
  final String text;

  const TimelineEntry({
    required this.year,
    required this.text,
  });
}

class ImageCredit {
  final String file;
  final String author;
  final String licence;
  final String sourceUrl;

  const ImageCredit({
    required this.file,
    required this.author,
    required this.licence,
    required this.sourceUrl,
  });
}

class Exhibit {
  final String id;
  final String title;
  final String mac;
  final String tagline;
  final String era;
  final String location;
  final String story;
  final String didYouKnow;
  final String heroImage;
  final String thumbImage;
  final List<String> galleryImages;
  final String? audioAsset;
  final String? videoAsset;
  final List<QuickFact> quickFacts;
  final List<TimelineEntry> timeline;
  final List<ImageCredit> imageCredits;

  const Exhibit({
    required this.id,
    required this.title,
    required this.mac,
    required this.tagline,
    required this.era,
    required this.location,
    required this.story,
    required this.didYouKnow,
    required this.heroImage,
    required this.thumbImage,
    required this.galleryImages,
    this.audioAsset,
    this.videoAsset,
    required this.quickFacts,
    required this.timeline,
    this.imageCredits = const [],
  });

  /// Backwards compatibility alias for eraLabel
  String get eraLabel => era;

  /// Backwards compatibility alias for locationLabel
  String get locationLabel => location;

  /// Backwards compatibility alias for code/tests expecting imageAsset
  String get imageAsset => heroImage;

  /// Backwards compatibility alias for short description
  String get shortDescription => tagline;
}

final List<Exhibit> allExhibits = [
  const Exhibit(
    id: 'exhibit_1',
    title: 'Entrance Gate',
    mac: '53:1A:7A:82:B4:83',
    tagline: 'Where the golden palace greets you',
    era: 'Commissioned 1878 · Completed 1890',
    location: 'Palace approach',
    story:
        'Welcome to Laxmi Vilas Palace. Maharaja Sayajirao Gaekwad III, ruler of Baroda, commissioned it in 1878, and it was completed in 1890. Charles Mant designed it, and Robert Chisholm completed the work. The style is Indo-Saracenic: Indian arches and domes combined with European planning. It is often described as about four times the size of Buckingham Palace, and it is still home to the Gaekwad family. Look up at the towers, then step inside.',
    didYouKnow:
        'The palace is often described as about four times the size of Buckingham Palace.',
    heroImage: ExhibitAssetPaths.exhibit1Hero,
    thumbImage: ExhibitAssetPaths.exhibit1Thumb,
    galleryImages: [
      ExhibitAssetPaths.exhibit1Gallery1,
      ExhibitAssetPaths.exhibit1Gallery2,
      ExhibitAssetPaths.exhibit1Gallery3,
    ],
    audioAsset: null, // Exhibit 1 has NO audio
    videoAsset: null, // Exhibit 1 has NO video
    quickFacts: [
      QuickFact(
        icon: Icons.account_balance,
        label: 'Style',
        value: 'Indo-Saracenic Revival',
      ),
      QuickFact(
        icon: Icons.person,
        label: 'Built for',
        value: 'Maharaja Sayajirao Gaekwad III',
      ),
      QuickFact(
        icon: Icons.architecture,
        label: 'Architects',
        value: 'Charles Mant and Robert Chisholm',
      ),
    ],
    timeline: [
      TimelineEntry(
        year: '1878',
        text: 'Maharaja Sayajirao Gaekwad III commissions the palace.',
      ),
      TimelineEntry(
        year: '1890',
        text: 'The palace is completed.',
      ),
      TimelineEntry(
        year: 'Today',
        text: 'It remains the home of the Gaekwad family and welcomes visitors.',
      ),
    ],
    imageCredits: [],
  ),
  const Exhibit(
    id: 'exhibit_2',
    title: 'Durbar Hall',
    mac: '76:06:07:E1:A8:C3',
    tagline: 'Where the royal court gathered',
    era: "The palace's ceremonial heart",
    location: 'Inside the palace',
    story:
        'This double-height hall was built for royal gatherings and state ceremonies. Look down at the Venetian mosaic floor, then up at the Belgian stained-glass windows that scatter coloured light across the room. Crystal chandeliers and richly decorated walls complete the scene. In its heyday, the hall is said to have hosted 34 different kinds of durbar, each with its own rules of dress and salute. Today it occasionally welcomes concerts and cultural events.',
    didYouKnow:
        'In its heyday the hall is said to have held 34 different kinds of durbar, each with its own protocol.',
    heroImage: ExhibitAssetPaths.exhibit2Hero,
    thumbImage: ExhibitAssetPaths.exhibit2Thumb,
    galleryImages: [
      ExhibitAssetPaths.exhibit2Gallery1,
      ExhibitAssetPaths.exhibit2Gallery2,
      ExhibitAssetPaths.exhibit2Gallery3,
    ],
    audioAsset: ExhibitAssetPaths.durbarHallAudio, // Only Durbar Hall has audio
    videoAsset: null, // Exhibit 2 has NO video
    quickFacts: [
      QuickFact(
        icon: Icons.grid_view,
        label: 'Floor',
        value: 'Venetian mosaic',
      ),
      QuickFact(
        icon: Icons.wb_sunny,
        label: 'Windows',
        value: 'Belgian stained glass',
      ),
      QuickFact(
        icon: Icons.light,
        label: 'Lighting',
        value: 'Grand crystal chandeliers',
      ),
    ],
    timeline: [
      TimelineEntry(
        year: '1890',
        text:
            'The palace is completed, with the Durbar Hall at its ceremonial centre.',
      ),
      TimelineEntry(
        year: '1890s',
        text: 'The Maharaja holds royal durbars here.',
      ),
      TimelineEntry(
        year: 'Today',
        text: 'The hall sometimes hosts concerts and cultural events.',
      ),
    ],
    imageCredits: [],
  ),
  const Exhibit(
    id: 'exhibit_3',
    title: 'Royal Gallery',
    mac: 'B5:3A:0C:BA:70:97',
    tagline: 'Art collected by a royal patron',
    era: 'Late 1800s to today',
    location: 'Palace and Maharaja Fateh Singh Museum',
    story:
        "Maharaja Sayajirao III was a great patron of the arts. He commissioned the celebrated painter Raja Ravi Varma, whose canvases of Hindu mythology and royal portraits are displayed in the palace and in the Maharaja Fateh Singh Museum in its grounds. The museum, which opened in 1961, occupies a building that was originally a school for the Maharaja's children. Take a moment to look closely at the colour, expression and detail in each painting.",
    didYouKnow:
        "The museum building was originally built as a school for the Maharaja's children.",
    heroImage: ExhibitAssetPaths.exhibit3Hero,
    thumbImage: ExhibitAssetPaths.exhibit3Thumb,
    galleryImages: [
      ExhibitAssetPaths.exhibit3Gallery1,
      ExhibitAssetPaths.exhibit3Gallery2,
      ExhibitAssetPaths.exhibit3Gallery3,
    ],
    audioAsset: null, // Exhibit 3 has NO audio
    videoAsset:
        ExhibitAssetPaths.royalGalleryVideo, // Only Royal Gallery has video
    quickFacts: [
      QuickFact(
        icon: Icons.palette,
        label: 'Artist',
        value: 'Raja Ravi Varma',
      ),
      QuickFact(
        icon: Icons.museum,
        label: 'Museum',
        value: 'Maharaja Fateh Singh Museum',
      ),
      QuickFact(
        icon: Icons.collections,
        label: 'Collection',
        value: 'Indian and European art',
      ),
    ],
    timeline: [
      TimelineEntry(
        year: 'Late 1800s',
        text: 'Raja Ravi Varma is commissioned by the Maharaja.',
      ),
      TimelineEntry(
        year: '1890',
        text: 'The palace is completed and receives the artworks.',
      ),
      TimelineEntry(
        year: '1961',
        text: 'The Maharaja Fateh Singh Museum opens.',
      ),
    ],
    imageCredits: [],
  ),
];

Exhibit? findExhibitByMac(String mac) {
  final cleanMac =
      mac.replaceAll(':', '').replaceAll('-', '').toLowerCase().trim();
  for (final exhibit in allExhibits) {
    if (exhibit.mac
            .replaceAll(':', '')
            .replaceAll('-', '')
            .toLowerCase()
            .trim() ==
        cleanMac) {
      return exhibit;
    }
  }
  return null;
}

bool isKnownBeaconMac(String mac) {
  return findExhibitByMac(mac) != null;
}
