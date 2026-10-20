import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Full-screen photo background with a dark brown tint so white text stays
/// readable (the look of the Figma login screen).
///
/// If the image file is missing, it falls back to the brown gradient, so the
/// app still runs before you add the photo.
class ImageBackground extends StatelessWidget {
  const ImageBackground({
    super.key,
    required this.child,
    this.image = defaultImage,
  });

  static const String defaultImage = 'assets/images/login_background.jpg';

  final Widget child;
  final String image;

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
