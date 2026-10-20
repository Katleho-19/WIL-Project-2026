//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import '../data/repositories/application_repository.dart';
import '../models/enrolment_application.dart';
import '../models/enums.dart';
import '../utils/app_error.dart';
import 'base_view_model.dart';

enum ApplicationFilter { all, pending, approved, rejected }

/// Holds the parent's applications, always loaded from Supabase (FR5).
class ApplicationsViewModel extends BaseViewModel {
  ApplicationsViewModel(this._repo);

  final ApplicationRepository _repo;

  String? _userId;
  List<EnrolmentApplication> items = [];
  bool loading = false;
  String? error;
  ApplicationFilter filter = ApplicationFilter.all;

  /// Called by the ProxyProvider whenever the logged-in user changes.
  void onUserChanged(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    items = [];
    error = null;
    // Defer: this runs while the widget tree is building.
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

  Future<EnrolmentApplication?> refreshOne(String applicationId) async {
    try {
      final fresh = await _repo.fetchOne(applicationId);
      if (fresh != null) {
        final i = items.indexWhere((a) => a.id == applicationId);
        if (i >= 0) {
          items[i] = fresh;
        } else {
          items.insert(0, fresh);
        }
        notifyListeners();
      }
      return fresh;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteApplication(EnrolmentApplication app) async {
    final uid = _userId;
    if (uid == null) throw Exception('Please log in again.');
    await _repo.deleteApplication(userId: uid, app: app);
    items.removeWhere((a) => a.id == app.id);
    notifyListeners();
  }

  void setFilter(ApplicationFilter f) {
    filter = f;
    notifyListeners();
  }

  List<EnrolmentApplication> get filtered {
    switch (filter) {
      case ApplicationFilter.all:
        return items;
      case ApplicationFilter.pending:
        return items.where((a) => a.status.isPendingGroup).toList();
      case ApplicationFilter.approved:
        return items
            .where((a) => a.status == ApplicationStatus.approved)
            .toList();
      case ApplicationFilter.rejected:
        return items
            .where((a) => a.status == ApplicationStatus.rejected)
            .toList();
    }
  }

  EnrolmentApplication? byId(String id) {
    for (final a in items) {
      if (a.id == id) return a;
    }
    return null;
  }
}
