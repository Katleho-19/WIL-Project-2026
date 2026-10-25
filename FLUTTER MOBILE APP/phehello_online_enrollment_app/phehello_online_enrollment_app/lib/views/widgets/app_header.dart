//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: app_header.dart defines AppHeader, the brown header bar shown at the top of
// nearly every screen (title, optional subtitle, back button and trailing widget).

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// AppHeader (class) - the brown screen header. title is the main text, subtitle an optional second
/// line, onBack (if given) shows a back arrow, leading is an optional widget before the title
/// (e.g. the school crest) and trailing an optional widget at the far right.
/// Brown screen header used on every screen of the design.
class AppHeader extends StatelessWidget {
  /// Constructor - only title is required.
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;

  /// build() - draws a full-width brown container that respects the phone's top safe area, with a row
  /// containing the optional back button, the optional leading widget, the title/subtitle column (each
  /// limited to two lines) and the optional trailing widget.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.brown,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(onBack != null ? 4 : 20, 14, 16, 16),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  tooltip: 'Back',
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE9DCCF),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
