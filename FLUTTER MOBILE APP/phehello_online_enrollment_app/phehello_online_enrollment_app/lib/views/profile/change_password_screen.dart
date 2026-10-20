import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/change_password_view_model.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';

/// Profile > Change Password. Saving/error state live in
/// [ChangePasswordViewModel].
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChangePasswordViewModel>(
      create: (ctx) => ChangePasswordViewModel(ctx.read<AuthViewModel>()),
      child: const _ChangePasswordForm(),
    );
  }
}

class _ChangePasswordForm extends StatefulWidget {
  const _ChangePasswordForm();

  @override
  State<_ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<_ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await context
        .read<ChangePasswordViewModel>()
        .save(_current.text, _next.text);
    if (!ok) return; // the message is shown from ChangePasswordViewModel.error
    messenger.showSnackBar(const SnackBar(content: Text('Your password was changed.')));
    navigator.pop();
  }

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
                      validator: (v) => Validators.confirmPassword(v, _next.text),
                    ),
                    if (vm.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(vm.error!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                    PrimaryButton(label: 'Update Password', loading: vm.saving, onPressed: _save),
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
