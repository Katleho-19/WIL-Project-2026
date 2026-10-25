//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: payment_info_step.dart defines Step 5 of the enrolment wizard (FR15): it shows the
// enrolment fee and the school's banking details and records the payment reference. The system does not take payment itself.

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

/// PaymentInfoStep (class) - Step 5, Payment Information.
/// Step 5 - Payment Information (FR15). The system does not take payment:
/// it shows the fee and banking details and records the payment reference.
class PaymentInfoStep extends StatefulWidget {
  /// Constructor - no required parameters.
  const PaymentInfoStep({super.key});

  /// createState() - creates the State object _PaymentInfoStepState.
  @override
  State<PaymentInfoStep> createState() => _PaymentInfoStepState();
}

/// _PaymentInfoStepState (class) - holds the form key and builds the step.
class _PaymentInfoStepState extends State<PaymentInfoStep> {
  /// _formKey - lets the step validate the payment reference.
  final _formKey = GlobalKey<FormState>();

  /// _copy() - copies a value (such as the account number) to the phone's clipboard and shows a "... copied" snack bar.
  Future<void> _copy(String value, String what) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text('$what copied')));
  }

  /// build() - shows a card with: the "Enrolment Fee" amount; the "Banking Details" rows (account name, bank, account number with a copy button, branch, branch code, account type);
  /// the "Payment Reference" field* (validated); and two information boxes (how to choose a reference, and a reminder to pay the fee first). Below the card is the
  /// "Continue to Proof of Payment" button, which moves on only if the reference is valid.
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
                const Text(
                  'Enrolment Fee',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brownDark,
                  ),
                ),
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
                      const Text(
                        'Amount to Pay',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.money(SchoolInfo.enrolmentFee),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Banking Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brownDark,
                  ),
                ),
                const SizedBox(height: 4),
                _BankRow('Account Name', SchoolInfo.accountName),
                _BankRow('Bank', SchoolInfo.bank),
                _BankRow(
                  'Account Number',
                  SchoolInfo.accountNumber,
                  onCopy: () =>
                      _copy(SchoolInfo.accountNumber, 'Account number'),
                ),
                _BankRow('Branch', SchoolInfo.branch),
                _BankRow('Branch Code', SchoolInfo.branchCode),
                _BankRow('Account Type', SchoolInfo.accountType, last: true),
                const SizedBox(height: 16),
                const Text(
                  'Payment Reference',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brownDark,
                  ),
                ),
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
                  text:
                      'Please use a clear reference so the school can identify your payment.',
                ),
                const SizedBox(height: 10),
                _InfoBox(
                  color: AppColors.tile,
                  title:
                      'Important: Pay ${Formatters.money(SchoolInfo.enrolmentFee).replaceAll('.00', '').replaceAll(' ', '')} before continuing.',
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

/// _BankRow (class) - one row of the banking details: a label on the left, the bold value on the right, an optional copy icon and a divider line (omitted for the last row).
class _BankRow extends StatelessWidget {
  /// Constructor - label and value are positional; onCopy (shows the copy icon) and last are optional.
  const _BankRow(this.label, this.value, {this.onCopy, this.last = false});

  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool last;

  /// build() - lays out the label and value in a bordered row and adds the copy icon when onCopy is provided.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (onCopy != null)
                  InkWell(
                    onTap: onCopy,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 16,
                        color: AppColors.brown,
                      ),
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

/// _InfoBox (class) - a coloured rounded box with a bold title and a smaller explanation text.
class _InfoBox extends StatelessWidget {
  /// Constructor - color, title and text are required.
  const _InfoBox({
    required this.color,
    required this.title,
    required this.text,
  });

  final Color color;
  final String title;
  final String text;

  /// build() - a full-width rounded container showing the title and the text.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
