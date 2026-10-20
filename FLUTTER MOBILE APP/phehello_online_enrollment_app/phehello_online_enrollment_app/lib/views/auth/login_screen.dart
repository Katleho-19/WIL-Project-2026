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

/// Welcome / Login screen. Busy and error state live in [LoginViewModel].
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (ctx) => LoginViewModel(ctx.read<AuthViewModel>()),
      child: const _LoginForm(),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    // On success AuthGate swaps this screen for the main app.
    await context.read<LoginViewModel>().signIn(_email.text, _password.text);
  }

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
              const Text("Enter your email address and we'll send you a link to reset your password."),
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(ctx, ctrl.text.trim());
            },
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (email == null) return;
    final err = await vm.sendPasswordReset(email);
    messenger.showSnackBar(SnackBar(
      content: Text(err ?? 'If an account exists for $email, a reset link has been sent.'),
    ));
  }

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
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
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
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ADMISSIONS & ENROLMENT PORTAL',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 1.3),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        SchoolInfo.motto,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 28),
                      const Text('Welcome Back',
                          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      const Text("Sign in to manage your learner's enrolment application.",
                          style: TextStyle(color: Colors.white, fontSize: 13.5)),
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
                              foregroundColor: AppColors.gold, padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                          child: const Text('Forgot Password?',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
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
                          child: Text(vm.error!,
                              style: const TextStyle(color: AppColors.rejectedFg, fontSize: 13)),
                        ),
                      const SizedBox(height: 6),
                      PrimaryButton(label: 'Log In', loading: busy, onPressed: _login),
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
