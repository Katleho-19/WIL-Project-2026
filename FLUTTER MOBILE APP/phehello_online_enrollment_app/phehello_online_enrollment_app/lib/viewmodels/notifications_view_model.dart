//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import '../data/repositories/notification_repository.dart';
import '../models/app_notification.dart';
import '../utils/app_error.dart';
import 'base_view_model.dart';

class NotificationsViewModel extends BaseViewModel {
  NotificationsViewModel(this._repo);

  final NotificationRepository _repo;

  String? _userId;
  List<AppNotification> items = [];
  bool loading = false;
  String? error;

  int get unreadCount => items.where((n) => !n.isRead).length;
  List<AppNotification> get messages => items.where((n) => n.isMessage).toList();
  List<AppNotification> get updates => items.where((n) => !n.isMessage).toList();

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
