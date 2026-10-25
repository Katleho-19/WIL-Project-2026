//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: route_manager.dart is the single place that knows every screen (route) in the app.
// It maps route names to screens for MaterialApp, and offers static helper methods (toXxx) that the
// views call to navigate, so a view never builds a page route itself. It also builds the enrolment
// wizard's view model and shows the "saved application" dialog and the re-upload proof sheet.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repositories/application_repository.dart';
import '../data/services/draft_storage.dart';
import '../data/services/file_picker_service.dart';
import '../models/enrolment_application.dart';
import '../theme/app_colors.dart';
import '../viewmodels/applications_view_model.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/enrolment_flow_view_model.dart';
import '../views/applications/application_details_screen.dart';
import '../views/applications/full_details_screen.dart';
import '../views/applications/reupload_proof_sheet.dart';
import '../views/auth/register_screen.dart';
import '../views/enrolment/enrolment_flow_screen.dart';
import '../views/enrolment/submission_success_screen.dart';
import '../views/profile/change_password_screen.dart';
import '../views/profile/help_support_screen.dart';
import '../views/profile/personal_details_screen.dart';
import '../viewmodels/draft_view_model.dart';

/// RouteManager (class) - static-only navigation helper; the private constructor RouteManager._()
/// prevents instances.
/// Single place that knows every route in the app.
///
/// * [onGenerateRoute] maps a route name (+ typed arguments) to a screen and is
///   plugged into `MaterialApp` in `app.dart`.
/// * The static `toXxx` helpers are what Views call, so a View never builds a
///   `MaterialPageRoute` or knows which screen class sits behind a route.
///
/// The auth gate (`Login` / `MainShell`) is the app's `home`, not a named
/// route: it is chosen by the auth state, not by navigation.
class RouteManager {
  RouteManager._();

  /// Route names - the text identifiers used to open each named screen.
  // ----------------------------------------------------------- route names
  static const String register = '/register';
  static const String personalDetails = '/profile/personal-details';
  static const String changePassword = '/profile/change-password';
  static const String helpSupport = '/profile/help';
  static const String helpContent = '/profile/help/topic';
  static const String applicationDetails = '/applications/details';
  static const String fullDetails = '/applications/full-details';
  static const String enrolment = '/enrolment';
  static const String submissionSuccess = '/enrolment/success';

  /// onGenerateRoute() - plugged into MaterialApp (see app.dart). Given a route name and its
  /// arguments it returns the page to show: register, personal details, change password, help &
  /// support, help topic content (argument: HelpTopic), application details and full details
  /// (argument: application id), the enrolment wizard (argument: its EnrolmentFlowViewModel, which
  /// the route provides to the screen and disposes) and the submission success screen (argument: the
  /// reference number). Unknown names show a "Page not found" screen.
  // ------------------------------------------------------ route -> screen map
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case register:
        return _page(settings, (_) => const RegisterScreen());
      case personalDetails:
        return _page(settings, (_) => const PersonalDetailsScreen());
      case changePassword:
        return _page(settings, (_) => const ChangePasswordScreen());
      case helpSupport:
        return _page(settings, (_) => const HelpSupportScreen());
      case helpContent:
        final topic = settings.arguments as HelpTopic;
        return _page(settings, (_) => HelpContentScreen(topic: topic));
      case applicationDetails:
        final id = settings.arguments as String;
        return _page(
          settings,
          (_) => ApplicationDetailsScreen(applicationId: id),
        );
      case fullDetails:
        final id = settings.arguments as String;
        return _page(settings, (_) => FullDetailsScreen(applicationId: id));
      case enrolment:
        // The wizard's ViewModel is built by [startEnrolment] and handed over
        // as the route argument; the route owns (and disposes) it.
        final flow = settings.arguments as EnrolmentFlowViewModel;
        return _page(
          settings,
          (_) => ChangeNotifierProvider<EnrolmentFlowViewModel>(
            create: (_) => flow,
            child: const EnrolmentFlowScreen(),
          ),
        );
      case submissionSuccess:
        final reference = settings.arguments as String;
        return _page(
          settings,
          (_) => SubmissionSuccessScreen(referenceNumber: reference),
        );
      default:
        return _page(settings, (_) => const _UnknownRouteScreen());
    }
  }

  /// _page() - private helper that wraps a widget builder in a MaterialPageRoute that keeps the route settings.
  static MaterialPageRoute<T> _page<T>(
    RouteSettings settings,
    WidgetBuilder builder,
  ) => MaterialPageRoute<T>(settings: settings, builder: builder);

  /// toRegister() - opens the Create Account screen.
  // ------------------------------------------------------ navigation helpers
  static Future<void> toRegister(BuildContext context) =>
      Navigator.of(context).pushNamed(register);

  /// toPersonalDetails() - opens the Personal Details screen.
  static Future<void> toPersonalDetails(BuildContext context) =>
      Navigator.of(context).pushNamed(personalDetails);

  /// toChangePassword() - opens the Change Password screen.
  static Future<void> toChangePassword(BuildContext context) =>
      Navigator.of(context).pushNamed(changePassword);

  /// toHelpSupport() - opens the Help & Support screen.
  static Future<void> toHelpSupport(BuildContext context) =>
      Navigator.of(context).pushNamed(helpSupport);

  /// toHelpContent() - opens the content page of one help topic.
  static Future<void> toHelpContent(BuildContext context, HelpTopic topic) =>
      Navigator.of(context).pushNamed(helpContent, arguments: topic);

  /// toApplicationDetails() - opens the Application Details screen for the given application id.
  static Future<void> toApplicationDetails(
    BuildContext context,
    String applicationId,
  ) => Navigator.of(
    context,
  ).pushNamed(applicationDetails, arguments: applicationId);

  /// toFullDetails() - opens the Full Details screen (all submitted answers) for the given application id.
  static Future<void> toFullDetails(
    BuildContext context,
    String applicationId,
  ) => Navigator.of(context).pushNamed(fullDetails, arguments: applicationId);

  /// toSubmissionSuccess() - replaces the wizard with the success screen, passing the reference number.
  /// Replaces the wizard with the success screen after a submission.
  static Future<void> toSubmissionSuccess(
    BuildContext context,
    String referenceNumber,
  ) => Navigator.of(
    context,
  ).pushReplacementNamed(submissionSuccess, arguments: referenceNumber);

  /// popToRoot() - closes every screen above the first one, returning to the login screen or the main shell.
  /// Closes everything above the auth gate (back to Login or the main shell).
  static void popToRoot(BuildContext context) =>
      Navigator.of(context).popUntil((r) => r.isFirst);

  /// newApplication() - called by the "New Application" buttons. If there is no saved draft it starts
  /// a fresh wizard. If there is one, it asks the parent with a dialog: Cancel (do nothing), Start new
  /// (discard the saved draft and start fresh) or Continue saved (restore the draft and open the wizard).
  /// Builds the wizard's ViewModel (restoring a saved draft if any) and opens
  /// the six-step enrolment wizard.
  /// "New Application" button. If a saved draft exists the parent chooses
  /// between continuing it and replacing it.
  static Future<void> newApplication(BuildContext context) async {
    final drafts = context.read<DraftViewModel>();
    if (!drafts.hasDraft) return startEnrolment(context);
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('You have a saved application'),
        content: const Text(
          'Continue the saved application, or start a new one? Starting a new one replaces the saved answers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'new'),
            child: const Text(
              'Start new',
              style: TextStyle(color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'continue'),
            child: const Text('Continue saved'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (choice == 'continue') {
      await startEnrolment(context, continueDraft: true);
    } else if (choice == 'new') {
      await drafts.discard();
      if (!context.mounted) return;
      await startEnrolment(context);
    }
  }

  /// startEnrolment() - builds the EnrolmentFlowViewModel (repository, draft storage, file picker,
  /// pre-filled guardian details from the profile, and a callback that reloads My Applications after a
  /// successful submission), restores the saved draft if continueDraft is true, opens the wizard, and
  /// when the parent comes back refreshes the draft shown on the dashboard. If the screen has gone away
  /// in the meantime the view model is disposed.
  /// Builds the wizard's ViewModel and opens the six-step enrolment wizard.
  /// With [continueDraft] the saved answers and step are restored.
  static Future<void> startEnrolment(
    BuildContext context, {
    bool continueDraft = false,
  }) async {
    final auth = context.read<AuthViewModel>();
    final drafts = context.read<DraftViewModel>();
    final uid = auth.userId;
    if (uid == null) return;
    final flow = EnrolmentFlowViewModel(
      userId: uid,
      repository: context.read<ApplicationRepository>(),
      storage: context.read<DraftStorage>(),
      filePicker: context.read<FilePickerService>(),
      // Refresh "My Applications" after a successful submission.
      onSubmitted: context.read<ApplicationsViewModel>().load,
      prefillName: auth.fullName,
      prefillEmail: auth.email,
      prefillPhone: auth.profile?.phoneNumber,
      prefillRelationship: auth.profile?.relationshipToLearner,
    );
    if (continueDraft) await flow.restoreDraft();
    if (!context.mounted) {
      flow.dispose();
      return;
    }
    await Navigator.of(context).pushNamed(enrolment, arguments: flow);
    // Back on the dashboard: show the saved draft (or hide it if submitted).
    await drafts.refresh();
  }

  /// showReuploadProof() - opens the "Upload New Proof of Payment" bottom sheet for an application.
  /// Resolves to true if a new proof was submitted.
  /// Bottom sheet to upload a new proof of payment. Resolves to true when a
  /// new proof was submitted.
  static Future<bool?> showReuploadProof(
    BuildContext context,
    EnrolmentApplication application,
  ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => ReuploadProofSheet(application: application),
    );
  }
}

/// _UnknownRouteScreen (class) - the fallback screen shown for any route name that is not recognised.
class _UnknownRouteScreen extends StatelessWidget {
  /// Constructor - no parameters.
  const _UnknownRouteScreen();

  /// build() - an empty app bar and a centred "Page not found" message.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: const Center(child: Text('Page not found')),
  );
}
