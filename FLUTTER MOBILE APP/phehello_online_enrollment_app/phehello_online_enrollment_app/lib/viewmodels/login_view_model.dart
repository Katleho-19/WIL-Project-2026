//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for the Welcome / Login screen.
class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._auth);

  final AuthViewModel _auth;

  bool busy = false;
  String? error;

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

  /// Returns null on success, otherwise a readable error message.
  Future<String?> sendPasswordReset(String email) =>
      _auth.sendPasswordReset(email);
}
