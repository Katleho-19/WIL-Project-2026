//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import '../utils/formatters.dart';

class StatusHistoryEntry {
  const StatusHistoryEntry({
    required this.newStatus,
    this.oldStatus,
    this.reason,
    this.changedAt,
  });

  final String? oldStatus;
  final String newStatus;
  final String? reason;
  final DateTime? changedAt;

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> m) =>
      StatusHistoryEntry(
        oldStatus: m['old_status'] as String?,
        newStatus: (m['new_status'] as String?) ?? '',
        reason: m['change_reason'] as String?,
        changedAt: Formatters.parseDateTime(m['changed_at']),
      );
}
