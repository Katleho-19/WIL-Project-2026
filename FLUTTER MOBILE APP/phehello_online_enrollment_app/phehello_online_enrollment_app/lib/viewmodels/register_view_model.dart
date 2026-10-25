//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: register_view_model.dart holds the state and action of the Create Account screen
// (FR1): whether registration is running, any error, and the register action.

import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for the Create Parent/Guardian Account screen (FR1).
///
/// RegisterViewModel (class) - sits between the register screen and AuthViewModel.
class RegisterViewModel extends BaseViewModel {
  /// Constructor - receives the shared AuthViewModel that performs the real sign-up.
  RegisterViewModel(this._auth);

  final AuthViewModel _auth;

  /// busy - true while the registration request is running.
  bool busy = false;

  /// error - the failure message to display; null when there is no error.
  String? error;

  /// register() - creates the account. It marks the view model busy, clears any old error and
  /// calls AuthViewModel.signUp. If the outcome is "failed" the message is stored in 'error'.
  /// It then stops being busy and returns the SignUpResult so the screen can decide what to show.
  /// The View decides what to show next from [SignUpResult.outcome];
  /// a failure message is also kept in [error].
  Future<SignUpResult> register(
    String fullName,
    String email,
    String password,
  ) async {
    busy = true;
    error = null;
    notifyListeners();
    final result = await _auth.signUp(fullName, email, password);
    if (result.outcome == SignUpOutcome.failed) error = result.message;
    busy = false;
    notifyListeners();
    return result;
  }
}
