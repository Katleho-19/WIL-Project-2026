import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for Profile > Change Password.
class ChangePasswordViewModel extends BaseViewModel {
  ChangePasswordViewModel(this._auth);

  final AuthViewModel _auth;

  bool saving = false;
  String? error;

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
