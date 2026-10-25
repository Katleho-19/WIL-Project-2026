//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: auth_view_model.dart holds the app-wide authentication state: whether the parent
// is signed in, the Supabase user and the loaded profile. It also provides sign in, sign up,
// sign out, password reset/change and profile update actions. The _AuthGate in app.dart watches
// its status to decide which screen to show.

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository.dart';
import '../models/parent_profile.dart';
import '../utils/app_error.dart';
import 'base_view_model.dart';

/// AuthStatus (enum) - the three states of authentication:
/// initializing (still checking for a saved session), authenticated (signed in) and
/// unauthenticated (signed out).
enum AuthStatus { initializing, authenticated, unauthenticated }

/// SignUpOutcome (enum) - the possible results of creating an account:
/// signedIn (account created and logged in), needsEmailConfirmation (the parent must confirm
/// their email first) or failed.
enum SignUpOutcome { signedIn, needsEmailConfirmation, failed }

/// SignUpResult (class) - what signUp() returns: the outcome plus an optional message
/// (used to explain a failure).
class SignUpResult {
  /// Constructor - the outcome is required (positional); the message is optional.
  const SignUpResult(this.outcome, [this.message]);
  final SignUpOutcome outcome;
  final String? message;
}

/// AuthViewModel (class) - the single source of truth for who is signed in.
class AuthViewModel extends BaseViewModel {
  /// Constructor - stores the AuthRepository and immediately runs _init() to check the session.
  AuthViewModel(this._repo) {
    _init();
  }

  final AuthRepository _repo;

  /// _sub - the subscription to Supabase's sign-in/sign-out events (cancelled in dispose()).
  StreamSubscription<AuthState>? _sub;

  /// status - the current AuthStatus; starts as initializing.
  AuthStatus status = AuthStatus.initializing;

  /// user - the signed-in Supabase user (null when signed out).
  User? user;

  /// profile - the parent's profile row (null until loaded).
  ParentProfile? profile;

  /// userId (getter) - the signed-in user's id, or null.
  String? get userId => user?.id;

  /// email (getter) - the email from the profile, falling back to the auth user's email, else ''.
  String get email => profile?.email ?? user?.email ?? '';

  /// fullName (getter) - the name from the profile; if that is empty it falls back to the
  /// full_name saved in the sign-up metadata, else ''.
  String get fullName {
    final p = profile?.fullName ?? '';
    if (p.trim().isNotEmpty) return p;
    final meta = user?.userMetadata?['full_name'];
    return meta is String ? meta : '';
  }

  /// _init() - runs once at start-up. It checks for an existing session: if there is one the
  /// status becomes authenticated and the profile is loaded, otherwise unauthenticated.
  /// It then listens to Supabase auth events: on sign-out it clears the user and profile; on
  /// sign-in it stores the user, marks authenticated and loads the profile if the user is new
  /// or the profile is missing.
  void _init() {
    user = _repo.currentUser;
    if (user != null) {
      status = AuthStatus.authenticated;
      _loadProfile();
    } else {
      status = AuthStatus.unauthenticated;
    }
    _sub = _repo.authChanges.listen((state) {
      final u = state.session?.user;
      if (u == null) {
        user = null;
        profile = null;
        status = AuthStatus.unauthenticated;
        notifyListeners();
      } else {
        final changedUser = user?.id != u.id;
        user = u;
        status = AuthStatus.authenticated;
        notifyListeners();
        if (changedUser || profile == null) _loadProfile();
      }
    });
  }

  /// _loadProfile() - fetches the profile row; if none exists it creates one. Any error is
  /// ignored because screens can fall back to the auth metadata. Listeners are notified afterwards.
  Future<void> _loadProfile() async {
    final id = user?.id;
    if (id == null) return;
    try {
      profile =
          await _repo.fetchProfile(id) ??
          await _repo.createMissingProfile(user!);
    } catch (_) {
      // Profile is optional for display; screens fall back to auth metadata.
    }
    notifyListeners();
  }

  /// refreshProfile() - public method to reload the profile from the database.
  Future<void> refreshProfile() => _loadProfile();

  /// signIn() - signs in with email and password. Returns null on success, otherwise a
  /// readable error message (via AppError).
  /// Returns null on success, otherwise a readable error message.
  Future<String?> signIn(String email, String password) async {
    try {
      await _repo.signIn(email, password);
      return null;
    } catch (e) {
      return AppError.message(e);
    }
  }

  /// signUp() - creates an account and returns a SignUpResult:
  ///  - a session was returned -> signedIn;
  ///  - no session and no identities -> failed, because Supabase hides existing emails this way
  ///    ("account already exists");
  ///  - no session otherwise -> needsEmailConfirmation (email confirmation is switched on);
  ///  - any thrown error -> failed with a readable message.
  Future<SignUpResult> signUp(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final res = await _repo.signUp(fullName, email, password);
      if (res.session != null) {
        return const SignUpResult(SignUpOutcome.signedIn);
      }
      // No session: Supabase "Confirm email" is enabled, or the address
      // already exists (Supabase returns an obfuscated user in that case).
      final identities = res.user?.identities;
      if (identities != null && identities.isEmpty) {
        return const SignUpResult(
          SignUpOutcome.failed,
          'An account with this email already exists. Please log in instead.',
        );
      }
      return const SignUpResult(SignUpOutcome.needsEmailConfirmation);
    } catch (e) {
      return SignUpResult(SignUpOutcome.failed, AppError.message(e));
    }
  }

  /// signOut() - signs out of Supabase. Even if that network call fails, the local user, profile
  /// and status are cleared so the app returns to the login screen.
  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } catch (_) {
      // Even if the network call fails, clear local state.
    }
    user = null;
    profile = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// sendPasswordReset() - emails a reset link. Returns null on success, otherwise an error message.
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _repo.sendPasswordReset(email);
      return null;
    } catch (e) {
      return AppError.message(e);
    }
  }

  /// changePassword() - first verifies the current password (a wrong one returns
  /// "Your current password is incorrect."), then sets the new password.
  /// Returns null on success, otherwise an error message.
  Future<String?> changePassword(String current, String next) async {
    try {
      await _repo.verifyPassword(email, current);
    } catch (e) {
      final m = AppError.message(e);
      return m.contains('incorrect')
          ? 'Your current password is incorrect.'
          : m;
    }
    try {
      await _repo.updatePassword(next);
      return null;
    } catch (e) {
      return AppError.message(e);
    }
  }

  /// updateProfile() - saves the edited profile details, then reloads the profile so the app shows
  /// the new values. Returns null on success, "Please log in again." if nobody is signed in,
  /// or a readable error message.
  Future<String?> updateProfile({
    required String fullName,
    String? phone,
    String? relationship,
    String? occupation,
  }) async {
    final id = userId;
    if (id == null) return 'Please log in again.';
    try {
      await _repo.updateProfile(
        id,
        fullName: fullName,
        phone: phone,
        relationship: relationship,
        occupation: occupation,
      );
      await _loadProfile();
      return null;
    } catch (e) {
      return AppError.message(e);
    }
  }

  /// dispose() - cancels the auth-event subscription before the view model is disposed.
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
