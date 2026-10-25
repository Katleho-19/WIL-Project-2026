//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: app_bottom_nav.dart defines the bottom navigation bar of the main app
// (Home, Applications, Alerts, Profile) with an optional dot on the Alerts tab.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// AppBottomNav (class) - the bottom navigation bar widget.
/// currentIndex is the selected tab, onTap is called with the tapped tab's index, and showAlertDot
/// shows a small gold dot on the Alerts tab when there are unread notifications.
/// Bottom navigation: Home, Applications, Alerts, Profile.
class AppBottomNav extends StatelessWidget {
  /// Constructor - currentIndex and onTap are required; showAlertDot defaults to false.
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showAlertDot = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showAlertDot;

  /// _items - the icon and label of each of the four tabs, in order.
  static const _items = <(IconData, String)>[
    (Icons.home_outlined, 'Home'),
    (Icons.list_alt_outlined, 'Applications'),
    (Icons.notifications_none_rounded, 'Alerts'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  /// build() - draws a bar with a top border; each tab is a tappable column with its icon and label,
  /// coloured brown and bold when selected and muted otherwise. The Alerts tab (index 2) shows the gold
  /// dot when showAlertDot is true.
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 6),
          child: Row(
            children: List.generate(_items.length, (i) {
              final selected = i == currentIndex;
              final color = selected ? AppColors.brown : AppColors.textMuted;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(_items[i].$1, size: 28, color: color),
                            if (i == 2 && showAlertDot)
                              Positioned(
                                right: -2,
                                top: -1,
                                child: Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _items[i].$2,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: color,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
