//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: supabase_service.dart gives the rest of the data layer one place to get the
// Supabase client, and can initialise Supabase from the values in AppConfig.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

/// Thin wrapper around the Supabase client.
///
/// SupabaseService (class) - static-only; the private constructor SupabaseService._() prevents instances.
class SupabaseService {
  SupabaseService._();

  /// initialize() - starts Supabase using the URL and key stored in AppConfig.
  /// Note: main.dart currently calls Supabase.initialize directly with its own values,
  /// so this method is only needed if the app is switched to load settings from the env file.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  /// client (getter) - returns the shared Supabase client used by every repository.
  static SupabaseClient get client => Supabase.instance.client;
}
