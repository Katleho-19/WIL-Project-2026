//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: applications_view_model.dart holds the parent's list of applications (always
// loaded from Supabase, FR5), the selected filter tab, and actions to load, refresh, delete and
// filter applications.

import '../data/repositories/application_repository.dart';
import '../models/enrolment_application.dart';
import '../models/enums.dart';
import '../utils/app_error.dart';
import 'base_view_model.dart';

/// ApplicationFilter (enum) - the tabs on the My Applications screen.
enum ApplicationFilter { all, pending, approved, rejected }

/// Holds the parent's applications, always loaded from Supabase (FR5).
///
/// ApplicationsViewModel (class) - state and actions for the list of applications.
class ApplicationsViewModel extends BaseViewModel {
  /// Constructor - receives the ApplicationRepository used to talk to Supabase.
  ApplicationsViewModel(this._repo);

  final ApplicationRepository _repo;

  /// _userId - the signed-in user's id (null when signed out).
  String? _userId;

  /// items - all of this parent's applications.
  List<EnrolmentApplication> items = [];

  /// loading - true while applications are being fetched.
  bool loading = false;

  /// error - a readable error message if loading failed; null otherwise.
  String? error;

  /// filter - the currently selected tab.
  ApplicationFilter filter = ApplicationFilter.all;

  /// onUserChanged() - called by the ProxyProvider whenever the signed-in user changes. If the
  /// user is unchanged nothing happens; otherwise it stores the new id, clears the old list and
  /// error, then (after the current build finishes) loads the new user's applications, or just
  /// notifies listeners if the user signed out.
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

  /// load() - fetches all of this user's applications. Shows the loading state, stores the items
  /// on success or a readable message in 'error' on failure, and always stops loading.
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

  /// refreshOne() - re-fetches a single application and replaces it in the list (or adds it at
  /// the top if it was not there). Returns the fresh application, or null if it was not found or
  /// the request failed.
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

  /// deleteApplication() - deletes one of the parent's own applications through the repository
  /// (database record and stored files), then removes it from the local list. Throws an error
  /// if nobody is signed in or the delete fails, so the caller can show a message.
  Future<void> deleteApplication(EnrolmentApplication app) async {
    final uid = _userId;
    if (uid == null) throw Exception('Please log in again.');
    await _repo.deleteApplication(userId: uid, app: app);
    items.removeWhere((a) => a.id == app.id);
    notifyListeners();
  }

  /// setFilter() - changes the selected tab and notifies listeners.
  void setFilter(ApplicationFilter f) {
    filter = f;
    notifyListeners();
  }

  /// filtered (getter) - the applications matching the selected tab: all; pending (pending review
  /// plus corrections requested); approved only; or rejected only.
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

  /// byId() - finds an application in the loaded list by its id; returns null if not found.
  EnrolmentApplication? byId(String id) {
    for (final a in items) {
      if (a.id == id) return a;
    }
    return null;
  }
}
