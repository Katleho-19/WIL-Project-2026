//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: medical_step.dart defines Step 3 of the enrolment wizard: medical aid, doctor and
// siblings-at-school details. Every field is optional, as on the school's paper form.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/enrolment_flow_view_model.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import 'step_scaffold.dart';

/// MedicalStep (class) - Step 3, Medical & Family. It needs no form validation, so it is a stateless widget.
/// Step 3 - Medical & Family (all fields optional, as on the paper form).
class MedicalStep extends StatelessWidget {
  /// Constructor - no required parameters.
  const MedicalStep({super.key});

  /// build() - shows six optional text fields (medical aid name and number, main member, doctor name and address, siblings at school), each pre-filled
  /// from the draft and saving back to it when changed, and a "Next: Guardian & Documents" button that simply goes to the next step.
  @override
  Widget build(BuildContext context) {
    final flow = context.read<EnrolmentFlowViewModel>();
    final d = flow.draft;
    return StepScaffold(
      title: 'Medical & Family',
      children: [
        AppTextField(
          label: 'Medical Aid Name',
          hint: 'Enter medical aid name',
          initialValue: d.medicalAidName,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => d.medicalAidName = v,
        ),
        AppTextField(
          label: 'Medical Aid Number',
          hint: 'Enter medical aid number',
          initialValue: d.medicalAidNumber,
          onChanged: (v) => d.medicalAidNumber = v,
        ),
        AppTextField(
          label: 'Main Member',
          hint: 'Enter main member',
          initialValue: d.mainMember,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => d.mainMember = v,
        ),
        AppTextField(
          label: 'Doctor Name',
          hint: "Enter doctor's name",
          initialValue: d.doctorName,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => d.doctorName = v,
        ),
        AppTextField(
          label: 'Doctor Address',
          hint: "Enter doctor's address",
          initialValue: d.doctorAddress,
          onChanged: (v) => d.doctorAddress = v,
        ),
        AppTextField(
          label: 'Siblings at School',
          hint: 'Enter details',
          initialValue: d.siblingsAtSchool,
          textInputAction: TextInputAction.done,
          onChanged: (v) => d.siblingsAtSchool = v,
        ),
        const SizedBox(height: 6),
        PrimaryButton(
          label: 'Next: Guardian & Documents',
          onPressed: flow.goNext,
        ),
      ],
    );
  }
}
