import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vibration/vibration.dart';
import '../data/exhibits.dart';
import '../services/beacon_detector.dart';
import '../services/beacon_service.dart';
import '../services/exhibit_navigator.dart';
import '../theme/app_theme.dart';
import 'credits_screen.dart';
import 'developer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BeaconDetector _detector = BeaconDetector.instance;
  final BeaconService _beaconService = BeaconService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sandstone,
      appBar: AppBar(
        backgroundColor: AppColors.maroon,
        foregroundColor: AppColors.sandstone,
        title: Text(
          'Staff Settings',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.sandstone,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _detector,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Section 1: Detection Settings
              _buildSectionHeader(
                icon: Icons.tune,
                title: 'Detection Settings',
                subtitle: 'Fine-tune signal detection and exhibit transitions',
              ),
              const SizedBox(height: 12),
              _buildDetectionSettingsCard(),

              const SizedBox(height: 24),

              // Section 2: Tools
              _buildSectionHeader(
                icon: Icons.build_circle_outlined,
                title: 'Tools & Diagnostics',
                subtitle: 'Inspect BLE signals and simulate exhibit triggers',
              ),
              const SizedBox(height: 12),
              _buildToolsCard(context),

              const SizedBox(height: 24),

              // Section 3: Options
              _buildSectionHeader(
                icon: Icons.settings_suggest_outlined,
                title: 'Options',
                subtitle: 'Haptic feedback and visitor notifications',
              ),
              const SizedBox(height: 12),
              _buildOptionsCard(),

              const SizedBox(height: 36),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.maroon),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionSettingsCard() {
    final cfg = _detector.config;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Slider 1: RSSI Threshold
          _buildSliderItem(
            title: 'Detection Threshold',
            valueLabel: '${cfg.thresholdDbm.toInt()} dBm',
            explanation:
                'Minimum signal strength required for a beacon to trigger an exhibit.',
            value: cfg.thresholdDbm,
            min: -85.0,
            max: -40.0,
            divisions: 45,
            onChanged: (val) => _detector.setThreshold(val),
          ),
          const Divider(height: 24, color: AppColors.borderLight),

          // Slider 2: Very-Near Override
          _buildSliderItem(
            title: 'Very-Near Override',
            valueLabel: '${cfg.nearOverrideDbm.toInt()} dBm',
            explanation:
                'Signal level where walking right up to an exhibit switches immediately.',
            value: cfg.nearOverrideDbm,
            min: -70.0,
            max: -35.0,
            divisions: 35,
            onChanged: (val) => _detector.setNearOverride(val),
          ),
          const Divider(height: 24, color: AppColors.borderLight),

          // Slider 3: Hysteresis
          _buildSliderItem(
            title: 'Hysteresis Lead',
            valueLabel: '${cfg.hysteresisDb.toStringAsFixed(1)} dB',
            explanation:
                'How much stronger a new beacon must be than the current exhibit to switch.',
            value: cfg.hysteresisDb,
            min: 1.0,
            max: 15.0,
            divisions: 28,
            onChanged: (val) => _detector.setHysteresis(val),
          ),
          const Divider(height: 24, color: AppColors.borderLight),

          // Slider 4: Lead Time
          _buildSliderItem(
            title: 'Continuous Lead Time',
            valueLabel: '${cfg.leadTimeMs} ms',
            explanation:
                'Time a new beacon must continuously beat the current exhibit before switching.',
            value: cfg.leadTimeMs.toDouble(),
            min: 0.0,
            max: 3000.0,
            divisions: 30,
            onChanged: (val) => _detector.setLeadTime(val.toInt()),
          ),
          const Divider(height: 24, color: AppColors.borderLight),

          // Slider 5: Same-Exhibit Cooldown
          _buildSliderItem(
            title: 'Same-Exhibit Cooldown',
            valueLabel: '${(cfg.cooldownMs / 1000).toInt()} s',
            explanation:
                'Delay before an exhibit that was just closed can be reopened automatically.',
            value: (cfg.cooldownMs / 1000).toDouble(),
            min: 1.0,
            max: 20.0,
            divisions: 19,
            onChanged: (val) => _detector.setCooldown((val * 1000).toInt()),
          ),
          const SizedBox(height: 16),

          // Reset to Defaults Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.maroon,
              side: const BorderSide(color: AppColors.maroon, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.restore, size: 18),
            label: Text(
              'Reset to Defaults',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: _confirmResetDefaults,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderItem({
    required String title,
    required String valueLabel,
    required String explanation,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.maroon,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                valueLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandstone,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          explanation,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: AppColors.textMuted,
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.maroon,
            inactiveTrackColor: AppColors.borderLight,
            thumbColor: AppColors.gold,
            overlayColor: AppColors.gold.withValues(alpha: 0.2),
            trackHeight: 3.5,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToolsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          // Beacon Diagnostics ListTile
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.maroon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.analytics_outlined,
                  color: AppColors.maroon, size: 22),
            ),
            title: Text(
              'Beacon Diagnostics',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: AppColors.darkBrown,
              ),
            ),
            subtitle: Text(
              'Live scanner, active subscriptions (${_beaconService.activeSubscriptionCount}), decision log',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DeveloperScreen()),
              );
            },
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Simulate Exhibit ListTile
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.play_circle_outline,
                  color: AppColors.gold, size: 22),
            ),
            title: Text(
              'Simulate Exhibit',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: AppColors.darkBrown,
              ),
            ),
            subtitle: Text(
              'Trigger and preview any exhibit story without BLE beacons',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textMuted),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () => _showSimulateDialog(context),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Photo Credits ListTile
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.deepMaroon.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.photo_library_outlined,
                  color: AppColors.deepMaroon, size: 22),
            ),
            title: Text(
              'Photo Credits',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: AppColors.darkBrown,
              ),
            ),
            subtitle: Text(
              'Attributions, licenses & sources for palace media assets',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppColors.textMuted),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreditsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: AppTheme.softShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Haptic Feedback (Vibration)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vibrate on arrival banner and exhibit detection',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _detector.vibrationEnabled,
                activeThumbColor: AppColors.maroon,
                activeTrackColor: AppColors.gold.withValues(alpha: 0.4),
                onChanged: (val) => _detector.setVibrationEnabled(val),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkBrown,
              side: const BorderSide(color: AppColors.borderLight, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
            icon: const Icon(Icons.vibration, size: 18, color: AppColors.maroon),
            label: Text(
              'Test Vibration Pulse',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            onPressed: () async {
              try {
                if (await Vibration.hasVibrator() == true) {
                  await Vibration.vibrate(duration: 150);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vibration pulse triggered!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                }
              } catch (_) {}
            },
          ),
        ],
      ),
    );
  }

  void _confirmResetDefaults() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.cardRadius),
        title: Text(
          'Reset Detection Defaults?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: AppColors.maroon,
          ),
        ),
        content: Text(
          'This will reset detection parameters to the recommended defaults:\n\n'
          '• Threshold: ${AppConstants.defaultThreshold.toInt()} dBm\n'
          '• Very-Near Override: ${AppConstants.defaultNearOverride.toInt()} dBm\n'
          '• Hysteresis: ${AppConstants.defaultHysteresis.toStringAsFixed(1)} dB\n'
          '• Continuous Lead Time: ${AppConstants.defaultLeadTime} ms\n'
          '• Cooldown: ${(AppConstants.defaultCooldown / 1000).toInt()} s',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.darkBrown),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppColors.textMuted),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.maroon,
              foregroundColor: AppColors.sandstone,
            ),
            child: Text(
              'Reset to Defaults',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _detector.setThreshold(AppConstants.defaultThreshold);
              await _detector.setNearOverride(AppConstants.defaultNearOverride);
              await _detector.setHysteresis(AppConstants.defaultHysteresis);
              await _detector.setLeadTime(AppConstants.defaultLeadTime);
              await _detector.setCooldown(AppConstants.defaultCooldown);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Detection parameters reset to defaults.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSimulateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Simulate Exhibit Arrival',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.maroon,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap an exhibit below to trigger its arrival banner and story.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...allExhibits.map(
              (exhibit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardSurfaceAlt,
                    foregroundColor: AppColors.darkBrown,
                    elevation: 0,
                    side: const BorderSide(
                        color: AppColors.borderLight, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                  icon: const Icon(Icons.museum_outlined,
                      color: AppColors.maroon),
                  label: Text(
                    exhibit.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ExhibitNavigator.openExhibit(exhibit, isAutomatic: false);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
