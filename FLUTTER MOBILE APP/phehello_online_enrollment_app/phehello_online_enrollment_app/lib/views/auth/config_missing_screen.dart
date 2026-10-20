import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';

/// Shown when assets/env/app.env has not been filled in yet.
class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({super.key});

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
                    Text('Connect the app to Supabase',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    SizedBox(height: 10),
                    Text(
                      'Open  assets/env/app.env  and fill in:\n\n'
                      '  SUPABASE_URL=https://YOUR-PROJECT.supabase.co\n'
                      '  SUPABASE_ANON_KEY=your public anon key\n\n'
                      'Use only the public anon key. Never put the service_role '
                      'key in this app.\n\n'
                      'Then stop and run the app again (flutter run). '
                      'See README.md for the full set-up steps.',
                      style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textDark),
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
