//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: home_screen.dart defines the Home / Dashboard tab: the school header, a greeting with the
// parent's name, the "New Application" call-to-action, the saved-draft card, a preview of the latest two
// applications and two quick-action tiles.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/school_info.dart';
import '../../models/enrolment_application.dart';
import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../viewmodels/applications_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/notifications_view_model.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../viewmodels/shell_nav_view_model.dart';
import '../widgets/app_card.dart';
import '../widgets/buttons.dart';
import '../widgets/school_crest.dart';
import '../widgets/state_views.dart';
import '../widgets/status_chip.dart';
import '../../models/enrolment_draft.dart';
import '../../viewmodels/draft_view_model.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';

/// HomeScreen (class) - the first tab of the main shell (FR5 entry point). It has no state of its own; it reads everything from the view models.
/// Home / Dashboard (FR5 entry point).
class HomeScreen extends StatelessWidget {
  /// Constructor - no required parameters.
  const HomeScreen({super.key});

  /// build() - watches the auth, applications, draft, notifications and settings view models. Chooses the display name
  /// (or "Parent / Guardian" if the name is empty). Draws: the brown school header (with a white dot that opens the Alerts
  /// tab when there are unread notifications and notifications are on); then a pull-to-refresh list containing the greeting,
  /// the name, the brown WELCOME card with the gold "New Application" button, the "Your Applications" heading, the saved-draft
  /// card (only if a draft exists), the applications preview, the two quick tiles (New Application / My Applications) and the school motto.
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final apps = context.watch<ApplicationsViewModel>();
    final draft = context.watch<DraftViewModel>().draft;
    final unread = context.watch<NotificationsViewModel>().unreadCount;
    final notificationsOn = context
        .watch<SettingsViewModel>()
        .notificationsEnabled;
    final name = auth.fullName.trim().isEmpty
        ? 'Parent / Guardian'
        : auth.fullName.trim();

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: AppColors.brown,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  const SchoolCrest(height: 44),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PHEHELLO SECONDARY SCHOOL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Online Enrolment System',
                          style: TextStyle(
                            color: Color(0xFFE9DCCF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0 && notificationsOn)
                    InkWell(
                      onTap: () =>
                          context.read<ShellNavViewModel>().setIndex(2),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => context.read<ApplicationsViewModel>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                Text(
                  Formatters.greeting(),
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.brown,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WELCOME',
                        style: TextStyle(
                          color: Color(0xFFE9DCCF),
                          fontSize: 11,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ready to enrol your learner?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Start a new application or track an existing one.',
                        style: TextStyle(
                          color: Color(0xFFE9DCCF),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'New Application',
                        gold: true,
                        onPressed: () => RouteManager.newApplication(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Your Applications',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                if (draft != null) ...[
                  _SavedDraftCard(draft: draft),
                  const SizedBox(height: 10),
                ],
                _ApplicationsPreview(apps: apps, hasDraft: draft != null),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickTile(
                        title: 'New Application',
                        subtitle: 'Start enrolment',
                        onTap: () => RouteManager.startEnrolment(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickTile(
                        icon: Icons.list_alt_outlined,
                        title: 'My Applications',
                        subtitle: 'Track progress',
                        onTap: () =>
                            context.read<ShellNavViewModel>().setIndex(1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    SchoolInfo.motto,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// _ApplicationsPreview (class) - the applications area of the dashboard. It receives the ApplicationsViewModel (apps)
/// and whether a saved draft is already shown (hasDraft).
class _ApplicationsPreview extends StatelessWidget {
  /// Constructor - apps is required; hasDraft defaults to false.
  const _ApplicationsPreview({required this.apps, this.hasDraft = false});

  final ApplicationsViewModel apps;
  final bool hasDraft;

  /// build() - decides what to show: a loader while loading for the first time; an error message with a retry button if loading
  /// failed and nothing is loaded; an "No applications yet" card if the list is empty (hidden if a draft card is already shown);
  /// otherwise the two most recent applications as _HomeApplicationCard widgets.
  @override
  Widget build(BuildContext context) {
    if (apps.loading && apps.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: CenteredLoader(),
      );
    }
    if (apps.error != null && apps.items.isEmpty) {
      return SizedBox(
        height: 220,
        child: ErrorState(message: apps.error!, onRetry: () => apps.load()),
      );
    }
    if (apps.items.isEmpty) {
      if (hasDraft) return const SizedBox.shrink();
      return const AppCard(
        child: Column(
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 38,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 8),
            Text(
              'No applications yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4),
            Text(
              'Tap "New Application" to enrol your learner.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    final shown = apps.items.take(2).toList();
    return Column(
      children: [
        for (final a in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HomeApplicationCard(app: a),
          ),
      ],
    );
  }
}

/// _SavedDraftCard (class) - the card for the saved, unsubmitted application, with a Continue button and a delete link.
/// The saved (unsubmitted) application, with a Continue button.
class _SavedDraftCard extends StatelessWidget {
  /// Constructor - the saved EnrolmentDraft is required.
  const _SavedDraftCard({required this.draft});

  final EnrolmentDraft draft;

  /// _delete() - asks "Delete saved application?" in a dialog (Keep / Delete). If the parent confirms, it tells
  /// DraftViewModel to discard the saved draft from the device.
  Future<void> _delete(BuildContext context) async {
    final drafts = context.read<DraftViewModel>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete saved application?'),
        content: const Text(
          'Your saved answers will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await drafts.discard();
  }

  /// build() - works out the draft's current step (kept between the first and last step), the learner's name and the
  /// saved time, then draws a card with: the title, the learner name (or "Learner not named yet"), a yellow DRAFT badge, "Step X of 6 - step title",
  /// "Last saved ..." (if known), a progress bar, the "Continue Application" button (restores the draft and opens the wizard) and the
  /// red "Delete saved application" link.
  @override
  Widget build(BuildContext context) {
    final stepIndex = draft.step
        .clamp(0, EnrolmentFlowViewModel.stepCount - 1)
        .toInt();
    final learner = draft.learnerName;
    final savedAt = draft.savedAt;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Saved application',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      learner.isEmpty ? 'Learner not named yet' : learner,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pendingBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'DRAFT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pendingFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Step ${stepIndex + 1} of ${EnrolmentFlowViewModel.stepCount} \u2022 '
            '${EnrolmentFlowViewModel.stepTitles[stepIndex]}',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          if (savedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Last saved ${Formatters.dateTimeLabel(savedAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (stepIndex + 1) / EnrolmentFlowViewModel.stepCount,
              minHeight: 6,
              backgroundColor: AppColors.tile,
              color: AppColors.brown,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Continue Application',
            icon: Icons.play_arrow_rounded,
            onPressed: () =>
                RouteManager.startEnrolment(context, continueDraft: true),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => _delete(context),
              child: const Text(
                'Delete saved application',
                style: TextStyle(color: AppColors.error, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// _HomeApplicationCard (class) - a summary card for one application on the dashboard.
class _HomeApplicationCard extends StatelessWidget {
  /// Constructor - the EnrolmentApplication is required.
  const _HomeApplicationCard({required this.app});

  final EnrolmentApplication app;

  /// build() - draws the reference number, the subtitle (grade and submission date), the status chip and a "View Application"
  /// button that opens the Application Details screen.
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application ${app.referenceNumber}',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      app.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusChip.application(app.status),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          OutlineBrandButton(
            label: 'View Application',
            height: 44,
            onPressed: () => RouteManager.toApplicationDetails(context, app.id),
          ),
        ],
      ),
    );
  }
}

/// _QuickTile (class) - a small tappable tile with an optional icon, a title and a subtitle, used for the two quick actions.
class _QuickTile extends StatelessWidget {
  /// Constructor - title, subtitle and onTap are required; icon is optional.
  const _QuickTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;

  /// build() - an AppCard that calls onTap when pressed, showing the optional icon beside the bold title and the muted subtitle below.
  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
