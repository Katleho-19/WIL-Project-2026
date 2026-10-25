//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: notifications_view_model.dart holds the parent's notifications and messages,
// splits them for the two tabs, counts unread items, loads them from Supabase and marks them read.

import '../data/repositories/notification_repository.dart';
import '../models/app_notification.dart';
import '../utils/app_error.dart';
import 'base_view_model.dart';

/// NotificationsViewModel (class) - state and actions for the Notifications screen and the
/// unread badge on the bottom navigation.
class NotificationsViewModel extends BaseViewModel {
  /// Constructor - receives the NotificationRepository used to talk to Supabase.
  NotificationsViewModel(this._repo);

  final NotificationRepository _repo;

  /// _userId - the signed-in user's id (null when signed out).
  String? _userId;

  /// items - all loaded notifications.
  List<AppNotification> items = [];

  /// loading - true while notifications are being fetched.
  bool loading = false;

  /// error - a readable error message if loading failed; null otherwise.
  String? error;

  /// unreadCount (getter) - how many notifications have not been read yet.
  int get unreadCount => items.where((n) => !n.isRead).length;

  /// messages (getter) - the items for the "Messages" tab (staff messages and system messages).
  List<AppNotification> get messages =>
      items.where((n) => n.isMessage).toList();

  /// updates (getter) - the items for the "Notifications" tab (status updates and reminders).
  List<AppNotification> get updates =>
      items.where((n) => !n.isMessage).toList();

  /// onUserChanged() - called by the ProxyProvider whenever the signed-in user changes.
  /// If the user is unchanged it does nothing; otherwise it stores the new id, clears the old
  /// list and error, then (after the current build finishes) loads the new user's notifications,
  /// or just notifies listeners if the user signed out.
  void onUserChanged(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    items = [];
    error = null;
    Future.microtask(() {
      if (_userId != null) {
        load();
      } else {
        notifyListeners();
      }
    });
  }

  /// load() - fetches this user's notifications from the repository. It shows the loading state,
  /// stores the items on success or a readable message in 'error' on failure, and always stops loading.
  Future<void> load() async {
    final id = _userId;
    if (id == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await _repo.fetchMine(id);
    } catch (e) {
      error = AppError.message(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// markRead() - marks one notification as read. It updates the list straight away
  /// (optimistic update) so the UI responds instantly, then tells the database. If the database
  /// call fails the local change is kept and will re-sync on the next load.
  Future<void> markRead(AppNotification n) async {
    if (n.isRead) return;
    final i = items.indexWhere((x) => x.id == n.id);
    if (i >= 0) {
      items[i] = n.copyWith(isRead: true);
      notifyListeners();
    }
    try {
      await _repo.markRead(n.id);
    } catch (_) {
      // Keep the optimistic state; it will re-sync on next load.
    }
  }

  /// markAllRead() - marks every notification as read in the list immediately, then tells the
  /// database; a failure is ignored.
  Future<void> markAllRead() async {
    final id = _userId;
    if (id == null) return;
    items = items.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    try {
      await _repo.markAllRead(id);
    } catch (_) {
      // ignore
    }
  }
}
