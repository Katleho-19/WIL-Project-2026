//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: config_missing_screen.dart defines a help screen that explains how to connect the
// app to Supabase through assets/env/app.env. Note: nothing in the app currently opens this screen,
// because main.dart initialises Supabase directly with its own URL and key.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';

/// ConfigMissingScreen (class) - a static page telling the developer that the Supabase settings have not been filled in.
/// Shown when assets/env/app.env has not been filled in yet.
class ConfigMissingScreen extends StatelessWidget {
  /// Constructor - no required parameters.
  const ConfigMissingScreen({super.key});

  /// build() - a page with the brown "Setup required" header and, underneath, a scrollable card with instructions:
  /// open assets/env/app.env, fill in SUPABASE_URL and SUPABASE_ANON_KEY (public anon key only, never the
  /// service_role key), then restart the app with flutter run.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppHeader(
            title: 'Setup required',
            subtitle: 'Supabase is not configured yet',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Connect the app to Supabase',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Open  assets/env/app.env  and fill in:\n\n'
                      '  SUPABASE_URL=https://YOUR-PROJECT.supabase.co\n'
                      '  SUPABASE_ANON_KEY=your public anon key\n\n'
                      'Use only the public anon key. Never put the service_role '
                      'key in this app.\n\n'
                      'Then stop and run the app again (flutter run). '
                      'See README.md for the full set-up steps.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
