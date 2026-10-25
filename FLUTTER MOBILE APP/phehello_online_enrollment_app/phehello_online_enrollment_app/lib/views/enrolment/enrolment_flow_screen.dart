//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: enrolment_flow_screen.dart defines the six-step enrolment wizard screen: the header with
// "Save & Close", the step progress bar, the current step, and the back / leave / save-draft behaviour.

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

/// EnrolmentFlowScreen (class) - hosts the six steps. Back works at every step; leaving from the first step (or using the app tabs) asks whether to save a draft.
/// All wizard state is in EnrolmentFlowViewModel, which is provided by RouteManager.
/// Six-step enrolment wizard. Back works at every step; leaving the first
/// step (or the app tabs) asks whether to save a draft.
class EnrolmentFlowScreen extends StatefulWidget {
  /// Constructor - no required parameters.
  const EnrolmentFlowScreen({super.key});

  /// createState() - creates the State object _EnrolmentFlowScreenState.
  @override
  State<EnrolmentFlowScreen> createState() => _EnrolmentFlowScreenState();
}

/// _EnrolmentFlowScreenState (class) - contains the wizard's navigation and leave logic.
class _EnrolmentFlowScreenState extends State<EnrolmentFlowScreen> {
  /// initState() - if a saved draft was restored, shows a snack bar after the first frame: the saved answers were restored but the documents must be attached again.
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

  /// _confirmLeave() - returns true if the parent may leave. If there is nothing to lose it returns true at once; otherwise it asks "Leave this application?"
  /// with three choices: Keep editing (stay), Discard (delete the draft and leave) and Save draft & exit (save and leave).
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

  /// _saveAndClose() - the "Save & Close" button, available on every step with no validation. It does nothing while a submission is running; otherwise it saves the draft,
  /// closes the wizard and shows a snack bar explaining how to continue from the home screen.
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

  /// _handleBack() - ignores back while submitting; on steps after the first it goes to the previous step; on the first step it asks _confirmLeave() and closes the wizard if allowed.
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

  /// _tabTapped() - used by the bottom navigation on the last two steps: after _confirmLeave() allows it, closes the wizard and selects the tapped tab (reloading applications for tab 1).
  Future<void> _tabTapped(int index) async {
    final leave = await _confirmLeave();
    if (!leave || !mounted) return;
    final nav = context.read<ShellNavViewModel>();
    Navigator.of(context).pop();
    nav.setIndex(index);
    if (index == 1) context.read<ApplicationsViewModel>().load();
  }

  /// build() - lists the six step widgets and shows the current one inside a PopScope (so the system back button runs _handleBack). The page has the "Application" header (step title and
  /// "X of 6", back button and a "Save & Close" button disabled during submission), the StepProgress indicator and the current step with a short fade animation. From step 5 onward it also shows the bottom navigation bar.
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
