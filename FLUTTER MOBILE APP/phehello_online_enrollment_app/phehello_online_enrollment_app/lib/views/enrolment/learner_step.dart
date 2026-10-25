//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: learner_step.dart defines Step 1 of the enrolment wizard: the learner's personal
// information (names, date of birth, gender and ID / passport number).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import 'step_scaffold.dart';

/// LearnerStep (class) - Step 1, Learner Personal Information. It is stateful because it owns the form key used for validation.
/// Step 1 - Learner Personal Information.
class LearnerStep extends StatefulWidget {
  /// Constructor - no required parameters.
  const LearnerStep({super.key});

  /// createState() - creates the State object _LearnerStepState.
  @override
  State<LearnerStep> createState() => _LearnerStepState();
}

/// _LearnerStepState (class) - holds the form key and builds the step.
class _LearnerStepState extends State<LearnerStep> {
  /// _formKey - lets the step validate all its fields at once.
  final _formKey = GlobalKey<FormState>();

  /// _next() - validates the form; only if every field is valid does it tell EnrolmentFlowViewModel to move to the next step.
  void _next() {
    final flow = context.read<EnrolmentFlowViewModel>();
    if (!_formKey.currentState!.validate()) return;
    flow.goNext();
  }

  /// build() - takes the draft from EnrolmentFlowViewModel and shows the fields, each pre-filled from the draft and writing back to it on every change:
  /// first name*, middle name, surname*, initials/nickname, other names, date of birth*, gender*, and ID/passport number* (validated as a 13-digit SA ID or a passport number),
  /// then the "Next: Academic History" button. Fields marked * are required.
  @override
  Widget build(BuildContext context) {
    final d = context.read<EnrolmentFlowViewModel>().draft;
    return Form(
      key: _formKey,
      child: StepScaffold(
        title: 'Learner Personal Information',
        children: [
          AppTextField(
            label: 'First Name *',
            hint: 'Enter first name',
            initialValue: d.firstName,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => d.firstName = v,
            validator: (v) => Validators.name(v, "the learner's first name"),
          ),
          AppTextField(
            label: 'Middle Name',
            hint: 'Enter middle name',
            initialValue: d.middleName,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => d.middleName = v,
          ),
          AppTextField(
            label: 'Surname *',
            hint: 'Enter surname',
            initialValue: d.surname,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => d.surname = v,
            validator: (v) => Validators.name(v, "the learner's surname"),
          ),
          AppTextField(
            label: 'Initials / Nickname',
            hint: 'Enter initials or nickname',
            initialValue: d.initials,
            onChanged: (v) => d.initials = v,
          ),
          AppTextField(
            label: 'Other Names',
            hint: 'Enter other names',
            initialValue: d.otherNames,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => d.otherNames = v,
          ),
          AppDateField(
            label: 'Date of Birth *',
            value: d.dateOfBirth,
            onChanged: (v) => d.dateOfBirth = v,
            validator: (_) => d.dateOfBirth == null
                ? "Please choose the learner's date of birth."
                : null,
          ),
          AppDropdown(
            label: 'Gender *',
            hint: 'Select gender',
            items: AppLists.genders,
            value: d.gender,
            onChanged: (v) => d.gender = v ?? '',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please select a gender.' : null,
          ),
          AppTextField(
            label: 'ID / Passport Number *',
            hint: 'Enter ID or passport number',
            initialValue: d.idNumber,
            textInputAction: TextInputAction.done,
            onChanged: (v) => d.idNumber = v,
            validator: Validators.idOrPassport,
          ),
          const SizedBox(height: 6),
          PrimaryButton(label: 'Next: Academic History', onPressed: _next),
        ],
      ),
    );
  }
}
