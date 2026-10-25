//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: change_password_screen.dart defines the Profile > Change Password screen, where the parent
// enters the current password and a new password (twice).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/change_password_view_model.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';

/// ChangePasswordScreen (class) - the public entry of the screen. The saving and error state live in ChangePasswordViewModel.
/// Profile > Change Password. Saving/error state live in
/// [ChangePasswordViewModel].
class ChangePasswordScreen extends StatelessWidget {
  /// Constructor - no required parameters.
  const ChangePasswordScreen({super.key});

  /// build() - provides a new ChangePasswordViewModel (built from the shared AuthViewModel) and shows _ChangePasswordForm.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChangePasswordViewModel>(
      create: (ctx) => ChangePasswordViewModel(ctx.read<AuthViewModel>()),
      child: const _ChangePasswordForm(),
    );
  }
}

/// _ChangePasswordForm (class) - the stateful form (private to this file).
class _ChangePasswordForm extends StatefulWidget {
  /// Constructor - no parameters.
  const _ChangePasswordForm();

  /// createState() - creates the State object _ChangePasswordFormState.
  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

/// _ChangePasswordFormState (class) - holds the form key and the three password controllers.
class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  /// _formKey - lets the screen validate the fields at once.
  final _formKey = GlobalKey<FormState>();

  /// _current - controller for the current password.
  final _current = TextEditingController();

  /// _next - controller for the new password.
  final _next = TextEditingController();

  /// _confirm - controller for the new password confirmation.
  final _confirm = TextEditingController();

  /// dispose() - releases the three controllers when the screen closes.
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  /// _save() - validates the form, hides the keyboard and asks the view model to change the password. If it fails, the view model's error message is shown on the screen;
  /// if it succeeds it shows "Your password was changed." and closes the screen.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await context.read<ChangePasswordViewModel>().save(
      _current.text,
      _next.text,
    );
    if (!ok) return; // the message is shown from ChangePasswordViewModel.error
    messenger.showSnackBar(
      const SnackBar(content: Text('Your password was changed.')),
    );
    navigator.pop();
  }

  /// build() - draws the "Change Password" header (with back button) and a scrollable form with the current password, the new password (at least 8 characters), the confirmation
  /// (must match), a red error message if there is one and the "Update Password" button (spinner while saving). All three fields hide their text with a show/hide eye.
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChangePasswordViewModel>();
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Change Password',
            subtitle: 'Keep your account secure',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Current Password',
                      hint: 'Enter current password',
                      controller: _current,
                      isPassword: true,
                      validator: Validators.loginPassword,
                    ),
                    AppTextField(
                      label: 'New Password',
                      hint: 'At least 8 characters',
                      controller: _next,
                      isPassword: true,
                      validator: Validators.password,
                    ),
                    AppTextField(
                      label: 'Confirm New Password',
                      hint: 'Confirm new password',
                      controller: _confirm,
                      isPassword: true,
                      textInputAction: TextInputAction.done,
                      validator: (v) =>
                          Validators.confirmPassword(v, _next.text),
                    ),
                    if (vm.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          vm.error!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    PrimaryButton(
                      label: 'Update Password',
                      loading: vm.saving,
                      onPressed: _save,
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
