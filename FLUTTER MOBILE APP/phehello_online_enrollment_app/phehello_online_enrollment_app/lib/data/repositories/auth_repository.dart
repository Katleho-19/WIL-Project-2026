//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: auth_repository.dart wraps Supabase Authentication and the profiles table:
// registering, signing in and out, resetting/changing passwords, and loading/updating the
// parent's profile.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/db_names.dart';
import '../../models/parent_profile.dart';
import '../services/supabase_service.dart';

/// FR1 - register, sign in, sign out and profile management (Supabase Auth).
///
/// AuthRepository (class) - all login/account operations used by AuthViewModel and the profile screens.
class AuthRepository {
  /// _c (getter) - shortcut to the shared Supabase client.
  SupabaseClient get _c => SupabaseService.client;

  /// currentUser (getter) - the signed-in Supabase user, or null if nobody is signed in.
  User? get currentUser => _c.auth.currentUser;

  /// currentSession (getter) - the current login session, or null if there is none.
  Session? get currentSession => _c.auth.currentSession;

  /// authChanges (getter) - a stream that emits an event whenever the user signs in, signs out
  /// or the session refreshes; AuthViewModel listens to it.
  Stream<AuthState> get authChanges => _c.auth.onAuthStateChange;

  /// signIn() - logs in with email and password (the email is trimmed).
  /// Throws an AuthException if the details are wrong.
  Future<AuthResponse> signIn(String email, String password) {
    return _c.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// createMissingProfile() - safety net: inserts a profiles row (role Parent) for a signed-in
  /// user who somehow has none, using their id, email and full name from the sign-up metadata.
  /// If the row already exists it is left untouched (ignoreDuplicates). Returns the profile.
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

  /// signUp() - creates a new account with the full name, email and password. The name and the
  /// role "Parent" are sent as metadata, and a database trigger uses them to create the profile row.
  /// Creates the account. The database trigger `handle_new_user` creates the
  /// matching `profiles` row (role = Parent) from the metadata below.
  Future<AuthResponse> signUp(String fullName, String email, String password) {
    return _c.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim(), 'role': 'Parent'},
    );
  }

  /// signOut() - ends the current session.
  Future<void> signOut() => _c.auth.signOut();

  /// sendPasswordReset() - asks Supabase to email a password-reset link to the given address.
  Future<void> sendPasswordReset(String email) =>
      _c.auth.resetPasswordForEmail(email.trim());

  /// updatePassword() - changes the signed-in user's password to the new one.
  Future<void> updatePassword(String newPassword) async {
    await _c.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// verifyPassword() - confirms the user knows their current password by signing in again with
  /// it; throws if it is wrong. Used before allowing a password change.
  /// Re-checks the current password before allowing a change.
  Future<void> verifyPassword(String email, String password) async {
    await _c.auth.signInWithPassword(email: email, password: password);
  }

  /// fetchProfile() - loads the profile row for a user id and returns a ParentProfile,
  /// or null if no row exists.
  Future<ParentProfile?> fetchProfile(String userId) async {
    final row = await _c
        .from(Db.profiles)
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return ParentProfile.fromMap(Map<String, dynamic>.from(row));
  }

  /// updateProfile() - saves the parent's edited details (name, phone, relationship, occupation)
  /// to their profile row and stamps updated_at with the current UTC time.
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
