//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: personal_details_screen.dart defines the Profile > Personal Details screen, where the
// parent edits their name, contact number, relationship to the learner and occupation (the email cannot be changed here).

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

/// PersonalDetailsScreen (class) - the public entry of the screen. The current values and the save call come from PersonalDetailsViewModel.
/// Profile > Personal Details (edit name, phone, relationship, occupation).
/// Current values and the save call come from [PersonalDetailsViewModel].
class PersonalDetailsScreen extends StatelessWidget {
  /// Constructor - no required parameters.
  const PersonalDetailsScreen({super.key});

  /// build() - provides a new PersonalDetailsViewModel (built from the shared AuthViewModel) and shows _PersonalDetailsForm.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PersonalDetailsViewModel>(
      create: (ctx) => PersonalDetailsViewModel(ctx.read<AuthViewModel>()),
      child: const _PersonalDetailsForm(),
    );
  }
}

/// _PersonalDetailsForm (class) - the stateful form (private to this file).
class _PersonalDetailsForm extends StatefulWidget {
  /// Constructor - no parameters.
  const _PersonalDetailsForm();

  /// createState() - creates the State object _PersonalDetailsFormState.
  @override
  State<_PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

/// _PersonalDetailsFormState (class) - holds the form key, the text controllers and the selected relationship.
class _PersonalDetailsFormState extends State<_PersonalDetailsForm> {
  /// _formKey - lets the screen validate the fields at once.
  final _formKey = GlobalKey<FormState>();

  /// _name - controller for the full name field.
  late final TextEditingController _name;

  /// _phone - controller for the contact number field.
  late final TextEditingController _phone;

  /// _occupation - controller for the occupation field.
  late final TextEditingController _occupation;

  /// _relationship - the selected relationship to the learner ('' if none).
  String _relationship = '';

  /// initState() - fills the controllers and the relationship with the parent's current saved values from the view model.
  @override
  void initState() {
    super.initState();
    final vm = context.read<PersonalDetailsViewModel>();
    _name = TextEditingController(text: vm.fullName);
    _phone = TextEditingController(text: vm.phone);
    _occupation = TextEditingController(text: vm.occupation);
    _relationship = vm.relationship;
  }

  /// dispose() - releases the three text controllers when the screen closes.
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _occupation.dispose();
    super.dispose();
  }

  /// _save() - validates the form, hides the keyboard and asks the view model to save the new details. It shows either the error or "Your details were saved." in a snack bar
  /// and closes the screen when the save succeeded.
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
    messenger.showSnackBar(
      SnackBar(content: Text(err ?? 'Your details were saved.')),
    );
    if (err == null) navigator.pop();
  }

  /// build() - draws the "Personal Details" header (with back button) and a scrollable form: full names (validated), email (shown but disabled), contact number (optional, validated
  /// only if filled in), relationship dropdown, occupation, the "Save Changes" button (spinner while saving) and a note that the email is the login and cannot be changed here.
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : Validators.phone(v),
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
                    PrimaryButton(
                      label: 'Save Changes',
                      loading: vm.saving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your email address is your login and cannot be changed here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
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
