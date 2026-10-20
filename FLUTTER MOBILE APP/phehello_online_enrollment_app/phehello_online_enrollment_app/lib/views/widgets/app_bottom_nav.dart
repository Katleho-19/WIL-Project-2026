import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Bottom navigation: Home, Applications, Alerts, Profile.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showAlertDot = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showAlertDot;

  static const _items = <(IconData, String)>[
    (Icons.home_outlined, 'Home'),
    (Icons.list_alt_outlined, 'Applications'),
    (Icons.notifications_none_rounded, 'Alerts'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

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
                                      color: AppColors.gold, shape: BoxShape.circle),
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
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
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
