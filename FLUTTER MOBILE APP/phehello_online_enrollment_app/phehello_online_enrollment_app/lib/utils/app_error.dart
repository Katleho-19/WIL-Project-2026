import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns any thrown error into a message a parent can understand (NFR4).
class AppError {
  AppError._();

  static String message(Object error) {
    if (error is AuthException) {
      final m = error.message.toLowerCase();
      if (m.contains('invalid login')) {
        return 'The email or password is incorrect. Please try again.';
      }
      if (m.contains('already registered') || m.contains('already been registered')) {
        return 'An account with this email already exists. Please log in instead.';
      }
      if (m.contains('email not confirmed')) {
        return 'Please confirm your email address first. Check your inbox for the confirmation link.';
      }
      if (m.contains('password') && m.contains('characters')) {
        return 'Your password is too short. Please use at least 8 characters.';
      }
      if (m.contains('rate limit') || m.contains('too many')) {
        return 'Too many attempts. Please wait a few minutes and try again.';
      }
      if (_isNetwork(error.toString())) return _networkMessage;
      return error.message;
    }
    if (error is StorageException) {
      if (_isNetwork(error.toString())) return _networkMessage;
      return 'The file could not be uploaded (${error.message}). Please try again.';
    }
    if (error is PostgrestException) {
      if (error.code == '42501') {
        return 'You do not have permission to do this. Please log in again.';
      }
      if (error.message.isNotEmpty && error.message.length < 160) {
        return error.message;
      }
      return 'Something went wrong while saving your information. Please try again.';
    }
    final text = error.toString();
    if (_isNetwork(text)) return _networkMessage;
    if (error is AppException) return error.message;
    return 'Something went wrong. Please try again.';
  }

  static const String _networkMessage =
      'We could not reach the server. Please check your internet connection and try again.';

  static bool _isNetwork(String t) {
    final s = t.toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('clientexception') ||
        s.contains('timeout') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection closed');
  }
}

/// A deliberate, user-readable error raised by the app itself.
class AppException implements Exception {
  AppException(this.message);
  final String message;
  @override
  String toString() => message;
}
