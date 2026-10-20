import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../routes/route_manager.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import '../widgets/upload_widgets.dart';
import 'step_scaffold.dart';

/// Step 6 - Proof of Payment, review and Submit Application (FR4, FR2).
class ProofOfPaymentStep extends StatefulWidget {
  const ProofOfPaymentStep({super.key});

  @override
  State<ProofOfPaymentStep> createState() => _ProofOfPaymentStepState();
}

class _ProofOfPaymentStepState extends State<ProofOfPaymentStep> {
  final _formKey = GlobalKey<FormState>();
  bool _fileError = false;

  Future<void> _choose() async {
    final flow = context.read<EnrolmentFlowViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final error = await flow.pickProof();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } else if (flow.proof != null && mounted) {
      setState(() => _fileError = false);
    }
  }

  Future<void> _submit() async {
    final flow = context.read<EnrolmentFlowViewModel>();
    final valid = _formKey.currentState!.validate();
    if (flow.proof == null) setState(() => _fileError = true);
    if (!valid || flow.proof == null) return;
    if (flow.missingRequiredDocuments.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please go back and upload: '
            '${flow.missingRequiredDocuments.map((e) => e.label).join(', ')}.'),
      ));
      return;
    }
    final confirmed = await _showReview(flow);
    if (confirmed != true || !mounted) return;

    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: ChangeNotifierProvider<EnrolmentFlowViewModel>.value(
          value: flow,
          child: const _ProgressDialog(),
        ),
      ),
    );
    final ok = await flow.submit();
    navigator.pop(); // close the progress dialog
    if (!mounted) return;
    if (ok) {
      RouteManager.toSubmissionSuccess(context, flow.referenceNumber);
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Submission failed'),
          content: Text(flow.errorMessage ?? 'Something went wrong. Please try again.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      flow.resetSubmitState();
    }
  }

  Future<bool?> _showReview(EnrolmentFlowViewModel flow) {
    final d = flow.draft;
    final docs = flow.documents.keys.map((e) => e.label).join(', ');
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Review your application',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Please check the details below before you submit.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 14),
              _ReviewLine('Learner', '${d.firstName} ${d.surname}'.trim()),
              _ReviewLine('Grade applied for', d.gradeApplied),
              _ReviewLine('Guardian', d.guardianName),
              _ReviewLine('Contact', d.guardianPhone),
              _ReviewLine('Documents', docs.isEmpty ? '-' : docs),
              _ReviewLine('Payment reference', d.paymentReference),
              _ReviewLine('Amount paid',
                  Formatters.money(Validators.parseAmount(d.amountPaid) ?? 0)),
              _ReviewLine('Proof of payment', flow.proof?.name ?? '-'),
              const SizedBox(height: 16),
              PrimaryButton(
                  label: 'Confirm & Submit', onPressed: () => Navigator.pop(ctx, true)),
              const SizedBox(height: 10),
              OutlineBrandButton(label: 'Go back', onPressed: () => Navigator.pop(ctx, false)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<EnrolmentFlowViewModel>();
    final d = flow.draft;
    final proof = flow.proof;
    return Form(
      key: _formKey,
      child: StepScaffold(
        title: 'Proof of Payment',
        subtitle:
            'Upload a clear copy of your payment receipt or proof of payment before submitting your application.',
        children: [
          AppTextField(
            label: 'Payment Reference *',
            hint: 'Enter payment reference',
            initialValue: d.paymentReference,
            onChanged: (v) => d.paymentReference = v,
            validator: Validators.paymentReference,
          ),
          AppTextField(
            label: 'Amount Paid *',
            hint: 'R 200.00',
            initialValue: d.amountPaid,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (v) => d.amountPaid = v,
            validator: Validators.amount,
          ),
          if (proof == null) ...[
            UploadDropZone(onChoose: _choose, error: _fileError),
            if (_fileError)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('Please choose your proof of payment.',
                    style: TextStyle(color: AppColors.error, fontSize: 12.5)),
              ),
          ] else ...[
            SelectedFileCard(file: proof, onRemove: flow.removeProof),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlineBrandButton(
                      label: 'Replace', icon: Icons.refresh_rounded, onPressed: _choose),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlineBrandButton(
                      label: 'Remove',
                      icon: Icons.delete_outline_rounded,
                      onPressed: flow.removeProof),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: 'Submit Application', onPressed: _submit),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.tile,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: 'Before submitting: ',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                TextSpan(
                    text:
                        'Check your proof of payment is clear and shows the payment reference and date.'),
              ]),
              style: TextStyle(fontSize: 12.5, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                flex: 4,
                child: Text(label,
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
            Expanded(
                flex: 6,
                child: Text(value.isEmpty ? '-' : value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
          ],
        ),
      );
}

class _ProgressDialog extends StatelessWidget {
  const _ProgressDialog();

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<EnrolmentFlowViewModel>();
    return AlertDialog(
      title: const Text('Submitting application'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: flow.progress == 0 ? null : flow.progress, minHeight: 6),
          const SizedBox(height: 14),
          Text(flow.progressMessage, style: const TextStyle(fontSize: 13.5)),
          const SizedBox(height: 6),
          const Text('Please keep the app open.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
