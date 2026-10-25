//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: confirmation_letter_dialog.dart defines the pop-up that shows the school's confirmation
// (or outcome) letter as a PDF preview, with a button to save it to the phone.

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../theme/app_colors.dart';
import '../../viewmodels/application_details_view_model.dart';
import '../widgets/buttons.dart';

/// ConfirmationLetterDialog (class) - the pop-up window. 'approved' decides whether it shows the congratulatory wording or the neutral outcome wording.
/// Pop-up that shows the confirmation letter PDF with a Download button.
class ConfirmationLetterDialog extends StatefulWidget {
  /// Constructor - approved is required.
  const ConfirmationLetterDialog({super.key, required this.approved});

  final bool approved;

  /// show() - helper that opens the dialog. A dialog is created outside the screen's provider tree, so the
  /// ApplicationDetailsViewModel is passed in and provided again with ChangeNotifierProvider.value.
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

  /// createState() - creates the State object _ConfirmationLetterDialogState.
  @override
  State<ConfirmationLetterDialog> createState() =>
      _ConfirmationLetterDialogState();
}

/// _ConfirmationLetterDialogState (class) - remembers whether the last save attempt worked.
class _ConfirmationLetterDialogState extends State<ConfirmationLetterDialog> {
  /// _saved - null until a save has been tried; then true (saved) or false (failed).
  bool? _saved; // null = not tried yet

  /// _download() - asks the view model to save the letter to the phone and stores the result (if the dialog is still open) so a message can be shown.
  Future<void> _download() async {
    final ok = await context.read<ApplicationDetailsViewModel>().saveLetter();
    if (mounted) setState(() => _saved = ok);
  }

  /// build() - reads the letter bytes from the view model and picks the title and message for approved or not approved. The dialog shows
  /// the title, the message, a PDF preview of the letter (about 45% of the screen height, with the default toolbar hidden), a green "saved" or red "could
  /// not save" message once a save was tried, the "Download Letter" button (spinner while saving) and a "Close" button.
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
