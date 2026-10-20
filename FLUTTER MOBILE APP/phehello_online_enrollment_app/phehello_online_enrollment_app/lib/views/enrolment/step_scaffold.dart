import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Shared layout for a wizard step: big title, helper text, scrollable body.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle = 'Complete this section of the learner enrolment application.',
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.35)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
