//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: academic_step.dart defines Step 2 of the enrolment wizard: the grade applied for and the
// learner's previous school history.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import 'step_scaffold.dart';

/// AcademicStep (class) - Step 2, Academic & School History.
/// Step 2 - Academic & School History.
class AcademicStep extends StatefulWidget {
  /// Constructor - no required parameters.
  const AcademicStep({super.key});

  /// createState() - creates the State object _AcademicStepState.
  @override
  State<AcademicStep> createState() => _AcademicStepState();
}

/// _AcademicStepState (class) - holds the form key and builds the step.
class _AcademicStepState extends State<AcademicStep> {
  /// _formKey - lets the step validate its fields at once.
  final _formKey = GlobalKey<FormState>();

  /// build() - shows the draft-backed fields: grade applied for* (dropdown), highest grade passed (dropdown), year passed (digits only, max 4, validated as a
  /// year), previous school and school history / notes (3 lines). The "Next: Medical & Family" button moves on only when the form is valid.
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
            validator: (v) => (v == null || v.isEmpty)
                ? 'Please select the grade you are applying for.'
                : null,
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
