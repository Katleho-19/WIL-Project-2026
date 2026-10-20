import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repositories/auth_repository.dart';
import '../models/parent_profile.dart';
import '../utils/app_error.dart';
import 'base_view_model.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

enum SignUpOutcome { signedIn, needsEmailConfirmation, failed }

class SignUpResult {
  const SignUpResult(this.outcome, [this.message]);
  final SignUpOutcome outcome;
  final String? message;
}

class AuthViewModel extends BaseViewModel {
  AuthViewModel(this._repo) {
    _init();
  }

  final AuthRepository _repo;
  StreamSubscription<AuthState>? _sub;

  AuthStatus status = AuthStatus.initializing;
  User? user;
  ParentProfile? profile;

  String? get userId => user?.id;
  String get email => profile?.email ?? user?.email ?? '';

  String get fullName {
    final p = profile?.fullName ?? '';
    if (p.trim().isNotEmpty) return p;
    final meta = user?.userMetadata?['full_name'];
    return meta is String ? meta : '';
  }

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

  Future<void> refreshProfile() => _loadProfile();

  /// Returns null on success, otherwise a readable error message.
  Future<String?> signIn(String email, String password) async {
    try {
      await _repo.signIn(email, password);
      return null;
    } catch (e) {
      return AppError.message(e);
    }
  }

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

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _repo.sendPasswordReset(email);
      return null;
    } catch (e) {
      return AppError.message(e);
    }
  }

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

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
