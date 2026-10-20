import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/school_info.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../viewmodels/enrolment_flow_view_model.dart';
import '../widgets/app_card.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import 'step_scaffold.dart';

/// Step 5 - Payment Information (FR15). The system does not take payment:
/// it shows the fee and banking details and records the payment reference.
class PaymentInfoStep extends StatefulWidget {
  const PaymentInfoStep({super.key});

  @override
  State<PaymentInfoStep> createState() => _PaymentInfoStepState();
}

class _PaymentInfoStepState extends State<PaymentInfoStep> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _copy(String value, String what) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text('$what copied')));
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.read<EnrolmentFlowViewModel>();
    final d = flow.draft;
    return Form(
      key: _formKey,
      child: StepScaffold(
        title: 'Payment Information',
        subtitle:
            'Please use the school banking details below to make the enrolment payment before uploading your proof of payment.',
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enrolment Fee',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.beige,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount to Pay',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      Text(Formatters.money(SchoolInfo.enrolmentFee),
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Banking Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                const SizedBox(height: 4),
                _BankRow('Account Name', SchoolInfo.accountName),
                _BankRow('Bank', SchoolInfo.bank),
                _BankRow('Account Number', SchoolInfo.accountNumber,
                    onCopy: () => _copy(SchoolInfo.accountNumber, 'Account number')),
                _BankRow('Branch', SchoolInfo.branch),
                _BankRow('Branch Code', SchoolInfo.branchCode),
                _BankRow('Account Type', SchoolInfo.accountType, last: true),
                const SizedBox(height: 16),
                const Text('Payment Reference',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.brownDark)),
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Your payment reference *',
                  hint: "Learner's ID number or application reference",
                  initialValue: d.paymentReference,
                  textInputAction: TextInputAction.done,
                  onChanged: (v) => d.paymentReference = v,
                  validator: Validators.paymentReference,
                ),
                _InfoBox(
                  color: AppColors.beige,
                  title: "Use: Learner's ID number or application reference",
                  text: 'Please use a clear reference so the school can identify your payment.',
                ),
                const SizedBox(height: 10),
                _InfoBox(
                  color: AppColors.tile,
                  title: 'Important: Pay ${Formatters.money(SchoolInfo.enrolmentFee).replaceAll('.00', '').replaceAll(' ', '')} before continuing.',
                  text: 'Keep your payment receipt or proof of payment ready.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Continue to Proof of Payment →',
            onPressed: () {
              if (_formKey.currentState!.validate()) flow.goNext();
            },
          ),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow(this.label, this.value, {this.onCopy, this.last = false});

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(value,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                ),
                if (onCopy != null)
                  InkWell(
                    onTap: onCopy,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.copy_rounded, size: 16, color: AppColors.brown),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.color, required this.title, required this.text});

  final Color color;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
