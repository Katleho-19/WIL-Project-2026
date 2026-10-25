//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: status_chip.dart defines StatusChip, the small coloured pill that shows the
// status of an application, a payment or a document (e.g. Pending, Approved, Rejected).

import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../theme/app_colors.dart';

/// StatusChip (class) - a rounded pill with a text label, a background colour (bg) and a text colour (fg).
class StatusChip extends StatelessWidget {
  /// Constructor - label, bg and fg are all required.
  const StatusChip({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;

  /// StatusChip.application() - builds the chip for an ApplicationStatus: yellow for pending, orange for
  /// corrections requested, green for approved and red for rejected.
  factory StatusChip.application(ApplicationStatus s) {
    switch (s) {
      case ApplicationStatus.pendingAdminReview:
        return StatusChip(
          label: s.chipLabel,
          bg: AppColors.pendingBg,
          fg: AppColors.pendingFg,
        );
      case ApplicationStatus.correctionsRequested:
        return StatusChip(
          label: s.chipLabel,
          bg: AppColors.correctionBg,
          fg: AppColors.correctionFg,
        );
      case ApplicationStatus.approved:
        return StatusChip(
          label: s.chipLabel,
          bg: AppColors.approvedBg,
          fg: AppColors.approvedFg,
        );
      case ApplicationStatus.rejected:
        return StatusChip(
          label: s.chipLabel,
          bg: AppColors.rejectedBg,
          fg: AppColors.rejectedFg,
        );
    }
  }

  /// StatusChip.payment() - builds the chip for a PaymentVerificationStatus: yellow for pending,
  /// green for verified and red for rejected.
  factory StatusChip.payment(PaymentVerificationStatus s) {
    switch (s) {
      case PaymentVerificationStatus.pending:
        return StatusChip(
          label: s.chipLabel,
          bg: AppColors.pendingBg,
          fg: AppColors.pendingFg,
        );
      case PaymentVerificationStatus.verified:
        return StatusChip(
          label: s.chipLabel,
          bg: AppColors.approvedBg,
          fg: AppColors.approvedFg,
        );
      case PaymentVerificationStatus.rejected:
        return StatusChip(
          label: s.chipLabel,
          bg: AppColors.rejectedBg,
          fg: AppColors.rejectedFg,
        );
    }
  }

  /// StatusChip.received() - a green "Received" chip (for a document that has been uploaded).
  factory StatusChip.received() => const StatusChip(
    label: 'Received',
    bg: AppColors.approvedBg,
    fg: AppColors.approvedFg,
  );

  /// StatusChip.missing() - a red "Missing" chip (for a document that has not been uploaded).
  factory StatusChip.missing() => const StatusChip(
    label: 'Missing',
    bg: AppColors.rejectedBg,
    fg: AppColors.rejectedFg,
  );

  /// build() - draws the pill: padded container with rounded corners in the background colour and bold, small text in the foreground colour.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
