//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: buttons.dart defines the app's three reusable button styles: the main filled
// button, the outlined button and the small outlined button.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// PrimaryButton (class) - the main full-width button (height 52). It is brown by default, gold if
/// gold is true, or white if white is true. loading shows a spinner and disables the button; icon is
/// an optional leading icon; onPressed is the tap action (null disables the button).
class PrimaryButton extends StatelessWidget {
  /// Constructor - label and onPressed are required; the other options are optional.
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.gold = false,
    this.white = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool gold;
  final bool white;
  final IconData? icon;

  /// build() - chooses the background and text colours from the options, then draws an ElevatedButton
  /// with rounded corners that shows either the spinner (while loading) or the optional icon and label.
  @override
  Widget build(BuildContext context) {
    final Color bg = gold
        ? AppColors.gold
        : white
        ? Colors.white
        : AppColors.brown;
    final Color fg = gold || white ? AppColors.brownDark : Colors.white;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: bg.withValues(alpha: 0.6),
          disabledForegroundColor: fg.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// OutlineBrandButton (class) - a full-width white button with a coloured outline. It is brown, or red when
/// danger is true (for destructive actions such as delete); height defaults to 48.
class OutlineBrandButton extends StatelessWidget {
  /// Constructor - label and onPressed are required.
  const OutlineBrandButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
    this.height = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
  final double height;

  /// build() - picks the colour from the danger flag and draws an OutlinedButton with the optional icon and the label.
  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.error : AppColors.brown;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          backgroundColor: Colors.white,
          side: BorderSide(color: color, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 19),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SmallOutlineButton (class) - a compact outlined button (e.g. "Upload" or "Replace") used inside document tiles.
/// Small outlined "Upload" button used inside document tiles.
class SmallOutlineButton extends StatelessWidget {
  /// Constructor - label and onPressed are required.
  const SmallOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  /// build() - draws a small brown-outlined button with rounded corners and bold label text.
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brown,
        side: const BorderSide(color: AppColors.brown, width: 1.3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        minimumSize: const Size(0, 34),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
      ),
    );
  }
}
