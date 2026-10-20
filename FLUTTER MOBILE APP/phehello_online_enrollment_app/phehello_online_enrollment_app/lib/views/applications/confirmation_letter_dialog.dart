import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../viewmodels/application_details_view_model.dart';
import '../widgets/buttons.dart';

/// Pop-up that shows the confirmation letter PDF with a Download button.
class ConfirmationLetterDialog extends StatefulWidget {
  const ConfirmationLetterDialog({super.key, required this.approved});

  final bool approved;

  /// The dialog sits outside the screen's provider, so the view model
  /// is passed in explicitly.
  static Future<void> show(
    BuildContext context, {
    required ApplicationDetailsViewModel vm,
    required bool approved,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider<ApplicationDetailsViewModel>.value(
        value: vm,
        child: ConfirmationLetterDialog(approved: approved),
      ),
    );
  }

  @override
  State<ConfirmationLetterDialog> createState() =>
      _ConfirmationLetterDialogState();
}

class _ConfirmationLetterDialogState extends State<ConfirmationLetterDialog> {
  bool? _saved; // null = not tried yet

  Future<void> _download() async {
    final ok = await context.read<ApplicationDetailsViewModel>().saveLetter();
    if (mounted) setState(() => _saved = ok);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ApplicationDetailsViewModel>();
    final bytes = vm.letterBytes;
    final title = widget.approved
        ? 'Your Confirmation Letter'
        : 'Application Outcome Letter';
    final message = widget.approved
        ? 'Congratulations! The school has issued your confirmation letter.'
        : 'The school has issued a letter about your application.';

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),

            // The PDF itself, shown inside the pop-up.
            if (bytes != null)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.45,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PdfPreview(
                    build: (_) async => bytes,
                    useActions: false, // hide the default toolbar
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                  ),
                ),
              ),

            if (_saved != null) ...[
              const SizedBox(height: 10),
              Text(
                _saved!
                    ? 'Letter saved to your device.'
                    : 'Could not save the letter. Please try again.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _saved! ? AppColors.approvedFg : AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Download Letter',
              icon: Icons.download_rounded,
              loading: vm.downloadingLetter,
              onPressed: _download,
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: AppColors.brown,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
