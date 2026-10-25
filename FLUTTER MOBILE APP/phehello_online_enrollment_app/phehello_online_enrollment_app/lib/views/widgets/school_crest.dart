//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: school_crest.dart defines SchoolCrest, the widget that shows the school's logo.

import 'package:flutter/material.dart';

/// SchoolCrest (class) - shows the school crest image at the given height (default 44).
/// School crest (transparent PNG made from the school's official crest).
class SchoolCrest extends StatelessWidget {
  /// Constructor - height is optional.
  const SchoolCrest({super.key, this.height = 44});

  final double height;

  /// build() - loads assets/images/school_crest.png scaled to fit. If the image file is missing, the
  /// errorBuilder shows a white school icon instead so the app still works.
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
