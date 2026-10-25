//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: draft_view_model.dart keeps the parent's saved (unsubmitted) enrolment draft in
// memory so the home screen can show a "Continue Application" card, and lets the parent discard it.

import '../data/services/draft_storage.dart';
import '../models/enrolment_draft.dart';
import 'base_view_model.dart';

/// Holds the parent's saved (unsubmitted) application so the dashboard can
/// show it with a "Continue Application" button.
///
/// DraftViewModel (class) - loads/clears the draft through DraftStorage for the signed-in user.
class DraftViewModel extends BaseViewModel {
  /// Constructor - receives the DraftStorage used to read and delete the saved draft.
  DraftViewModel(this._storage);

  final DraftStorage _storage;

  /// _userId - the id of the signed-in user whose draft is loaded (null when signed out).
  String? _userId;

  /// draft - the saved draft, or null if there is none.
  EnrolmentDraft? draft;

  /// hasDraft (getter) - true when a saved draft exists.
  bool get hasDraft => draft != null;

  /// onUserChanged() - called by the ProxyProvider (see app.dart) whenever the signed-in user
  /// changes. If the user is the same it does nothing; otherwise it stores the new id, clears the
  /// old draft and schedules refresh() to load the new user's draft.
  /// Called by the ProxyProvider whenever the logged-in user changes.
  void onUserChanged(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    draft = null;
    // Defer: this runs while the widget tree is building.
    Future.microtask(refresh);
  }

  /// refresh() - reloads the draft from device storage (or sets it to null if nobody is signed in)
  /// and notifies listeners.
  Future<void> refresh() async {
    final id = _userId;
    draft = id == null ? null : await _storage.load(id);
    notifyListeners();
  }

  /// discard() - deletes the saved draft from the device and clears it from memory.
  /// Does nothing if nobody is signed in.
  Future<void> discard() async {
    final id = _userId;
    if (id == null) return;
    await _storage.clear(id);
    draft = null;
    notifyListeners();
  }
}
