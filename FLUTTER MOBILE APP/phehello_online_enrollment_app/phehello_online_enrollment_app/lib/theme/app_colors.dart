//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: app_colors.dart defines every colour used by the app in one place, so the look
// stays consistent (brown and white palette plus status colours).

import 'package:flutter/material.dart';

/// Brown and white palette sampled from the supplied interface designs
/// (stakeholder-approved colours, SRS Part D).
///
/// AppColors (class) - static-only colour constants; the private constructor AppColors._()
/// prevents instances. Colours are written as 0xAARRGGBB hex values.
class AppColors {
  AppColors._();

  // Main brand and surface colours.
  static const Color brown = Color(
    0xFF5B3825,
  ); // primary brand colour (buttons, headers)
  static const Color brownDark = Color(
    0xFF3F271A,
  ); // darker brown (snack bars, gradients)
  static const Color background = Color(
    0xFFFEFDF9,
  ); // off-white page background
  static const Color gold = Color(0xFFC9A227); // accent / secondary colour
  static const Color beige = Color(0xFFF0E4CA); // soft highlight background
  static const Color tile = Color(0xFFF4EEE4); // card/tile background
  static const Color border = Color(0xFFE8DFCF); // outlines and dividers
  static const Color textDark = Color(0xFF2B1B12); // main text colour
  static const Color textMuted = Color(
    0xFF8A7C72,
  ); // secondary/hint text colour
  static const Color error = Color(0xFFB3261E); // error and warning red

  // Status chip colours: Bg = chip background, Fg = text/icon colour.
  static const Color pendingBg = Color(0xFFFCEFC0); // pending: light yellow
  static const Color pendingFg = Color(0xFF7A5B00);
  static const Color approvedBg = Color(0xFFDFF1DF); // approved: light green
  static const Color approvedFg = Color(0xFF2E7D32);
  static const Color rejectedBg = Color(0xFFFADBDB); // rejected: light red
  static const Color rejectedFg = Color(0xFFB3261E);
  static const Color correctionBg = Color(
    0xFFFBE3CF,
  ); // corrections requested: light orange
  static const Color correctionFg = Color(0xFF9A4A00);
}
