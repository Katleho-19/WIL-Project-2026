//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: reupload_proof_view_model.dart holds the state and actions of the "Upload New
// Proof of Payment" sheet shown after the Financial Clerk rejects a proof (FR4): the chosen file,
// validation flags, progress and error message.

import '../data/repositories/application_repository.dart';
import '../data/services/file_picker_service.dart';
import '../models/picked_document.dart';
import '../utils/app_error.dart';
import '../utils/validators.dart';
import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for the "Upload New Proof of Payment" sheet (FR4).
///
/// ReuploadProofViewModel (class) - logic for re-submitting a proof of payment for one application.
class ReuploadProofViewModel extends BaseViewModel {
  /// Constructor - receives the application id plus the repository, file picker and auth view
  /// model it needs; the three services are stored in private fields.
  ReuploadProofViewModel({
    required this.applicationId,
    required ApplicationRepository repository,
    required FilePickerService filePicker,
    required AuthViewModel auth,
  }) : _repo = repository,
       _filePicker = filePicker,
       _auth = auth;

  final String applicationId;
  final ApplicationRepository _repo;
  final FilePickerService _filePicker;
  final AuthViewModel _auth;

  /// file - the proof file the parent has chosen (null if none yet).
  PickedDocument? file;

  /// fileError - true when the parent tried to submit without choosing a file (shows a message).
  bool fileError = false;

  /// busy - true while the upload is running.
  bool busy = false;

  /// error - a readable error message; null when there is none.
  String? error;

  /// chooseFile() - opens the file picker. If a valid file is chosen it is stored and the file
  /// error is cleared. If the parent cancels nothing changes; if the file is invalid (wrong type
  /// or too large) the readable message is stored in 'error'.
  Future<void> chooseFile() async {
    try {
      final f = await _filePicker.pickDocument();
      if (f != null) {
        file = f;
        fileError = false;
        error = null;
        notifyListeners();
      }
    } catch (e) {
      error = AppError.message(e);
      notifyListeners();
    }
  }

  /// removeFile() - clears the chosen file so the parent can pick a different one.
  void removeFile() {
    file = null;
    notifyListeners();
  }

  /// submit() - uploads the new proof of payment. Steps: flag a file error if no file was chosen;
  /// stop if the form is invalid, no file was chosen, or nobody is signed in; otherwise show the
  /// busy state, call ApplicationRepository.resubmitPaymentProof (amount parsed from the typed
  /// text) and return true. On failure the readable message is stored in 'error' and false is
  /// returned. The busy state is always switched off at the end.
  /// [formValid] is the result of the form's field validators (a View
  /// concern); the file rule and the upload are handled here.
  /// Returns true when the new proof was submitted.
  Future<bool> submit({
    required bool formValid,
    required String reference,
    required String amount,
  }) async {
    final chosen = file;
    if (chosen == null) {
      fileError = true;
      notifyListeners();
    }
    if (!formValid || chosen == null) return false;
    final uid = _auth.userId;
    if (uid == null) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await _repo.resubmitPaymentProof(
        userId: uid,
        applicationId: applicationId,
        reference: reference,
        amount: Validators.parseAmount(amount) ?? 0,
        file: chosen,
      );
      return true;
    } catch (e) {
      error = AppError.message(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
