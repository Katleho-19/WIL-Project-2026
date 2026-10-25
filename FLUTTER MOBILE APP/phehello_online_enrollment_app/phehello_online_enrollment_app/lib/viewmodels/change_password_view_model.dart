//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: change_password_view_model.dart holds the state and action of the Change
// Password screen: whether saving is in progress, any error, and the save action.

import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for Profile > Change Password.
///
/// ChangePasswordViewModel (class) - sits between the change-password screen and AuthViewModel.
class ChangePasswordViewModel extends BaseViewModel {
  /// Constructor - receives the shared AuthViewModel that performs the real password change.
  ChangePasswordViewModel(this._auth);

  final AuthViewModel _auth;

  /// saving - true while the password change is running.
  bool saving = false;

  /// error - the message to display if the change failed; null when there is no error.
  String? error;

  /// save() - changes the password from 'current' to 'next'. It marks the view model as saving,
  /// clears any old error, calls AuthViewModel.changePassword (null on success, otherwise an
  /// error message) and returns true only if no error was returned.
  /// Returns true when the password was changed.
  Future<bool> save(String current, String next) async {
    saving = true;
    error = null;
    notifyListeners();
    error = await _auth.changePassword(current, next);
    saving = false;
    notifyListeners();
    return error == null;
  }
}
