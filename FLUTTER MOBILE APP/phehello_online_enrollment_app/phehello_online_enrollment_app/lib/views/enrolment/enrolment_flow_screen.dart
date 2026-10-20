import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../viewmodels/applications_view_model.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';
import '../../viewmodels/shell_nav_view_model.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/app_header.dart';
import '../widgets/step_progress.dart';
import 'academic_step.dart';
import 'guardian_documents_step.dart';
import 'learner_step.dart';
import 'medical_step.dart';
import 'payment_info_step.dart';
import 'proof_of_payment_step.dart';

/// Six-step enrolment wizard. Back works at every step; leaving the first
/// step (or the app tabs) asks whether to save a draft.
class EnrolmentFlowScreen extends StatefulWidget {
  const EnrolmentFlowScreen({super.key});

  @override
  State<EnrolmentFlowScreen> createState() => _EnrolmentFlowScreenState();
}

class _EnrolmentFlowScreenState extends State<EnrolmentFlowScreen> {
  @override
  void initState() {
    super.initState();
    final restored = context.read<EnrolmentFlowViewModel>().restoredDraft;
    if (restored) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We restored your saved answers. Please re-attach your documents.',
            ),
          ),
        );
      });
    }
  }

  Future<bool> _confirmLeave() async {
    final flow = context.read<EnrolmentFlowViewModel>();
    if (!flow.hasUnsavedWork) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave this application?'),
        content: const Text(
          'You can save your answers and continue later. Uploaded files are not saved and will need to be chosen again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'stay'),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'discard'),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: const Text('Save draft & exit'),
          ),
        ],
      ),
    );
    if (choice == 'save') {
      await flow.saveDraft();
      return true;
    }
    if (choice == 'discard') {
      await flow.discardDraft();
      return true;
    }
    return false;
  }

  /// "Save & Close" - available on every step. Needs no validation: it stores
  /// whatever has been entered plus the current step, then returns to the
  /// dashboard where the draft shows a "Continue Application" button.
  Future<void> _saveAndClose() async {
    final flow = context.read<EnrolmentFlowViewModel>();
    if (flow.submitState == SubmitState.submitting) return;
    FocusScope.of(context).unfocus();
    await flow.saveDraft();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Application saved. Tap "Continue Application" on the home screen to carry on.',
        ),
      ),
    );
  }

  Future<void> _handleBack() async {
    final flow = context.read<EnrolmentFlowViewModel>();
    if (flow.submitState == SubmitState.submitting) return;
    if (flow.step > 0) {
      flow.goBack();
      return;
    }
    final leave = await _confirmLeave();
    if (leave && mounted) Navigator.of(context).pop();
  }

  Future<void> _tabTapped(int index) async {
    final leave = await _confirmLeave();
    if (!leave || !mounted) return;
    final nav = context.read<ShellNavViewModel>();
    Navigator.of(context).pop();
    nav.setIndex(index);
    if (index == 1) context.read<ApplicationsViewModel>().load();
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<EnrolmentFlowViewModel>();
    final step = flow.step;
    final steps = <Widget>[
      const LearnerStep(),
      const AcademicStep(),
      const MedicalStep(),
      const GuardianDocumentsStep(),
      const PaymentInfoStep(),
      const ProofOfPaymentStep(),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        body: Column(
          children: [
            AppHeader(
              title: 'Application',
              subtitle:
                  '${EnrolmentFlowViewModel.stepTitles[step]} • ${step + 1} of '
                  '${EnrolmentFlowViewModel.stepCount}',
              onBack: _handleBack,
              trailing: TextButton.icon(
                onPressed: flow.submitState == SubmitState.submitting
                    ? null
                    : _saveAndClose,
                icon: const Icon(
                  Icons.bookmark_added_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'Save & Close',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            StepProgress(current: step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: KeyedSubtree(
                  key: ValueKey<int>(step),
                  child: steps[step],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: step >= 4
            ? AppBottomNav(currentIndex: 1, onTap: _tabTapped)
            : null,
      ),
    );
  }
}
