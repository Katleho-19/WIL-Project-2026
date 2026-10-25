//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: step_progress.dart defines StepProgress, the six-step progress indicator shown at the
// top of the enrolment wizard.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';

/// StepProgress (class) - shows the six wizard steps as numbered circles joined by lines, with the step names
/// underneath. 'current' is the zero-based index of the current step.
/// Six-step progress indicator (Learner > Academic > Medical > Guardian >
/// Payment > Proof) with ticks on completed steps.
class StepProgress extends StatelessWidget {
  /// Constructor - current is required.
  const StepProgress({super.key, required this.current});

  /// Zero-based index of the current step.
  final int current;

  /// build() - for each step draws a circle: completed steps are brown with a tick, the current step is brown with its
  /// number, future steps are white; the connecting lines are brown up to the current step; the step name is
  /// underneath (bold for the current step).
  @override
  Widget build(BuildContext context) {
    const names = EnrolmentFlowViewModel.stepNames;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 6),
      child: Row(
        children: List.generate(names.length, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 32,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i == 0
                              ? Colors.transparent
                              : (i <= current
                                    ? AppColors.brown
                                    : AppColors.border),
                        ),
                      ),
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (done || active)
                              ? AppColors.brown
                              : Colors.white,
                          border: Border.all(
                            color: (done || active)
                                ? AppColors.brown
                                : AppColors.border,
                            width: 1.6,
                          ),
                        ),
                        child: done
                            ? const Icon(
                                Icons.check_rounded,
                                size: 17,
                                color: Colors.white,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: active
                                      ? Colors.white
                                      : AppColors.textMuted,
                                ),
                              ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i == names.length - 1
                              ? Colors.transparent
                              : (i < current
                                    ? AppColors.brown
                                    : AppColors.border),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  names[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                    color: active ? AppColors.brownDark : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
