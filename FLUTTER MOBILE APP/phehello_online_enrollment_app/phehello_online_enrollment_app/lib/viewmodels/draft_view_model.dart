//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import '../data/services/draft_storage.dart';
import '../models/enrolment_draft.dart';
import 'base_view_model.dart';

/// Holds the parent's saved (unsubmitted) application so the dashboard can
/// show it with a "Continue Application" button.
class DraftViewModel extends BaseViewModel {
  DraftViewModel(this._storage);

  final DraftStorage _storage;

  String? _userId;
  EnrolmentDraft? draft;

  bool get hasDraft => draft != null;

  /// Called by the ProxyProvider whenever the logged-in user changes.
  void onUserChanged(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    draft = null;
    // Defer: this runs while the widget tree is building.
    Future.microtask(refresh);
  }

  Future<void> refresh() async {
    final id = _userId;
    draft = id == null ? null : await _storage.load(id);
    notifyListeners();
  }

  Future<void> discard() async {
    final id = _userId;
    if (id == null) return;
    await _storage.clear(id);
    draft = null;
    notifyListeners();
  }
}
