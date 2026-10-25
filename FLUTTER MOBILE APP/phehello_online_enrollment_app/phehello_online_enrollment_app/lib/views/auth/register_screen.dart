//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: register_screen.dart defines the Create Parent/Guardian Account screen (FR1): a form
// with full name, email, password and confirm password, error display, and handling of the sign-up result.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/school_info.dart';
import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/register_view_model.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';

/// RegisterScreen (class) - the public entry of the register screen. It creates a RegisterViewModel (which
/// holds the busy and error state) and provides it to the form below it.
/// Create Parent/Guardian Account (FR1). Busy and error state live in
/// [RegisterViewModel].
class RegisterScreen extends StatelessWidget {
  /// Constructor - no required parameters.
  const RegisterScreen({super.key});

  /// build() - wraps _RegisterForm in a ChangeNotifierProvider that creates RegisterViewModel using the shared AuthViewModel.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegisterViewModel>(
      create: (ctx) => RegisterViewModel(ctx.read<AuthViewModel>()),
      child: const _RegisterForm(),
    );
  }
}

/// _RegisterForm (class) - the stateful widget holding the actual form (private to this file).
class _RegisterForm extends StatefulWidget {
  /// Constructor - no parameters.
  const _RegisterForm();

  /// createState() - creates the State object _RegisterFormState.
  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

/// _RegisterFormState (class) - holds the form key and the four text controllers (name, email, password, confirm).
class _RegisterFormState extends State<_RegisterForm> {
  /// _formKey - lets the screen validate all the form fields at once.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// dispose() - releases the four text controllers when the screen is removed.
  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// _register() - runs when "Register Account" is pressed. It stops if validation fails, hides the keyboard and asks
  /// RegisterViewModel to register, then reacts to the outcome: signedIn -> closes this screen so the auth gate shows
  /// the app; needsEmailConfirmation -> shows a "Check your email" dialog and then goes back to the login screen;
  /// failed -> nothing more (the error is shown from the view model).
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final result = await context.read<RegisterViewModel>().register(
      _name.text,
      _email.text,
      _password.text,
    );
    if (!mounted) return;
    switch (result.outcome) {
      case SignUpOutcome.signedIn:
        // Close this screen; AuthGate now shows the app.
        RouteManager.popToRoot(context);
        break;
      case SignUpOutcome.needsEmailConfirmation:
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Check your email'),
            content: Text(
              'We sent a confirmation link to ${_email.text.trim()}. '
              'Please open it, then log in.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop();
        break;
      case SignUpOutcome.failed:
        // The message is shown from RegisterViewModel.error.
        break;
    }
  }

  /// build() - watches RegisterViewModel and draws the brown header (with a back button), the intro text, the four
  /// fields (names, email, password, confirm password with match check), a red error box when there is an error, the
  /// "Register Account" button (spinner while busy) and an "Already have an account? Log in" link that goes back.
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegisterViewModel>();
    final busy = vm.busy;
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Create Parent/Guardian Account',
            subtitle: SchoolInfo.name,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create your account to begin a school enrolment application.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Full Names',
                      hint: 'Enter full names',
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => Validators.name(v, 'your full names'),
                    ),
                    AppTextField(
                      label: 'Email Address',
                      hint: 'Enter email address',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    AppTextField(
                      label: 'Password',
                      hint: 'Create password (at least 8 characters)',
                      controller: _password,
                      isPassword: true,
                      validator: Validators.password,
                    ),
                    AppTextField(
                      label: 'Confirm Password',
                      hint: 'Confirm password',
                      controller: _confirm,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          Validators.confirmPassword(v, _password.text),
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
                    PrimaryButton(
                      label: 'Register Account',
                      loading: busy,
                      onPressed: _register,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
