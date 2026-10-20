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
