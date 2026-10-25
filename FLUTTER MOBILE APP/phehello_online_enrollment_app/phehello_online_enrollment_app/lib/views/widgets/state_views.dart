//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: state_views.dart defines the three reusable widgets used to show the state of a
// screen: a loading spinner, an error message with a retry button, and an empty-list message.

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'buttons.dart';

/// CenteredLoader (class) - a loading spinner in the middle of the screen with an optional message under it.
class CenteredLoader extends StatelessWidget {
  /// Constructor - message is optional.
  const CenteredLoader({super.key, this.message});

  final String? message;

  /// build() - a centred column with a CircularProgressIndicator and, if a message was given, the muted message text.
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 14),
          Text(message!, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ],
    ),
  );
}

/// ErrorState (class) - shown when loading failed: a cloud-off icon, the error message and a
/// "Try again" button that calls onRetry.
class ErrorState extends StatelessWidget {
  /// Constructor - message and onRetry are required.
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  /// build() - a centred, padded column with the icon, the message and the retry button.
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 46,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14.5, color: AppColors.textDark),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 180,
            child: OutlineBrandButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    ),
  );
}

/// EmptyState (class) - shown when a list has no items: an icon, a title and a message, plus an optional
/// action button (shown only when both actionLabel and onAction are given).
class EmptyState extends StatelessWidget {
  /// Constructor - icon, title and message are required; actionLabel and onAction are optional.
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// build() - a centred, padded column with the icon, title, message and the optional button.
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: 220,
              child: PrimaryButton(label: actionLabel!, onPressed: onAction),
            ),
          ],
        ],
      ),
    ),
  );
}
