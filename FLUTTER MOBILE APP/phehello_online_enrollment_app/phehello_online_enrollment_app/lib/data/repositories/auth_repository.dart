import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/db_names.dart';
import '../../models/parent_profile.dart';
import '../services/supabase_service.dart';

/// FR1 - register, sign in, sign out and profile management (Supabase Auth).
class AuthRepository {
  SupabaseClient get _c => SupabaseService.client;

  User? get currentUser => _c.auth.currentUser;
  Session? get currentSession => _c.auth.currentSession;
  Stream<AuthState> get authChanges => _c.auth.onAuthStateChange;

  Future<AuthResponse> signIn(String email, String password) {
    return _c.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// If a signed-in user somehow has no profile row, create it (Parent only).
  Future<ParentProfile?> createMissingProfile(User user) async {
    await _c
        .from(Db.profiles)
        .upsert(
          {
            'id': user.id,
            'email': user.email,
            'full_name': ((user.userMetadata?['full_name'] as String?) ?? '')
                .trim(),
            'role': 'Parent',
          },
          onConflict: 'id',
          ignoreDuplicates: true,
        );
    return fetchProfile(user.id);
  }

  /// Creates the account. The database trigger `handle_new_user` creates the
  /// matching `profiles` row (role = Parent) from the metadata below.
  Future<AuthResponse> signUp(String fullName, String email, String password) {
    return _c.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim(), 'role': 'Parent'},
    );
  }

  Future<void> signOut() => _c.auth.signOut();

  Future<void> sendPasswordReset(String email) =>
      _c.auth.resetPasswordForEmail(email.trim());

  Future<void> updatePassword(String newPassword) async {
    await _c.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Re-checks the current password before allowing a change.
  Future<void> verifyPassword(String email, String password) async {
    await _c.auth.signInWithPassword(email: email, password: password);
  }

  Future<ParentProfile?> fetchProfile(String userId) async {
    final row = await _c
        .from(Db.profiles)
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return ParentProfile.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> updateProfile(
    String userId, {
    required String fullName,
    String? phone,
    String? relationship,
    String? occupation,
  }) async {
    await _c
        .from(Db.profiles)
        .update({
          'full_name': fullName.trim(),
          'phone_number': phone?.trim(),
          'relationship_to_learner': relationship,
          'occupation': occupation?.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);
  }
}
