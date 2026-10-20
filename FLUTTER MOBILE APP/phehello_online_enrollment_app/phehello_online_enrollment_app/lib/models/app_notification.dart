//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import '../utils/formatters.dart';
import 'enums.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.applicationId,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? applicationId;
  final DateTime? createdAt;

  /// "Messages" tab = staff messages, reminders and system messages.
  /// "Notifications" tab = application status updates.
  bool get isMessage =>
      type != NotificationType.statusUpdate &&
      type != NotificationType.reminder;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    isRead: isRead ?? this.isRead,
    applicationId: applicationId,
    createdAt: createdAt,
  );

  factory AppNotification.fromMap(Map<String, dynamic> m) {
    final type = (m['notification_type'] as String?) ?? NotificationType.system;
    return AppNotification(
      id: (m['notification_id'] ?? m['id'] ?? '') as String,
      type: type,
      title: (m['title'] as String?) ?? _defaultTitle(type),
      message: (m['message'] as String?) ?? '',
      isRead: (m['is_read'] as bool?) ?? false,
      applicationId: m['application_id'] as String?,
      createdAt: Formatters.parseDateTime(m['created_at']),
    );
  }

  static String _defaultTitle(String type) {
    switch (type) {
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.statusUpdate:
        return 'Application Update';
      case NotificationType.message:
        return 'Message from School';
      default:
        return 'System Message';
    }
  }
}
