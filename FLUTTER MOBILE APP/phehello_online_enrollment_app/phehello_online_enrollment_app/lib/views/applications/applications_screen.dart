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

/// My Applications (FR5): filter All / Pending / Approved / Rejected.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  static const _labels = {
    ApplicationFilter.all: 'All',
    ApplicationFilter.pending: 'Pending',
    ApplicationFilter.approved: 'Approved',
    ApplicationFilter.rejected: 'Rejected',
  };

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

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

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

class _ApplicationListCard extends StatelessWidget {
  const _ApplicationListCard({required this.app});

  final EnrolmentApplication app;

  void _open(BuildContext context) {
    RouteManager.toApplicationDetails(context, app.id);
  }

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
