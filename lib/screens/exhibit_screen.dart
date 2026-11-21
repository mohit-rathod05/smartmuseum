import 'dart:async';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';
import '../data/exhibits.dart';
import '../services/asset_checker.dart';
import '../services/beacon_detector.dart';
import '../services/exhibit_navigator.dart';
import '../theme/app_theme.dart';
import '../widgets/palace_decorations.dart';

class ExhibitScreen extends StatefulWidget {
  final Exhibit exhibit;

  const ExhibitScreen({super.key, required this.exhibit});

  /// Stops all playing audio and video across any active exhibit screen.
  static void stopAllMedia() {
    _ExhibitScreenState.activeInstance?.stopMedia();
  }

  @override
  State<ExhibitScreen> createState() => _ExhibitScreenState();
}

class _ExhibitScreenState extends State<ExhibitScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static _ExhibitScreenState? activeInstance;

  // Scroll & Parallax
  late final ScrollController _scrollController;
  double _scrollOffset = 0.0;

  // Favorite toggle
  bool _isFavorite = false;

  // Story expand toggle
  bool _isStoryExpanded = false;

  // Audio Player State
  AudioPlayer? _audioPlayer;
  PlayerState _audioPlayerState = PlayerState.stopped;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _audioHasError = false;
  double _playbackRate = 1.0;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  // Waveform animation
  late final AnimationController _waveformController;

  // Video Player State
  VideoPlayerController? _videoController;
  bool _videoHasError = false;
  bool _videoIsInitialized = false;
  bool _showVideoControls = true;
  Timer? _videoControlsTimer;

  // Gallery PageController
  late final PageController _galleryPageController;
  int _activeGalleryIndex = 0;

  @override
  void initState() {
    super.initState();
    activeInstance = this;
    WidgetsBinding.instance.addObserver(this);
    BeaconDetector.instance.onExhibitOpened(widget.exhibit);

    _scrollController = ScrollController()
      ..addListener(() {
        if (mounted) {
          setState(() {
            _scrollOffset = _scrollController.offset;
          });
        }
      });

    _galleryPageController = PageController();

    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _initAudio();
    _initVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _pauseMedia();
    }
  }

  void _pauseMedia() {
    try {
      _audioPlayer?.pause();
      _videoController?.pause();
      _waveformController.stop();
    } catch (_) {}
  }

  void stopMedia() {
    try {
      _audioPlayer?.stop();
      _audioPlayerState = PlayerState.stopped;
      _videoController?.pause();
      _waveformController.stop();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _initAudio() {
    final asset = widget.exhibit.audioAsset;
    if (asset == null || asset.isEmpty || !AssetChecker.hasAsset(asset)) {
      return;
    }

    try {
      _audioPlayer = AudioPlayer();
      _playerStateSubscription =
          _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() => _audioPlayerState = state);
          if (state == PlayerState.playing) {
            _waveformController.repeat();
          } else {
            _waveformController.stop();
          }
        }
      });
      _durationSubscription = _audioPlayer!.onDurationChanged.listen((dur) {
        if (mounted) setState(() => _audioDuration = dur);
      });
      _positionSubscription = _audioPlayer!.onPositionChanged.listen((pos) {
        if (mounted) setState(() => _audioPosition = pos);
      });
    } catch (e) {
      _audioHasError = true;
    }
  }

  Future<void> _toggleAudio() async {
    final asset = widget.exhibit.audioAsset;
    if (_audioPlayer == null ||
        _audioHasError ||
        asset == null ||
        !AssetChecker.hasAsset(asset)) {
      return;
    }

    final path =
        asset.startsWith('assets/') ? asset.substring('assets/'.length) : asset;

    try {
      if (_audioPlayerState == PlayerState.playing) {
        await _audioPlayer!.pause();
      } else {
        if (_audioPlayerState == PlayerState.paused) {
          await _audioPlayer!.resume();
        } else {
          await _audioPlayer!.play(AssetSource(path));
          await _audioPlayer!.setPlaybackRate(_playbackRate);
        }
      }
    } catch (e) {
      setState(() => _audioHasError = true);
    }
  }

  Future<void> _togglePlaybackRate() async {
    if (_audioPlayer == null) {
      return;
    }
    final newRate = _playbackRate == 1.0 ? 1.5 : 1.0;
    setState(() => _playbackRate = newRate);
    try {
      await _audioPlayer!.setPlaybackRate(newRate);
    } catch (_) {}
  }

  void _initVideo() {
    final asset = widget.exhibit.videoAsset;
    if (asset == null || asset.isEmpty || !AssetChecker.hasAsset(asset)) {
      return;
    }

    try {
      _videoController = VideoPlayerController.asset(asset)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _videoIsInitialized = true;
            });
          }
        }).catchError((e) {
          if (mounted) {
            setState(() {
              _videoHasError = true;
            });
          } else {
            _videoHasError = true;
          }
        });
      _videoController?.addListener(() {
        if (mounted) setState(() {});
      });
    } catch (e) {
      _videoHasError = true;
    }
  }

  void _toggleVideo() {
    if (_videoController == null || !_videoIsInitialized) {
      return;
    }

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _showVideoControls = true;
        _videoControlsTimer?.cancel();
      } else {
        _videoController!.play();
        _videoControlsTimer?.cancel();
        _videoControlsTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _videoController!.value.isPlaying) {
            setState(() => _showVideoControls = false);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    if (activeInstance == this) activeInstance = null;
    WidgetsBinding.instance.removeObserver(this);
    _videoControlsTimer?.cancel();
    _pauseMedia();
    BeaconDetector.instance.onExhibitClosed(widget.exhibit.id);

    _scrollController.dispose();
    _galleryPageController.dispose();
    _waveformController.dispose();

    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.45;
    final topPadding = MediaQuery.of(context).padding.top;

    final hasAudio = widget.exhibit.audioAsset != null &&
        AssetChecker.hasAsset(widget.exhibit.audioAsset);
    final hasVideo = widget.exhibit.videoAsset != null &&
        AssetChecker.hasAsset(widget.exhibit.videoAsset);
    final availableGallery =
        AssetChecker.filterExisting(widget.exhibit.galleryImages);

    return Scaffold(
      backgroundColor: AppColors.deepCharcoal,
      body: Stack(
        children: [
          // 1. Parallax Hero Background (Stays at the top, moves at 0.45 speed)
          Positioned(
            top: -_scrollOffset * 0.45,
            left: 0,
            right: 0,
            height: heroHeight,
            child: _buildHeroHeader(heroHeight),
          ),

          // 2. Scrolling Sheet overlapping hero
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Invisible spacer to reveal hero
                  SizedBox(height: heroHeight - 32),

                  // Rounded Sheet
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.ivory,
                      borderRadius: AppTheme.sheetRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, -6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Pill indicator
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.borderLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 1: Quick Facts
                        if (widget.exhibit.quickFacts.isNotEmpty) ...[
                          _buildQuickFacts(),
                          const SizedBox(height: 20),
                          const GoldOrnamentalDivider(),
                          const SizedBox(height: 20),
                        ],

                        // Section 2: The Story
                        _buildStoryCard(),
                        const SizedBox(height: 18),

                        // Section 2b: Did You Know? Callout
                        if (widget.exhibit.didYouKnow.isNotEmpty) ...[
                          _buildDidYouKnowCard(),
                          const SizedBox(height: 20),
                          const GoldOrnamentalDivider(),
                          const SizedBox(height: 20),
                        ] else ...[
                          const SizedBox(height: 10),
                          const GoldOrnamentalDivider(),
                          const SizedBox(height: 20),
                        ],

                        // Section 3: Audio Player Card
                        if (hasAudio) ...[
                          _buildAudioCard(),
                          const SizedBox(height: 20),
                          const GoldOrnamentalDivider(),
                          const SizedBox(height: 20),
                        ],

                        // Section 4: Photo Gallery Carousel
                        if (availableGallery.isNotEmpty) ...[
                          _buildGallerySection(availableGallery),
                          const SizedBox(height: 20),
                          const GoldOrnamentalDivider(),
                          const SizedBox(height: 20),
                        ],

                        // Section 5: Video Card
                        if (hasVideo) ...[
                          _buildVideoCard(),
                          const SizedBox(height: 20),
                          const GoldOrnamentalDivider(),
                          const SizedBox(height: 20),
                        ],

                        // Section 6: Historical Timeline
                        if (widget.exhibit.timeline.isNotEmpty) ...[
                          _buildTimelineSection(),
                          const SizedBox(height: 20),
                          const GoldOrnamentalDivider(),
                          const SizedBox(height: 20),
                        ],

                        // Section 7: Next Stop Recommendation
                        _buildNextStopCard(),
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Floating App Bar (Back button + Favorite button)
          Positioned(
            top: topPadding + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back_rounded,
                  tooltip: 'Back to Guide',
                  onTap: () => Navigator.of(context).pop(),
                ),
                _buildCircleButton(
                  icon: _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  iconColor:
                      _isFavorite ? AppColors.royalMaroon : Colors.white,
                  tooltip: 'Save Exhibit',
                  onTap: () {
                    setState(() => _isFavorite = !_isFavorite);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.royalMaroon,
                        content: Text(
                          _isFavorite
                              ? 'Saved ${widget.exhibit.title} to favourites'
                              : 'Removed from favourites',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.ivory,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Hero Header with Title & Tagline ---
  Widget _buildHeroHeader(double height) {
    final hasHero = AssetChecker.hasAsset(widget.exhibit.heroImage);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero Image with Ken Burns zoom or fallback placeholder
        if (hasHero)
          Hero(
            tag: 'exhibit_hero_${widget.exhibit.id}',
            child: Image.asset(
              widget.exhibit.heroImage,
              fit: BoxFit.cover,
              cacheWidth: 1200,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.05, 1.05),
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeOut,
              )
        else
          ExhibitImagePlaceholder(
            title: widget.exhibit.title,
            height: height,
          ),

        // Dark Atmospheric Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.45),
                Colors.transparent,
                AppColors.deepCharcoal.withValues(alpha: 0.8),
                AppColors.deepCharcoal,
              ],
              stops: const [0.0, 0.35, 0.72, 1.0],
            ),
          ),
        ),

        // Bottom Title & Chips over hero
        Positioned(
          left: 20,
          right: 20,
          bottom: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Era & Location Chips
              Row(
                children: [
                  if (widget.exhibit.era.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.antiqueGold,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.antiqueGold.withValues(alpha: 0.35),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Text(
                        widget.exhibit.era.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.deepCharcoal,
                        ),
                      ),
                    ),
                  if (widget.exhibit.location.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          widget.exhibit.location,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ivory,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),

              // Title in Playfair Display
              Text(
                widget.exhibit.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                  height: 1.15,
                  shadows: const [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              if (widget.exhibit.tagline.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.exhibit.tagline,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ivory.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // --- Top Circular Translucent Action Buttons ---
  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    required String tooltip,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.deepCharcoal.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  // --- 1. Quick Facts Row ---
  Widget _buildQuickFacts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARCHITECTURAL HIGHLIGHTS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: AppColors.royalMaroon,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.exhibit.quickFacts.length,
            separatorBuilder: (_, index) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final fact = widget.exhibit.quickFacts[i];
              return Container(
                width: 130,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 1.0),
                  boxShadow: AppTheme.cardElevation,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(fact.icon, size: 20, color: AppColors.antiqueGold),
                    const SizedBox(height: 6),
                    Text(
                      fact.label.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      fact.value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepCharcoal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // --- 2. The Story Card ---
  Widget _buildStoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.borderLight, width: 1.0),
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
                  Icons.auto_stories_rounded,
                  size: 20,
                  color: AppColors.royalMaroon,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE STORY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.royalMaroon,
                    ),
                  ),
                  Text(
                    'Heritage & History',
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
          Text(
            widget.exhibit.story,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              height: 1.65,
              color: AppColors.deepCharcoal,
            ),
            maxLines: _isStoryExpanded ? null : 4,
            overflow:
                _isStoryExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() => _isStoryExpanded = !_isStoryExpanded);
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isStoryExpanded ? 'Read less' : 'Read more',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.royalMaroon,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isStoryExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.royalMaroon,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.1, end: 0);
  }

  // --- 2b. Did You Know? Callout Card ---
  Widget _buildDidYouKnowCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warmSandstone.withValues(alpha: 0.6),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(
          color: AppColors.antiqueGold.withValues(alpha: 0.45),
          width: 1.0,
        ),
        boxShadow: AppTheme.cardElevation,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.antiqueGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 20,
              color: AppColors.royalMaroon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DID YOU KNOW?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.royalMaroon,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.exhibit.didYouKnow,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.5,
                    color: AppColors.deepCharcoal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 110.ms).slideY(begin: 0.1, end: 0);
  }

  // --- 3. Audio Player Card ---
  Widget _buildAudioCard() {
    final isPlaying = _audioPlayerState == PlayerState.playing;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: AppTheme.cardElevation,
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.antiqueGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.headphones_rounded,
                      size: 20,
                      color: AppColors.antiqueGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AUDIO GUIDE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.antiqueGold,
                        ),
                      ),
                      Text(
                        'Audio Narration Guide',
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
              // Playback Speed Toggle (1x / 1.5x)
              InkWell(
                onTap: _togglePlaybackRate,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warmSandstone,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.borderLight, width: 1.0),
                  ),
                  child: Text(
                    '${_playbackRate.toStringAsFixed(1)}x',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepCharcoal,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Waveform Animation Visualizer
          _WaveformBars(
            controller: _waveformController,
            isPlaying: isPlaying,
            color: AppColors.antiqueGold,
          ),
          const SizedBox(height: 14),

          // Slider Progress
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: AppColors.antiqueGold,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.antiqueGold,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: (_audioDuration.inMilliseconds > 0 &&
                      _audioPosition.inMilliseconds <=
                          _audioDuration.inMilliseconds)
                  ? _audioPosition.inMilliseconds.toDouble()
                  : 0.0,
              max: _audioDuration.inMilliseconds > 0
                  ? _audioDuration.inMilliseconds.toDouble()
                  : 1.0,
              onChanged: (val) {
                _audioPlayer?.seek(Duration(milliseconds: val.toInt()));
              },
            ),
          ),

          // Time labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_audioPosition),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  _formatDuration(_audioDuration),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Play / Pause Button with Gold Morph
          Center(
            child: GestureDetector(
              onTap: _toggleAudio,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.goldLight, AppColors.antiqueGold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.antiqueGold.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: AppColors.deepCharcoal,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 140.ms).slideY(begin: 0.1, end: 0);
  }

  // --- 4. Photo Gallery Carousel ---
  Widget _buildGallerySection(List<String> availableGallery) {
    final activeIndex = _activeGalleryIndex.clamp(0, availableGallery.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PHOTO GALLERY',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: AppColors.royalMaroon,
              ),
            ),
            Text(
              '${activeIndex + 1} of ${availableGallery.length}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _galleryPageController,
              itemCount: availableGallery.length,
              onPageChanged: (idx) {
                setState(() => _activeGalleryIndex = idx);
              },
              itemBuilder: (context, i) {
                final imgPath = availableGallery[i];
                return GestureDetector(
                  onTap: () => _openFullscreenGallery(context, availableGallery, i),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imgPath,
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.zoom_in,
                                  size: 15, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Tap to zoom',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            availableGallery.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: activeIndex == idx ? 20 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: activeIndex == idx
                    ? AppColors.antiqueGold
                    : AppColors.borderLight,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  void _openFullscreenGallery(BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => _FullscreenGalleryDialog(
        images: images,
        initialIndex: initialIndex,
      ),
    );
  }

  // --- 5. Video Card ---
  Widget _buildVideoCard() {
    final isPlaying =
        _videoIsInitialized && _videoController!.value.isPlaying;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.borderLight, width: 1.0),
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
                  Icons.videocam_rounded,
                  size: 20,
                  color: AppColors.royalMaroon,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ARCHIVAL FOOTAGE',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.royalMaroon,
                    ),
                  ),
                  Text(
                    'Archival Video Footage',
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

          // Video Player Box
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_videoHasError)
                    Container(
                      color: AppColors.deepCharcoal,
                      child: Center(
                        child: Text(
                          'Video unavailable',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.ivory,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else if (_videoIsInitialized)
                    VideoPlayer(_videoController!)
                  else if (AssetChecker.hasAsset(widget.exhibit.heroImage))
                    Image.asset(
                      widget.exhibit.heroImage,
                      fit: BoxFit.cover,
                      cacheWidth: 600,
                    )
                  else
                    ExhibitImagePlaceholder(
                      title: widget.exhibit.title,
                    ),

                  // Tap to Play / Pause Overlay
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _toggleVideo,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: (_showVideoControls || !isPlaying) ? 1.0 : 0.0,
                      child: Container(
                        color: Colors.black45,
                        child: Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.antiqueGold,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.antiqueGold.withValues(alpha: 0.45),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 32,
                              color: AppColors.deepCharcoal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Fullscreen toggle button
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen, color: Colors.white),
                      tooltip: 'Fullscreen Video',
                      onPressed: () => _openFullscreenVideo(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 240.ms).slideY(begin: 0.1, end: 0);
  }

  void _openFullscreenVideo(BuildContext context) {
    if (_videoController == null || !_videoIsInitialized) {
      return;
    }
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => _FullscreenVideoDialog(controller: _videoController!),
    );
  }

  // --- 6. Historical Timeline Section ---
  Widget _buildTimelineSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.borderLight, width: 1.0),
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
                  Icons.timeline_rounded,
                  size: 20,
                  color: AppColors.royalMaroon,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHRONOLOGY',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.royalMaroon,
                    ),
                  ),
                  Text(
                    'Historical Timeline',
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
          const SizedBox(height: 18),

          // Vertical timeline list
          ...widget.exhibit.timeline.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isLast = idx == widget.exhibit.timeline.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dot and Line
                  Column(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.antiqueGold,
                          border: Border.all(
                            color: AppColors.deepCharcoal,
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.antiqueGold.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: AppColors.borderLight,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Text content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.warmSandstone,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.year,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.royalMaroon,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.text,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: AppColors.deepCharcoal,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 280.ms).slideY(begin: 0.1, end: 0);
  }

  // --- 7. Next Stop Card ---
  Widget _buildNextStopCard() {
    final nextIndex =
        (allExhibits.indexOf(widget.exhibit) + 1) % allExhibits.length;
    final nextExhibit = allExhibits[nextIndex];
    final hasNextThumb = AssetChecker.hasAsset(nextExhibit.thumbImage);

    return InkWell(
      onTap: () {
        ExhibitNavigator.openExhibit(nextExhibit, isAutomatic: false);
      },
      borderRadius: AppTheme.cardRadius,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.deepCharcoal,
          borderRadius: AppTheme.cardRadius,
          boxShadow: [
            BoxShadow(
              color: AppColors.deepCharcoal.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Thumbnail in Pointed Arch Clipper
            ClipPath(
              clipper: const PointedArchClipper(shoulderRatio: 0.18),
              child: hasNextThumb
                  ? Image.asset(
                      nextExhibit.thumbImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      cacheWidth: 300,
                    )
                  : ExhibitImagePlaceholder(
                      title: nextExhibit.title,
                      width: 60,
                      height: 60,
                    ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT IN PALACE TOUR',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AppColors.antiqueGold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextExhibit.title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ivory,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    nextExhibit.tagline,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.ivory.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.antiqueGold,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 320.ms).slideY(begin: 0.1, end: 0);
  }
}

// --- Animated Audio Waveform Visualizer ---
class _WaveformBars extends StatelessWidget {
  final AnimationController controller;
  final bool isPlaying;
  final Color color;

  const _WaveformBars({
    required this.controller,
    required this.isPlaying,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    const barCount = 22;
    return SizedBox(
      height: 32,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              double height;
              if (isPlaying) {
                final progress = controller.value * 2 * math.pi;
                final wave = math.sin(progress + (i * 0.45));
                height = 8.0 + (wave.abs() * 22.0);
              } else {
                height = 4.0;
              }
              return Container(
                width: 3.2,
                height: height,
                decoration: BoxDecoration(
                  color: isPlaying ? color : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// --- Fullscreen Pinch-to-Zoom Gallery Dialog ---
class _FullscreenGalleryDialog extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullscreenGalleryDialog({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGalleryDialog> createState() =>
      _FullscreenGalleryDialogState();
}

class _FullscreenGalleryDialogState extends State<_FullscreenGalleryDialog> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (context, i) {
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.asset(
                    widget.images[i],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  '${_currentIndex + 1} / ${widget.images.length}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Fullscreen Video Dialog ---
class _FullscreenVideoDialog extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenVideoDialog({required this.controller});

  @override
  State<_FullscreenVideoDialog> createState() => _FullscreenVideoDialogState();
}

class _FullscreenVideoDialogState extends State<_FullscreenVideoDialog> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: VideoPlayer(widget.controller),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit,
                  color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
