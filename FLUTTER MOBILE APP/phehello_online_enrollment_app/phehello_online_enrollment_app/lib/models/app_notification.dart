//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: app_notification.dart defines AppNotification, one message/notification sent to
// the parent (staff message, reminder, status update or system message).

import '../utils/formatters.dart';
import 'enums.dart';

/// AppNotification (class) - an immutable record of one notification.
class AppNotification {
  /// Constructor - id, type, title, message and isRead are required; applicationId and createdAt are optional.
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

  /// isMessage (getter) - true when this belongs on the "Messages" tab, i.e. its type is
  /// neither a status update nor a reminder.
  /// "Messages" tab = staff messages, reminders and system messages.
  /// "Notifications" tab = application status updates.
  bool get isMessage =>
      type != NotificationType.statusUpdate &&
      type != NotificationType.reminder;

  /// copyWith() - returns a copy of this notification with only isRead changed.
  /// Used to mark a notification as read without mutating the original.
  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    isRead: isRead ?? this.isRead,
    applicationId: applicationId,
    createdAt: createdAt,
  );

  /// AppNotification.fromMap() - factory that builds a notification from a database row.
  /// If the row has no title, a default title for its type is used; a missing is_read becomes false.
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

  /// _defaultTitle() - private helper returning the fallback title for a notification type
  /// ("Reminder", "Application Update", "Message from School" or "System Message").
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
