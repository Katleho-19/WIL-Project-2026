//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: applications_screen.dart defines the My Applications tab (FR5): a list of all the parent's
// applications with filter pills (All / Pending / Approved / Rejected) and the loading, error and empty states.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enrolment_application.dart';
import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../viewmodels/applications_view_model.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/state_views.dart';
import '../widgets/status_chip.dart';

/// ApplicationsScreen (class) - the Applications tab of the main shell. It has no state of its own; the list and the selected filter live in ApplicationsViewModel.
/// My Applications (FR5): filter All / Pending / Approved / Rejected.
class ApplicationsScreen extends StatelessWidget {
  /// Constructor - no required parameters.
  const ApplicationsScreen({super.key});

  /// _labels - the text shown on each filter pill.
  static const _labels = {
    ApplicationFilter.all: 'All',
    ApplicationFilter.pending: 'Pending',
    ApplicationFilter.approved: 'Approved',
    ApplicationFilter.rejected: 'Rejected',
  };

  /// build() - watches ApplicationsViewModel and takes the filtered list. It chooses the body: a loader on first load; an error
  /// message with a retry button; an empty-state with a "Start New Application" button if there are no applications at all; a "Nothing here"
  /// message if the selected filter has no matches; otherwise a pull-to-refresh list of _ApplicationListCard widgets. It then draws the
  /// "My Applications" header, a horizontal row of _FilterPill buttons and the body.
  @override
  Widget build(BuildContext context) {
    final apps = context.watch<ApplicationsViewModel>();
    final list = apps.filtered;

    Widget body;
    if (apps.loading && apps.items.isEmpty) {
      body = const CenteredLoader(message: 'Loading your applications...');
    } else if (apps.error != null && apps.items.isEmpty) {
      body = ErrorState(message: apps.error!, onRetry: () => apps.load());
    } else if (apps.items.isEmpty) {
      body = EmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No applications yet',
        message:
            'When you submit an enrolment application it will appear here so you can track its progress.',
        actionLabel: 'Start New Application',
        onAction: () => RouteManager.newApplication(context),
      );
    } else if (list.isEmpty) {
      body = const EmptyState(
        icon: Icons.filter_list_off_rounded,
        title: 'Nothing here',
        message: 'You have no applications with this status.',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () => apps.load(),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ApplicationListCard(app: list[i]),
        ),
      );
    }

    return Column(
      children: [
        const AppHeader(
          title: 'My Applications',
          subtitle: 'Track your enrolment applications',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in ApplicationFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _FilterPill(
                      label: _labels[f]!,
                      selected: apps.filter == f,
                      onTap: () => apps.setFilter(f),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}

/// _FilterPill (class) - one pill-shaped filter button; brown with white text when selected, light tile with brown text when not.
class _FilterPill extends StatelessWidget {
  /// Constructor - label, selected and onTap are required.
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// build() - a tappable rounded container showing the label, coloured according to 'selected'.
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brown : AppColors.tile,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppColors.brownDark,
          ),
        ),
      ),
    );
  }
}

/// _ApplicationListCard (class) - the card for one application in the list.
class _ApplicationListCard extends StatelessWidget {
  /// Constructor - the EnrolmentApplication is required.
  const _ApplicationListCard({required this.app});

  final EnrolmentApplication app;

  /// _open() - opens the Application Details screen for this application.
  void _open(BuildContext context) {
    RouteManager.toApplicationDetails(context, app.id);
  }

  /// build() - works out whether the application is in the pending group and what its latest payment status is. The card shows the
  /// reference number, the subtitle and the status chip; for pending applications it also shows the payment status line and a "View Details" button.
  /// Tapping anywhere on the card opens the details.
  @override
  Widget build(BuildContext context) {
    final pending = app.status.isPendingGroup;
    final payment = app.latestPayment?.status ?? app.paymentStatus;
    return AppCard(
      onTap: () => _open(context),
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
                      app.referenceNumber,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
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
          if (pending) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            Text(
              'Payment: ${payment.parentLabel}',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            OutlineBrandButton(
              label: 'View Details',
              height: 42,
              onPressed: () => _open(context),
            ),
          ],
        ],
      ),
    );
  }
}
