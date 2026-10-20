import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import 'step_scaffold.dart';

/// Step 2 - Academic & School History.
class AcademicStep extends StatefulWidget {
  const AcademicStep({super.key});

  @override
  State<AcademicStep> createState() => _AcademicStepState();
}

class _AcademicStepState extends State<AcademicStep> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final flow = context.read<EnrolmentFlowViewModel>();
    final d = flow.draft;
    return Form(
      key: _formKey,
      child: StepScaffold(
        title: 'Academic & School History',
        children: [
          AppDropdown(
            label: 'Grade Applied For *',
            hint: 'Select grade',
            items: AppLists.applyGrades,
            value: d.gradeApplied,
            onChanged: (v) => d.gradeApplied = v ?? '',
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Please select the grade you are applying for.' : null,
          ),
          AppDropdown(
            label: 'Highest Grade Passed',
            hint: 'Select grade',
            items: AppLists.passedGrades,
            value: d.highestGradePassed,
            onChanged: (v) => d.highestGradePassed = v ?? '',
          ),
          AppTextField(
            label: 'Year Passed',
            hint: 'YYYY',
            initialValue: d.yearPassed,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            onChanged: (v) => d.yearPassed = v,
            validator: Validators.yearPassed,
          ),
          AppTextField(
            label: 'Previous School',
            hint: 'Enter previous school',
            initialValue: d.previousSchool,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => d.previousSchool = v,
          ),
          AppTextField(
            label: 'School History / Notes',
            hint: 'Enter relevant information',
            initialValue: d.schoolHistoryNotes,
            maxLines: 3,
            textInputAction: TextInputAction.newline,
            onChanged: (v) => d.schoolHistoryNotes = v,
          ),
          const SizedBox(height: 6),
          PrimaryButton(
            label: 'Next: Medical & Family',
            onPressed: () {
              if (_formKey.currentState!.validate()) flow.goNext();
            },
          ),
        ],
      ),
    );
  }
}
