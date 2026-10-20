import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/personal_details_view_model.dart';
import '../widgets/app_header.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';

/// Profile > Personal Details (edit name, phone, relationship, occupation).
/// Current values and the save call come from [PersonalDetailsViewModel].
class PersonalDetailsScreen extends StatelessWidget {
  const PersonalDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PersonalDetailsViewModel>(
      create: (ctx) => PersonalDetailsViewModel(ctx.read<AuthViewModel>()),
      child: const _PersonalDetailsForm(),
    );
  }
}

class _PersonalDetailsForm extends StatefulWidget {
  const _PersonalDetailsForm();

  @override
  State<_PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<_PersonalDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _occupation;
  String _relationship = '';

  @override
  void initState() {
    super.initState();
    final vm = context.read<PersonalDetailsViewModel>();
    _name = TextEditingController(text: vm.fullName);
    _phone = TextEditingController(text: vm.phone);
    _occupation = TextEditingController(text: vm.occupation);
    _relationship = vm.relationship;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _occupation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final err = await context.read<PersonalDetailsViewModel>().save(
          fullName: _name.text,
          phone: _phone.text,
          relationship: _relationship,
          occupation: _occupation.text,
        );
    messenger.showSnackBar(SnackBar(content: Text(err ?? 'Your details were saved.')));
    if (err == null) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PersonalDetailsViewModel>();
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            title: 'Personal Details',
            subtitle: 'Manage your account information',
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
                      label: 'Full Names',
                      hint: 'Enter full names',
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => Validators.name(v, 'your full names'),
                    ),
                    AppTextField(
                      label: 'Email Address',
                      controller: TextEditingController(text: vm.email),
                      enabled: false,
                    ),
                    AppTextField(
                      label: 'Contact Number',
                      hint: 'Enter phone number',
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? null : Validators.phone(v),
                    ),
                    AppDropdown(
                      label: 'Relationship to learner',
                      hint: 'Select relationship',
                      items: AppLists.relationships,
                      value: _relationship,
                      onChanged: (v) => _relationship = v ?? '',
                    ),
                    AppTextField(
                      label: 'Occupation',
                      hint: 'Enter occupation',
                      controller: _occupation,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 4),
                    PrimaryButton(label: 'Save Changes', loading: vm.saving, onPressed: _save),
                    const SizedBox(height: 10),
                    const Text(
                      'Your email address is your login and cannot be changed here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
