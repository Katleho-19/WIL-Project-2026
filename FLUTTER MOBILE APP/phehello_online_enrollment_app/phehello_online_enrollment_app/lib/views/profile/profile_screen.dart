//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: profile_screen.dart defines the Profile tab: the parent's name and email, the menu
// (Personal Details, Change Password, Notifications ON/OFF, Help & Support) and the Log Out button.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../viewmodels/shell_nav_view_model.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';

/// ProfileScreen (class) - the Profile tab of the main shell. It has no state of its own; it reads the name, email and notification setting from the view models.
/// Profile / account area.
class ProfileScreen extends StatelessWidget {
  /// Constructor - no required parameters.
  const ProfileScreen({super.key});

  /// _logout() - asks "Log out?" in a dialog. If the parent confirms (and the screen is still showing) it switches the bottom navigation back to Home and signs out;
  /// the auth gate then shows the login screen automatically.
  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to sign in again to see your applications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    context.read<ShellNavViewModel>().setIndex(0);
    await context.read<AuthViewModel>().signOut();
    // AuthGate shows the login screen once the session is cleared.
  }

  /// build() - watches AuthViewModel and SettingsViewModel and chooses the display name (or "Parent / Guardian"). Draws the "Profile" header, a round person avatar, the name and
  /// email, four _MenuRow items (Personal Details, Change Password, Notifications showing ON/OFF - tapping it toggles the setting, Help & Support) and the red "Log Out" button.
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final settings = context.watch<SettingsViewModel>();
    final name = auth.fullName.trim().isEmpty
        ? 'Parent / Guardian'
        : auth.fullName.trim();
    return Column(
      children: [
        const AppHeader(
          title: 'Profile',
          subtitle: 'Parent / Guardian account',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    color: AppColors.tile,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 42,
                    color: AppColors.brown,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                auth.email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 22),
              _MenuRow(
                title: 'Personal Details',
                subtitle: 'Manage your account information',
                onTap: () => RouteManager.toPersonalDetails(context),
              ),
              _MenuRow(
                title: 'Change Password',
                onTap: () => RouteManager.toChangePassword(context),
              ),
              _MenuRow(
                title: 'Notifications',
                trailing: Text(
                  settings.notificationsEnabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: settings.notificationsEnabled
                        ? AppColors.approvedFg
                        : AppColors.textMuted,
                  ),
                ),
                onTap: () => settings.setNotificationsEnabled(
                  !settings.notificationsEnabled,
                ),
              ),
              _MenuRow(
                title: 'Help & Support',
                onTap: () => RouteManager.toHelpSupport(context),
              ),
              const SizedBox(height: 18),
              OutlineBrandButton(
                label: 'Log Out',
                danger: true,
                height: 50,
                onPressed: () => _logout(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// _MenuRow (class) - one tappable row of the profile menu: a bold title, an optional subtitle and, on the right, either a custom 'trailing' widget or a chevron arrow.
class _MenuRow extends StatelessWidget {
  /// Constructor - title and onTap are required; subtitle and trailing are optional.
  const _MenuRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  /// build() - an InkWell row with a bottom border, the title (and subtitle) on the left and the trailing widget or chevron on the right.
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
        ],
      ),
    ),
  );
}
