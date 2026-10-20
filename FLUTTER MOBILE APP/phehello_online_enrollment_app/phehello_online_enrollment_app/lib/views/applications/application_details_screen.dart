import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/application_repository.dart';
import '../../data/services/file_picker_service.dart';
import '../../models/enrolment_application.dart';
import '../../models/enums.dart';
import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../viewmodels/application_details_view_model.dart';
import '../../viewmodels/applications_view_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/state_views.dart';
import '../widgets/status_chip.dart';
import 'confirmation_letter_dialog.dart';

/// Application Details / Application Status (FR5). Status always comes from
/// the database and is re-fetched when this screen opens.
///
/// The View only renders [ApplicationDetailsViewModel] and forwards taps to it.
class ApplicationDetailsScreen extends StatelessWidget {
  const ApplicationDetailsScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ApplicationDetailsViewModel>(
      create: (ctx) => ApplicationDetailsViewModel(
        applicationId: applicationId,
        repository: ctx.read<ApplicationRepository>(),
        filePicker: ctx.read<FilePickerService>(),
        applications: ctx.read<ApplicationsViewModel>(),
        auth: ctx.read<AuthViewModel>(),
      )..refresh(),
      child: _ApplicationDetailsView(applicationId: applicationId),
    );
  }
}

class _ApplicationDetailsView extends StatelessWidget {
  const _ApplicationDetailsView({required this.applicationId});

  final String applicationId;

  Future<void> _replaceDocument(
    BuildContext context,
    ApplicationDetailsViewModel vm,
    DocumentType type,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await vm.replaceDocument(type);
    if (message != null)
      messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resubmit(
    BuildContext context,
    ApplicationDetailsViewModel vm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await vm.resubmitForReview();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _reuploadProof(
    BuildContext context,
    ApplicationDetailsViewModel vm,
    EnrolmentApplication app,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final done = await RouteManager.showReuploadProof(context, app);
    if (done == true) {
      await vm.refresh();
      messenger.showSnackBar(
        const SnackBar(content: Text('New proof of payment submitted.')),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    ApplicationDetailsViewModel vm,
    EnrolmentApplication app,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete application?'),
        content: Text(
          'This permanently deletes application ${app.referenceNumber}, '
          'including the learner details, uploaded documents and proof of '
          'payment. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await vm.deleteApplication();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Application deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ApplicationDetailsViewModel>();
    final app = context.watch<ApplicationsViewModel>().byId(applicationId);

    if (app != null && vm.shouldAutoShowLetter) {
      vm.markLetterPromptShown();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ConfirmationLetterDialog.show(
            context,
            vm: vm,
            approved: app.status == ApplicationStatus.approved,
          );
        }
      });
    }

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Application Details',
            subtitle: app?.referenceNumber ?? '',
            onBack: () => Navigator.of(context).pop(),
          ),
          if (vm.refreshing && app != null)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(child: _body(context, vm, app)),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    ApplicationDetailsViewModel vm,
    EnrolmentApplication? app,
  ) {
    if (vm.deleted) return const CenteredLoader();
    if (app == null) {
      if (vm.refreshing) return const CenteredLoader();
      return ErrorState(
        message:
            'We could not load this application. Please check your connection.',
        onRetry: vm.refresh,
      );
    }
    final payment = app.latestPayment;
    final payStatus = payment?.status ?? app.paymentStatus;
    final isFinal =
        app.status == ApplicationStatus.approved ||
        app.status == ApplicationStatus.rejected;
    final corrections = app.status == ApplicationStatus.correctionsRequested;
    final learner = app.learner;

    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
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
                  'APPLICATION STATUS',
                  style: TextStyle(
                    color: Color(0xFFE9DCCF),
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  app.status.dbValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  app.status.bannerDescription,
                  style: const TextStyle(
                    color: Color(0xFFE9DCCF),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Payment: ',
                      style: TextStyle(
                        color: Color(0xFFE9DCCF),
                        fontSize: 12.5,
                      ),
                    ),
                    StatusChip.payment(payStatus),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learner Information',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                _InfoLine('First Name', learner?.firstName ?? '-'),
                _InfoLine('Surname', learner?.surname ?? '-'),
                _InfoLine('ID Number', Formatters.maskId(learner?.idNumber)),
                _InfoLine(
                  'Date of Birth',
                  learner?.dateOfBirth == null
                      ? '-'
                      : Formatters.longDate(learner!.dateOfBirth!),
                ),
                if ((learner?.studentNumber ?? '').isNotEmpty)
                  _InfoLine('Student Number', learner!.studentNumber!),
              ],
            ),
          ),
          if (corrections) ...[
            const SizedBox(height: 14),
            AppCard(
              color: const Color(0xFFFFF6EC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Corrections needed',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Check the Alerts tab for the message from the school. Replace the '
                    'documents below, then send your application back for review.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Resubmit for Review',
                    loading: vm.working,
                    onPressed: () => _resubmit(context, vm),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Documents',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          for (final t in DocumentType.values)
            if (app.documentOfType(t) != null || t.isRequired)
              _DocumentRow(
                title: t.label,
                subtitle: app.documentOfType(t) != null
                    ? 'Received'
                    : 'Not received',
                chip: app.documentOfType(t) != null
                    ? StatusChip.received()
                    : StatusChip.missing(),
                onReplace: corrections && !vm.working
                    ? () => _replaceDocument(context, vm, t)
                    : null,
              ),
          _DocumentRow(
            title: 'Proof of Payment',
            subtitle: payment == null
                ? 'Not received'
                : payStatus.documentSubtitle,
            extra: payment == null
                ? null
                : 'Reference: ${payment.reference} • ${Formatters.money(payment.amount)}'
                      '${(payment.notes ?? '').isNotEmpty && payStatus == PaymentVerificationStatus.rejected ? '\nSchool note: ${payment.notes}' : ''}',
            chip: payment == null
                ? StatusChip.missing()
                : StatusChip.payment(payStatus),
          ),
          if (payStatus == PaymentVerificationStatus.rejected && !isFinal) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Upload New Proof of Payment',
              icon: Icons.upload_file_rounded,
              onPressed: vm.working
                  ? null
                  : () => _reuploadProof(context, vm, app),
            ),
          ],
          const SizedBox(height: 16),
          OutlineBrandButton(
            label: 'View Full Details',
            onPressed: () => RouteManager.toFullDetails(context, app.id),
          ),

          const SizedBox(height: 12),
          OutlineBrandButton(
            label: 'Delete Application',
            icon: Icons.delete_outline_rounded,
            danger: true,
            onPressed: vm.working ? null : () => _delete(context, vm, app),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppColors.textMuted),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 13),
    ),
  );
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({
    required this.title,
    required this.subtitle,
    required this.chip,
    this.extra,
    this.onReplace,
  });

  final String title;
  final String subtitle;
  final String? extra;
  final Widget chip;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
                if (extra != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    extra!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              chip,
              if (onReplace != null) ...[
                const SizedBox(height: 6),
                SmallOutlineButton(label: 'Replace', onPressed: onReplace),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
