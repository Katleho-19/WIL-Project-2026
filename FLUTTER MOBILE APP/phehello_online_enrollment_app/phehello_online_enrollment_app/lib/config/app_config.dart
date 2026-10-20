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
