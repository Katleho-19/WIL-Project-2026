//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members name : KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034


import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Reads the local Supabase configuration from `assets/env/app.env`.
/// Only the public anon key is ever used by the app (never a service-role key).
class AppConfig {
  AppConfig._();

  static String supabaseUrl = '';
  static String supabaseAnonKey = '';

  static bool get isConfigured =>
      supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty;

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
