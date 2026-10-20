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
