//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: application_details_screen.dart defines the Application Details screen (FR5): the current
// status and payment status, learner summary, documents list with their statuses, and the parent's actions
// (replace documents, resubmit for review, upload a new proof of payment, view full details, delete).

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

/// ApplicationDetailsScreen (class) - the public entry of the screen. Status always comes from the database and is re-fetched when this screen opens.
/// It only shows what ApplicationDetailsViewModel provides and passes taps back to it.
/// Application Details / Application Status (FR5). Status always comes from
/// the database and is re-fetched when this screen opens.
///
/// The View only renders [ApplicationDetailsViewModel] and forwards taps to it.
class ApplicationDetailsScreen extends StatelessWidget {
  /// Constructor - the id of the application to show is required.
  const ApplicationDetailsScreen({super.key, required this.applicationId});

  final String applicationId;

  /// build() - provides a new ApplicationDetailsViewModel (and immediately calls refresh() on it) and shows _ApplicationDetailsView.
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

/// _ApplicationDetailsView (class) - the actual screen content (private to this file).
class _ApplicationDetailsView extends StatelessWidget {
  /// Constructor - the application id is required.
  const _ApplicationDetailsView({required this.applicationId});

  final String applicationId;

  /// _replaceDocument() - asks the view model to let the parent pick and upload a new file for a document type, then shows the returned message in a snack bar.
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

  /// _resubmit() - sends the corrected application back to the school for review and shows the result message.
  Future<void> _resubmit(
    BuildContext context,
    ApplicationDetailsViewModel vm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = await vm.resubmitForReview();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// _reuploadProof() - opens the re-upload proof sheet; if a new proof was submitted it refreshes the application and shows a confirmation message.
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

  /// _delete() - asks "Delete application?" in a dialog explaining that everything will be permanently removed. If confirmed it asks the view
  /// model to delete; on an error it shows the message, on success it closes the screen and shows "Application deleted."
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

  /// build() - watches the view model and the application. The first time a letter is available it schedules the confirmation letter dialog to open after
  /// the frame is drawn (approved or not). It then draws the header (with the reference number and a back button), a thin progress bar while refreshing and the body.
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

  /// _body() - builds the main content. It shows a loader if the application was deleted or is still loading, or an error with a retry button if it could not be loaded.
  /// Otherwise it shows a pull-to-refresh list containing: the brown status banner with the payment status chip; the Learner Information card (ID masked);
  /// a "Corrections needed" card with a Resubmit button (only when corrections were requested); the Documents list (each document with a Received/Missing chip and a Replace
  /// button while corrections are requested); the Proof of Payment row (reference, amount and the school's note if rejected); an "Upload New Proof of Payment" button
  /// (if the payment was rejected and the application is not final); and the "View Full Details" and "Delete Application" buttons.
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
    final proofRequested = app.isRequested('Proof of Payment');
    final canUploadProof =
        !isFinal &&
        (payStatus == PaymentVerificationStatus.rejected ||
            proofRequested ||
            (corrections && app.requests.isEmpty));
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
                    'Documents requested by the school',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    app.openRequests.isEmpty
                        ? 'Upload the document mentioned in the school message (see Alerts).'
                        : 'Still needed: ${app.openRequests.map((r) => r.type).join(', ')}. '
                              'Upload each one below. Your application goes back to the '
                              'school automatically once all are uploaded.',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
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
                subtitle: app.isRequested(t.dbValue)
                    ? 'Requested by the school - please upload a new copy'
                    : (app.documentOfType(t) != null
                          ? 'Received'
                          : 'Not received'),
                chip: app.documentOfType(t) != null
                    ? StatusChip.received()
                    : StatusChip.missing(),
                onReplace:
                    corrections &&
                        !vm.working &&
                        (app.requests.isEmpty || app.isRequested(t.dbValue))
                    ? () => _replaceDocument(context, vm, t)
                    : null,
              ),
          _DocumentRow(
            title: 'Proof of Payment',
            subtitle: payment == null
                ? 'Not received'
                : (proofRequested
                      ? 'Requested by the school - please upload a new proof'
                      : payStatus.documentSubtitle),
            extra: payment == null
                ? null
                : 'Reference: ${payment.reference} • ${Formatters.money(payment.amount)}'
                      '${(payment.notes ?? '').isNotEmpty && payStatus == PaymentVerificationStatus.rejected ? '\nSchool note: ${payment.notes}' : ''}',
            chip: payment == null
                ? StatusChip.missing()
                : StatusChip.payment(payStatus),
          ),

          if (canUploadProof) ...[
            const SizedBox(height: 16),

            PrimaryButton(
              label: 'Upload New Proof of Payment',
              icon: Icons.upload_file_rounded,
              onPressed: vm.working
                  ? null
                  : () => _reuploadProof(context, vm, app),
            ),

            const SizedBox(height: 12),

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
        ],
      ),
    );
  }
}

/// _InfoLine (class) - one line of text in the form 'Label: value', with a muted label and a bold value.
class _InfoLine extends StatelessWidget {
  /// Constructor - label and value are positional parameters.
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  /// build() - a padded rich-text line combining the muted label and the bold value.
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

/// _DocumentRow (class) - one row of the documents list: title, subtitle, optional extra text, a status chip on the right and an optional
/// Replace button (shown only if onReplace is provided).
class _DocumentRow extends StatelessWidget {
  /// Constructor - title, subtitle and chip are required; extra and onReplace are optional.
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

  /// build() - a row with a bottom border: the text column on the left (title, subtitle, extra) and the chip with the optional Replace button on the right.
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
