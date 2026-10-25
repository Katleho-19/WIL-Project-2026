//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: notification_repository.dart loads the parent's notifications from Supabase and
// marks them as read.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/db_names.dart';
import '../../models/app_notification.dart';
import '../services/supabase_service.dart';

/// FR10 / FR11 - messages and reminders sent by school staff.
///
/// NotificationRepository (class) - database access for the notifications table.
class NotificationRepository {
  /// _c (getter) - shortcut to the shared Supabase client.
  SupabaseClient get _c => SupabaseService.client;

  /// fetchMine() - loads every notification addressed to this user (recipient_id = userId)
  /// and converts each row into an AppNotification.
  Future<List<AppNotification>> fetchMine(String userId) async {
    final rows = await _c
        .from(Db.notifications)
        .select()
        .eq('recipient_id', userId);

    return (rows as List)
        .map(
          (e) => AppNotification.fromMap(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// markRead() - sets is_read = true for one notification.
  Future<void> markRead(String notificationId) async {
    await _c
        .from(Db.notifications)
        .update({'is_read': true})
        .eq('notification_id', notificationId);
  }

  /// markAllRead() - sets is_read = true for every unread notification of this user.
  Future<void> markAllRead(String userId) async {
    await _c
        .from(Db.notifications)
        .update({'is_read': true})
        .eq('recipient_id', userId)
        .eq('is_read', false);
  }
}
