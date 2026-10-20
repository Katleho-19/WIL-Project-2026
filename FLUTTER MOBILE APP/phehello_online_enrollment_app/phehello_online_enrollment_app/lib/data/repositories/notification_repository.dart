//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034


import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/db_names.dart';
import '../../models/app_notification.dart';
import '../services/supabase_service.dart';

/// FR10 / FR11 - messages and reminders sent by school staff.
class NotificationRepository {
  SupabaseClient get _c => SupabaseService.client;

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

  Future<void> markRead(String notificationId) async {
    await _c
        .from(Db.notifications)
        .update({'is_read': true})
        .eq('notification_id', notificationId);
  }

  Future<void> markAllRead(String userId) async {
    await _c
        .from(Db.notifications)
        .update({'is_read': true})
        .eq('recipient_id', userId)
        .eq('is_read', false);
  }
}
