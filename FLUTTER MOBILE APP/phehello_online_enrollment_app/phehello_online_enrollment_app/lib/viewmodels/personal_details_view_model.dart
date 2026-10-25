//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: personal_details_view_model.dart provides the current profile values used to
// pre-fill the Personal Details form, and saves the parent's edits.

import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for Profile > Personal Details.
///
/// PersonalDetailsViewModel (class) - sits between the personal-details screen and AuthViewModel.
class PersonalDetailsViewModel extends BaseViewModel {
  /// Constructor - receives the shared AuthViewModel that owns the profile.
  PersonalDetailsViewModel(this._auth);

  final AuthViewModel _auth;

  /// saving - true while the profile update is running.
  bool saving = false;

  // Current values used to pre-fill the form.
  /// fullName (getter) - the parent's current full name.
  String get fullName => _auth.fullName;

  /// email (getter) - the parent's email address (shown but not editable).
  String get email => _auth.email;

  /// phone (getter) - the saved phone number, or '' if none.
  String get phone => _auth.profile?.phoneNumber ?? '';

  /// occupation (getter) - the saved occupation, or '' if none.
  String get occupation => _auth.profile?.occupation ?? '';

  /// relationship (getter) - the saved relationship to the learner, or '' if none.
  String get relationship => _auth.profile?.relationshipToLearner ?? '';

  /// save() - saves the edited details through AuthViewModel.updateProfile (an empty relationship
  /// is sent as null). It marks the view model as saving, then not saving, and returns the result.
  /// Returns null on success, otherwise a readable error message.
  Future<String?> save({
    required String fullName,
    required String phone,
    required String relationship,
    required String occupation,
  }) async {
    saving = true;
    notifyListeners();
    final err = await _auth.updateProfile(
      fullName: fullName,
      phone: phone,
      relationship: relationship.isEmpty ? null : relationship,
      occupation: occupation,
    );
    saving = false;
    notifyListeners();
    return err;
  }
}
