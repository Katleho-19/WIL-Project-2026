import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import 'step_scaffold.dart';

/// Step 1 - Learner Personal Information.
class LearnerStep extends StatefulWidget {
  const LearnerStep({super.key});

  @override
  State<LearnerStep> createState() => _LearnerStepState();
}

class _LearnerStepState extends State<LearnerStep> {
  final _formKey = GlobalKey<FormState>();

  void _next() {
    final flow = context.read<EnrolmentFlowViewModel>();
    if (!_formKey.currentState!.validate()) return;
    flow.goNext();
  }

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
            validator: (v) => (v == null || v.isEmpty) ? 'Please select a gender.' : null,
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
