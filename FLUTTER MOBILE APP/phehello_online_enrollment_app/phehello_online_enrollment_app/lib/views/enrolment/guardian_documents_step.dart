//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: guardian_documents_step.dart defines Step 4 of the enrolment wizard: the parent / guardian's
// details and the upload of the supporting documents (FR3).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import '../widgets/upload_widgets.dart';
import 'step_scaffold.dart';

/// GuardianDocumentsStep (class) - Step 4, Parent / Guardian & Documents.
/// Step 4 - Parent / Guardian details and supporting documents (FR3).
class GuardianDocumentsStep extends StatefulWidget {
  /// Constructor - no required parameters.
  const GuardianDocumentsStep({super.key});

  /// createState() - creates the State object _GuardianDocumentsStepState.
  @override
  State<GuardianDocumentsStep> createState() => _GuardianDocumentsStepState();
}

/// _GuardianDocumentsStepState (class) - holds the form key and whether document errors should be shown.
class _GuardianDocumentsStepState extends State<GuardianDocumentsStep> {
  /// _formKey - lets the step validate the guardian fields at once.
  final _formKey = GlobalKey<FormState>();

  /// _showDocErrors - becomes true after the parent presses Next, so missing required documents are highlighted in red.
  bool _showDocErrors = false;

  /// _pick() - asks the view model to let the parent choose a file for one document type; if the file is invalid, the error is shown in a snack bar.
  Future<void> _pick(DocumentType type) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<EnrolmentFlowViewModel>().pickDocument(
      type,
    );
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  /// _next() - validates the form and checks that every required document was uploaded. Missing documents turn on the red highlighting and show a snack bar listing them.
  /// Only when both checks pass does it move to the next step.
  void _next() {
    final flow = context.read<EnrolmentFlowViewModel>();
    final formOk = _formKey.currentState!.validate();
    final missing = flow.missingRequiredDocuments;
    setState(() => _showDocErrors = missing.isNotEmpty);
    if (!formOk) return;
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please upload: ${missing.map((e) => e.label).join(', ')}.',
          ),
        ),
      );
      return;
    }
    flow.goNext();
  }

  /// build() - shows the guardian fields (full name*, relationship, contact number*, email*), the "Supporting documents" heading with the file rules (JPG, PNG or PDF, max 5 MB),
  /// one DocumentUploadTile for each document type (with Upload / Replace / remove actions) and the "Next : Payment Info" button.
  @override
  Widget build(BuildContext context) {
    final flow = context.watch<EnrolmentFlowViewModel>();
    final d = flow.draft;
    return Form(
      key: _formKey,
      child: StepScaffold(
        title: 'Parent / Guardian',
        subtitle: 'Enter guardian details and upload required documents.',
        children: [
          AppTextField(
            label: 'Full Name *',
            hint: 'Enter guardian name',
            initialValue: d.guardianName,
            textCapitalization: TextCapitalization.words,
            onChanged: (v) => d.guardianName = v,
            validator: (v) => Validators.name(v, "the guardian's full name"),
          ),
          AppDropdown(
            label: 'Relationship',
            hint: 'Select relationship',
            items: AppLists.relationships,
            value: d.relationship,
            onChanged: (v) => d.relationship = v ?? '',
          ),
          AppTextField(
            label: 'Contact Number *',
            hint: 'Enter phone number',
            initialValue: d.guardianPhone,
            keyboardType: TextInputType.phone,
            onChanged: (v) => d.guardianPhone = v,
            validator: Validators.phone,
          ),
          AppTextField(
            label: 'Email Address *',
            hint: 'Enter email address',
            initialValue: d.guardianEmail,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onChanged: (v) => d.guardianEmail = v,
            validator: Validators.email,
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text(
              'Supporting documents',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text(
              'JPG, PNG or PDF • Maximum 5 MB each',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          for (final t in DocumentType.values)
            DocumentUploadTile(
              label: t.label,
              hint: t.hint,
              file: flow.documents[t],
              showError: _showDocErrors && t.isRequired,
              onPick: () => _pick(t),
              onRemove: () => flow.removeDocument(t),
            ),
          const SizedBox(height: 6),
          PrimaryButton(label: 'Next : Payment Info', onPressed: _next),
        ],
      ),
    );
  }
}
