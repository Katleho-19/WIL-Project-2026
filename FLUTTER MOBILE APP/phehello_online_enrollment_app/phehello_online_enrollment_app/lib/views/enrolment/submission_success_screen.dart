import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/shell_nav_view_model.dart';
import '../widgets/buttons.dart';

/// Shown after the application has been stored in Supabase.
class SubmissionSuccessScreen extends StatelessWidget {
  const SubmissionSuccessScreen({super.key, required this.referenceNumber});

  final String referenceNumber;

  void _goTo(BuildContext context, int tab) {
    context.read<ShellNavViewModel>().setIndex(tab);
    RouteManager.popToRoot(context);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goTo(context, 0);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.check_circle_rounded, size: 84, color: AppColors.approvedFg),
                const SizedBox(height: 18),
                const Text('Application submitted',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (referenceNumber.isNotEmpty)
                  Text('Reference: $referenceNumber',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brown)),
                const SizedBox(height: 10),
                const Text(
                  'Your documents and proof of payment were received. The Financial Clerk will verify your '
                  'payment and the Administrator will review your application. You can follow progress under '
                  '"Applications" and in "Alerts".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
                ),
                const SizedBox(height: 28),
                PrimaryButton(label: 'View Application Status', onPressed: () => _goTo(context, 1)),
                const SizedBox(height: 10),
                OutlineBrandButton(label: 'Back to Home', onPressed: () => _goTo(context, 0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
