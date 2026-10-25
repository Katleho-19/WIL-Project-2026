//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: step_scaffold.dart defines StepScaffold, the shared layout used by every step of the
// enrolment wizard (large title, helper text and a scrollable list of form fields).

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// StepScaffold (class) - the common page layout for a wizard step. 'title' is the big heading, 'subtitle' the helper text under it
/// (with a default sentence) and 'children' the form widgets shown below.
/// Shared layout for a wizard step: big title, helper text, scrollable body.
class StepScaffold extends StatelessWidget {
  /// Constructor - title and children are required; subtitle has a default value.
  const StepScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle =
        'Complete this section of the learner enrolment application.',
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// build() - a scrollable column (the keyboard closes when the user drags) with the title, the subtitle, a gap and then all the child widgets.
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
