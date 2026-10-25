//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: status_history_entry.dart defines StatusHistoryEntry, one row in an application's
// status history (what it changed from, what it changed to, why and when).

import '../utils/formatters.dart';

/// StatusHistoryEntry (class) - an immutable record of a single status change.
class StatusHistoryEntry {
  /// Constructor - newStatus is required; oldStatus, reason and changedAt are optional.
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

  /// StatusHistoryEntry.fromMap() - factory that builds an entry from a database row
  /// (old_status, new_status, change_reason, changed_at).
  factory StatusHistoryEntry.fromMap(Map<String, dynamic> m) =>
      StatusHistoryEntry(
        oldStatus: m['old_status'] as String?,
        newStatus: (m['new_status'] as String?) ?? '',
        reason: m['change_reason'] as String?,
        changedAt: Formatters.parseDateTime(m['changed_at']),
      );
}
