import '../data/repositories/application_repository.dart';
import '../data/services/file_picker_service.dart';
import '../models/picked_document.dart';
import '../utils/app_error.dart';
import '../utils/validators.dart';
import 'auth_view_model.dart';
import 'base_view_model.dart';

/// ViewModel for the "Upload New Proof of Payment" sheet (FR4).
class ReuploadProofViewModel extends BaseViewModel {
  ReuploadProofViewModel({
    required this.applicationId,
    required ApplicationRepository repository,
    required FilePickerService filePicker,
    required AuthViewModel auth,
  })  : _repo = repository,
        _filePicker = filePicker,
        _auth = auth;

  final String applicationId;
  final ApplicationRepository _repo;
  final FilePickerService _filePicker;
  final AuthViewModel _auth;

  PickedDocument? file;
  bool fileError = false;
  bool busy = false;
  String? error;

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

  void removeFile() {
    file = null;
    notifyListeners();
  }

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
