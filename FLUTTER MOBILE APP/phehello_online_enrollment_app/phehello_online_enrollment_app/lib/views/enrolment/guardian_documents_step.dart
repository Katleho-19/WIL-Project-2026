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

/// Step 4 - Parent / Guardian details and supporting documents (FR3).
class GuardianDocumentsStep extends StatefulWidget {
  const GuardianDocumentsStep({super.key});

  @override
  State<GuardianDocumentsStep> createState() => _GuardianDocumentsStepState();
}

class _GuardianDocumentsStepState extends State<GuardianDocumentsStep> {
  final _formKey = GlobalKey<FormState>();
  bool _showDocErrors = false;

  Future<void> _pick(DocumentType type) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<EnrolmentFlowViewModel>().pickDocument(type);
    if (error != null) messenger.showSnackBar(SnackBar(content: Text(error)));
  }

  void _next() {
    final flow = context.read<EnrolmentFlowViewModel>();
    final formOk = _formKey.currentState!.validate();
    final missing = flow.missingRequiredDocuments;
    setState(() => _showDocErrors = missing.isNotEmpty);
    if (!formOk) return;
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please upload: ${missing.map((e) => e.label).join(', ')}.'),
      ));
      return;
    }
    flow.goNext();
  }

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
            child: Text('Supporting documents',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('JPG, PNG or PDF • Maximum 5 MB each',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
