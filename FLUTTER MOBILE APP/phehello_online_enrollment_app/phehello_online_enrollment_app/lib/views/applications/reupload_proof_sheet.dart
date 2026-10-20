import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/school_info.dart';
import '../../data/repositories/application_repository.dart';
import '../../data/services/file_picker_service.dart';
import '../../models/enrolment_application.dart';
import '../../theme/app_colors.dart';
import '../../utils/validators.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/reupload_proof_view_model.dart';
import '../widgets/buttons.dart';
import '../widgets/form_fields.dart';
import '../widgets/upload_widgets.dart';

/// Bottom sheet to upload a new proof of payment after a rejection (FR4).
/// File picking, the upload and its error/busy state live in
/// [ReuploadProofViewModel]; the View keeps only the form fields.
class ReuploadProofSheet extends StatelessWidget {
  const ReuploadProofSheet({super.key, required this.application});

  final EnrolmentApplication application;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReuploadProofViewModel>(
      create: (ctx) => ReuploadProofViewModel(
        applicationId: application.id,
        repository: ctx.read<ApplicationRepository>(),
        filePicker: ctx.read<FilePickerService>(),
        auth: ctx.read<AuthViewModel>(),
      ),
      child: _ReuploadProofForm(application: application),
    );
  }
}

class _ReuploadProofForm extends StatefulWidget {
  const _ReuploadProofForm({required this.application});

  final EnrolmentApplication application;

  @override
  State<_ReuploadProofForm> createState() => _ReuploadProofFormState();
}

class _ReuploadProofFormState extends State<_ReuploadProofForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ref = TextEditingController(
    text: widget.application.latestPayment?.reference ?? '',
  );
  late final TextEditingController _amount = TextEditingController(
    text: SchoolInfo.enrolmentFee.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _ref.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit(ReuploadProofViewModel vm) async {
    final navigator = Navigator.of(context);
    final ok = await vm.submit(
      formValid: _formKey.currentState!.validate(),
      reference: _ref.text,
      amount: _amount.text,
    );
    if (ok) navigator.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReuploadProofViewModel>();
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Upload New Proof of Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your previous proof of payment was rejected. Please upload a clear copy.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Payment Reference *',
                hint: 'Enter payment reference',
                controller: _ref,
                validator: Validators.paymentReference,
              ),
              AppTextField(
                label: 'Amount Paid *',
                hint: 'R 200.00',
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: Validators.amount,
              ),
              if (vm.file == null)
                UploadDropZone(onChoose: vm.chooseFile, error: vm.fileError)
              else
                SelectedFileCard(file: vm.file!, onRemove: vm.removeFile),
              if (vm.fileError && vm.file == null)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Please choose your proof of payment.',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    vm.error!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Submit Proof of Payment',
                loading: vm.busy,
                onPressed: () => _submit(vm),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
