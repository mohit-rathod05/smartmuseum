import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class PinDialog extends StatefulWidget {
  const PinDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const PinDialog(),
    );
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String _enteredPin = '';
  bool _hasError = false;
  int _shakeTrigger = 0;

  void _onDigitPress(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _hasError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == AppConstants.hiddenSettingsPin) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    } else {
      setState(() {
        _hasError = true;
        _enteredPin = '';
        _shakeTrigger++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.gold, width: 1.5),
          boxShadow: AppTheme.softShadow,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shield Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.maroon.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.maroon,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Text(
              'Staff Access',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.maroon,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter 4-digit PIN for hidden settings',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),

            // 4 PIN Dot indicators with shake animation
            Animate(
              key: ValueKey(_shakeTrigger),
              effects: _shakeTrigger > 0
                  ? [
                      ShakeEffect(
                        duration: const Duration(milliseconds: 400),
                        hz: 4,
                        offset: const Offset(8, 0),
                      )
                    ]
                  : const [],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppColors.maroon
                          : AppColors.borderLight,
                      border: Border.all(
                        color: _hasError
                            ? Colors.redAccent
                            : (isFilled ? AppColors.gold : AppColors.borderLight),
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),
            ),

            if (_hasError) ...[
              const SizedBox(height: 10),
              Text(
                'Incorrect PIN. Please try again.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ] else
              const SizedBox(height: 14),

            const SizedBox(height: 10),

            // Keypad
            _buildKeypad(),

            const SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _buildKeypadRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _buildKeypadRow(['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 60, height: 50),
            _buildKeypadButton('0'),
            SizedBox(
              width: 60,
              height: 50,
              child: IconButton(
                icon: const Icon(Icons.backspace_outlined,
                    size: 20, color: AppColors.darkBrown),
                onPressed: _onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_buildKeypadButton).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return Container(
      width: 60,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.cardSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onDigitPress(digit),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBrown,
            ),
          ),
        ),
      ),
    );
  }
}
