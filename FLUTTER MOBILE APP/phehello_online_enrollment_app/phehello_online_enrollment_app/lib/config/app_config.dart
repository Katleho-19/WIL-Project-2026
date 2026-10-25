//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: app_config.dart holds the Supabase settings (URL and public key) read from a local
// environment file, and tells the rest of the app whether those settings are present.

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads the local Supabase configuration from `assets/env/app.env`.
/// Only the public anon key is ever used by the app (never a service-role key).
///
/// AppConfig (class) - a static-only holder for configuration values. The private constructor
/// AppConfig._() stops anyone from creating an instance; everything is accessed as AppConfig.xxx.
class AppConfig {
  AppConfig._();

  /// supabaseUrl - the Supabase project address; empty until load() succeeds.
  static String supabaseUrl = '';

  /// supabaseAnonKey - the public (anon) Supabase key; empty until load() succeeds.
  static String supabaseAnonKey = '';

  /// isConfigured (getter) - returns true only when the URL starts with "http" and a key exists.
  /// Used to decide whether to show the "configuration missing" screen.
  static bool get isConfigured =>
      supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty;

  /// load() - reads assets/env/app.env with flutter_dotenv and copies SUPABASE_URL and
  /// SUPABASE_ANON_KEY (trimmed, defaulting to empty text) into the static fields above.
  /// If the file is missing or unreadable, the error is swallowed and both values are reset
  /// to empty, which makes isConfigured return false.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: 'assets/env/app.env');
      supabaseUrl = (dotenv.env['SUPABASE_URL'] ?? '').trim();
      supabaseAnonKey = (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();
    } catch (_) {
      supabaseUrl = '';
      supabaseAnonKey = '';
    }
  }
}
