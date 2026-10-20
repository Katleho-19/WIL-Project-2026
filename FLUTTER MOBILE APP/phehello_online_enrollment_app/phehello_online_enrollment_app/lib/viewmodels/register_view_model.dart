import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for the Create Parent/Guardian Account screen (FR1).
class RegisterViewModel extends BaseViewModel {
  RegisterViewModel(this._auth);

  final AuthViewModel _auth;

  bool busy = false;
  String? error;

  /// The View decides what to show next from [SignUpResult.outcome];
  /// a failure message is also kept in [error].
  Future<SignUpResult> register(
      String fullName, String email, String password) async {
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
