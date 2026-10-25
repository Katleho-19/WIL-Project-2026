//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: app_card.dart defines AppCard, the white rounded card with a thin border that is
// used throughout the app to group content.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// AppCard (class) - a rounded, bordered container. It shows 'child' with the given padding and
/// background colour; if onTap is provided the whole card becomes tappable with a ripple effect.
class AppCard extends StatelessWidget {
  /// Constructor - child is required; padding defaults to 16, color to white, onTap is optional.
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;

  /// build() - creates the shared decoration (rounded corners, border). Without onTap it returns a plain
  /// full-width container; with onTap it wraps the card in Material + InkWell so it reacts to taps.
  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border, width: 1.3),
    );
    if (onTap == null) {
      return Container(
        width: double.infinity,
        padding: padding,
        decoration: decoration,
        child: child,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          width: double.infinity,
          padding: padding,
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}
