//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: login_view_model.dart holds the state and actions of the Login screen: whether a
// sign-in is in progress, the error message to show, and the sign-in / forgot-password actions.

import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for the Welcome / Login screen.
///
/// LoginViewModel (class) - sits between the login screen and AuthViewModel.
class LoginViewModel extends BaseViewModel {
  /// Constructor - receives the shared AuthViewModel that performs the real sign-in.
  LoginViewModel(this._auth);

  final AuthViewModel _auth;

  /// busy - true while the sign-in request is running (the screen shows a spinner).
  bool busy = false;

  /// error - the message to display if sign-in failed; null when there is no error.
  String? error;

  /// signIn() - signs the parent in. It marks the view model busy, clears any old error, calls
  /// AuthViewModel.signIn (which returns null on success or an error message), stores that result
  /// in 'error', and stops being busy.
  /// On success the auth gate swaps the screen for the main app, so there is
  /// nothing for the View to do except show [error] when it is set.
  Future<void> signIn(String email, String password) async {
    busy = true;
    error = null;
    notifyListeners();
    error = await _auth.signIn(email, password);
    busy = false;
    notifyListeners();
  }

  /// sendPasswordReset() - asks AuthViewModel to email a password-reset link.
  /// Returns null on success, otherwise a readable error message.
  Future<String?> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);
}
