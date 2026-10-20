//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

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
