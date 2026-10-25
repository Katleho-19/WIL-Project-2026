//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: login_screen.dart defines the Welcome / Login screen: school branding, the email and
// password form, a "Forgot Password?" dialog, error display and a button to open the register screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/school_info.dart';
import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/login_view_model.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import '../widgets/image_background.dart';
import '../widgets/school_crest.dart';

/// LoginScreen (class) - the public entry of the login screen. It creates a LoginViewModel (which holds the
/// busy and error state) and provides it to the form below it.
/// Welcome / Login screen. Busy and error state live in [LoginViewModel].
class LoginScreen extends StatelessWidget {
  /// Constructor - no required parameters.
  const LoginScreen({super.key});

  /// build() - wraps _LoginForm in a ChangeNotifierProvider that creates LoginViewModel using the shared AuthViewModel.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (ctx) => LoginViewModel(ctx.read<AuthViewModel>()),
      child: const _LoginForm(),
    );
  }
}

/// _LoginForm (class) - the stateful widget holding the actual form (private to this file).
class _LoginForm extends StatefulWidget {
  /// Constructor - no parameters.
  const _LoginForm();

  /// createState() - creates the State object _LoginFormState.
  @override
  State<_LoginForm> createState() => _LoginFormState();
}

/// _LoginFormState (class) - holds the form key and the email and password text controllers.
class _LoginFormState extends State<_LoginForm> {
  /// _formKey - lets the screen validate all the form fields at once.
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  /// dispose() - releases the two text controllers when the screen is removed.
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// _login() - runs when the Log In button (or the keyboard Done key) is pressed. It stops if validation fails,
  /// hides the keyboard and asks LoginViewModel to sign in. On success the auth gate in app.dart replaces this
  /// screen with the main app, so nothing else is needed here; on failure the view model shows the error.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // On success AuthGate swaps this screen for the main app.
    await context.read<LoginViewModel>().signIn(_email.text, _password.text);
  }

  /// _forgotPassword() - opens a "Reset password" dialog with an email field (pre-filled from the login form,
  /// validated with Validators.email). When the parent presses "Send link" it asks LoginViewModel to send the
  /// reset email and shows a snack bar with either the error or a message saying a reset link was sent
  /// (worded so it does not reveal whether the account exists).
  Future<void> _forgotPassword() async {
    final ctrl = TextEditingController(text: _email.text);
    final key = GlobalKey<FormState>();
    final vm = context.read<LoginViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter your email address and we'll send you a link to reset your password.",
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Email Address',
                hint: 'Enter email address',
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (key.currentState!.validate())
                Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (email == null) return;
    final err = await vm.sendPasswordReset(email);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          err ?? 'If an account exists for $email, a reset link has been sent.',
        ),
      ),
    );
  }

  /// build() - watches LoginViewModel for the busy and error state and draws: the photo background, the school
  /// crest, name, "ADMISSIONS & ENROLMENT PORTAL" and motto, the "Welcome Back" text, the email and password
  /// fields, the "Forgot Password?" link, a red error box (only if there is an error), the "Log In" button
  /// (shows a spinner while busy) and the white "Register Account" button (disabled while busy).
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();
    final busy = vm.busy;
    return Scaffold(
      body: ImageBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      const Center(child: SchoolCrest(height: 120)),
                      const SizedBox(height: 18),
                      const Text(
                        SchoolInfo.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ADMISSIONS & ENROLMENT PORTAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        SchoolInfo.motto,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Sign in to manage your learner's enrolment application.",
                        style: TextStyle(color: Colors.white, fontSize: 13.5),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Email Address',
                        labelColor: Colors.white,
                        hint: 'Enter email address',
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                      ),
                      AppTextField(
                        label: 'Password',
                        labelColor: Colors.white,
                        hint: 'Enter password',
                        controller: _password,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        validator: Validators.loginPassword,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _forgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.gold,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                      if (vm.error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.rejectedBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vm.error!,
                            style: const TextStyle(
                              color: AppColors.rejectedFg,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      PrimaryButton(
                        label: 'Log In',
                        loading: busy,
                        onPressed: _login,
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Register Account',
                        white: true,
                        onPressed: busy
                            ? null
                            : () => RouteManager.toRegister(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
