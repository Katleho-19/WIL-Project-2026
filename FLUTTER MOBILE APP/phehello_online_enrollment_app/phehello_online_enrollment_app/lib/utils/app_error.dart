//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: app_error.dart converts any error thrown by Supabase, the network or the app
// itself into a short, plain-language message a parent can understand, and defines AppException
// for errors the app raises deliberately.

import 'package:supabase_flutter/supabase_flutter.dart';

/// Turns any thrown error into a message a parent can understand (NFR4).
///
/// AppError (class) - static-only helper; the private constructor AppError._() prevents instances.
class AppError {
  AppError._();

  /// message() - takes any error object and returns the text to show the user.
  /// It checks the error type in this order:
  ///  - AuthException: matches phrases in the message (wrong login, email already registered,
  ///    email not confirmed, password too short, too many attempts), then network errors,
  ///    otherwise returns the original message.
  ///  - StorageException: network message, otherwise "file could not be uploaded".
  ///  - PostgrestException: code 42501 means no permission (log in again); short database
  ///    messages are shown as they are; anything longer gets a generic "could not save" message.
  ///  - Anything else: network message if it looks like a connection problem, the AppException's
  ///    own message if it is one, otherwise a generic "Something went wrong" message.
  static String message(Object error) {
    if (error is AuthException) {
      final m = error.message.toLowerCase();
      if (m.contains('invalid login')) {
        return 'The email or password is incorrect. Please try again.';
      }
      if (m.contains('already registered') ||
          m.contains('already been registered')) {
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

  /// _networkMessage - the standard message shown when the server cannot be reached.
  static const String _networkMessage =
      'We could not reach the server. Please check your internet connection and try again.';

  /// _isNetwork() - private helper that returns true if the error text (lower-cased) contains a
  /// typical connection-problem phrase such as "socketexception", "failed host lookup",
  /// "timeout" or "connection refused".
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
///
/// AppException (class) - an Exception that carries a message already written for the user
/// (for example "Please choose a JPG, PNG or PDF file.").
class AppException implements Exception {
  /// Constructor - stores the user-readable message.
  AppException(this.message);

  /// message - the text shown to the user.
  final String message;

  /// toString() - returns just the message, so printing the exception shows the friendly text.
  @override
  String toString() => message;
}
