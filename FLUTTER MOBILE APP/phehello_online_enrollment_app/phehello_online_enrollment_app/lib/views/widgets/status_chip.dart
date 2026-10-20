import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  factory StatusChip.application(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pendingAdminReview:
        return StatusChip(label: s.chipLabel, bg: AppColors.pendingBg, fg: AppColors.pendingFg);
      case ApplicationStatus.correctionsRequested:
        return StatusChip(label: s.chipLabel, bg: AppColors.correctionBg, fg: AppColors.correctionFg);
      case ApplicationStatus.approved:
        return StatusChip(label: s.chipLabel, bg: AppColors.approvedBg, fg: AppColors.approvedFg);
      case ApplicationStatus.rejected:
        return StatusChip(label: s.chipLabel, bg: AppColors.rejectedBg, fg: AppColors.rejectedFg);
    }
  }

  factory StatusChip.payment(PaymentVerificationStatus s) {
    switch (s) {
      case PaymentVerificationStatus.pending:
        return StatusChip(label: s.chipLabel, bg: AppColors.pendingBg, fg: AppColors.pendingFg);
      case PaymentVerificationStatus.verified:
        return StatusChip(label: s.chipLabel, bg: AppColors.approvedBg, fg: AppColors.approvedFg);
      case PaymentVerificationStatus.rejected:
        return StatusChip(label: s.chipLabel, bg: AppColors.rejectedBg, fg: AppColors.rejectedFg);
    }
  }

  factory StatusChip.received() => const StatusChip(
      label: 'Received', bg: AppColors.approvedBg, fg: AppColors.approvedFg);

  factory StatusChip.missing() => const StatusChip(
      label: 'Missing', bg: AppColors.rejectedBg, fg: AppColors.rejectedFg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
