import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for Profile > Personal Details.
class PersonalDetailsViewModel extends BaseViewModel {
  PersonalDetailsViewModel(this._auth);

  final AuthViewModel _auth;

  bool saving = false;

  // Current values used to pre-fill the form.
  String get fullName => _auth.fullName;
  String get email => _auth.email;
  String get phone => _auth.profile?.phoneNumber ?? '';
  String get occupation => _auth.profile?.occupation ?? '';
  String get relationship => _auth.profile?.relationshipToLearner ?? '';

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
