import 'package:flutter/material.dart';

/// School crest (transparent PNG made from the school's official crest).
class SchoolCrest extends StatelessWidget {
  const SchoolCrest({super.key, this.height = 44});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/school_crest.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stack) =>
          Icon(Icons.school_rounded, size: height, color: Colors.white),
    );
  }
}
