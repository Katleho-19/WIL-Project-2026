//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

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
