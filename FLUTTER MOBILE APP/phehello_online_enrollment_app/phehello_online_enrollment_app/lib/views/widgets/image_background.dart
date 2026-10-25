//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: image_background.dart defines ImageBackground, the full-screen photo background with a
// dark brown tint used behind the login and registration screens.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// ImageBackground (class) - stacks 'child' on top of a full-screen photo covered by a brown gradient so
/// white text stays readable. If the photo file is missing it falls back to a brown gradient.
/// Full-screen photo background with a dark brown tint so white text stays
/// readable (the look of the Figma login screen).
///
/// If the image file is missing, it falls back to the brown gradient, so the
/// app still runs before you add the photo.
class ImageBackground extends StatelessWidget {
  /// Constructor - child is required; image defaults to defaultImage.
  const ImageBackground({
    super.key,
    required this.child,
    this.image = defaultImage,
  });

  /// defaultImage - the asset path of the default background photo.
  static const String defaultImage = 'assets/images/login_background.jpg';

  final Widget child;
  final String image;

  /// build() - a Stack with three layers: the photo (or the brown gradient if it fails to load), a tint that is
  /// lighter at the top and darker at the bottom, and finally the child content.
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          image,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8A5A3A),
                  AppColors.brown,
                  AppColors.brownDark,
                ],
              ),
            ),
          ),
        ),
        // Brown tint: lighter at the top so the photo shows, darker at the
        // bottom behind the form fields.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.brownDark.withValues(alpha: 0.55),
                AppColors.brown.withValues(alpha: 0.78),
                AppColors.brownDark.withValues(alpha: 0.94),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
