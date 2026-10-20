//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import '../config/school_info.dart';
import '../data/repositories/application_repository.dart';
import '../data/services/draft_storage.dart';
import '../data/services/file_picker_service.dart';
import '../models/enrolment_draft.dart';
import '../models/enums.dart';
import '../models/picked_document.dart';
import '../utils/app_error.dart';
import '../utils/uuid.dart';
import 'base_view_model.dart';

enum SubmitState { idle, submitting, success, failure }

/// State of the six-step enrolment wizard (FR2, FR3, FR4, FR15).
/// Steps: 0 Learner, 1 Academic, 2 Medical, 3 Guardian + documents,
/// 4 Payment information, 5 Proof of payment.
class EnrolmentFlowViewModel extends BaseViewModel {
  EnrolmentFlowViewModel({
    required this.userId,
    required ApplicationRepository repository,
    required DraftStorage storage,
    required FilePickerService filePicker,
    this.onSubmitted,
    String? prefillName,
    String? prefillEmail,
    String? prefillPhone,
    String? prefillRelationship,
  }) : _repo = repository,
       _storage = storage,
       _filePicker = filePicker {
    draft.guardianName = prefillName ?? '';
    draft.guardianEmail = prefillEmail ?? '';
    draft.guardianPhone = prefillPhone ?? '';
    draft.relationship = prefillRelationship ?? '';
    draft.amountPaid = SchoolInfo.enrolmentFee.toStringAsFixed(2);
  }

  static const int stepCount = 6;
  static const List<String> stepNames = [
    'Learner',
    'Academic',
    'Medical',
    'Guardian',
    'Payment',
    'Proof',
  ];
  static const List<String> stepTitles = [
    'Learner Personal Information',
    'Academic & School History',
    'Medical & Family',
    'Parent/Guardian & Documents',
    'Payment Information',
    'Proof of Payment',
  ];

  final String userId;
  final ApplicationRepository _repo;
  final DraftStorage _storage;
  final FilePickerService _filePicker;

  /// Called after a successful submission (used to refresh the applications
  /// list without the View having to know about other ViewModels).
  final void Function()? onSubmitted;

  /// Generated up-front so uploaded files can be stored under the
  /// application's folder before the database record is created.
  final String applicationId = generateUuidV4();

  EnrolmentDraft draft = EnrolmentDraft();
  final Map<DocumentType, PickedDocument> documents = {};
  PickedDocument? proof;
  final Map<String, String> _uploadedPaths = {};

  int step = 0;
  bool restoredDraft = false;

  SubmitState submitState = SubmitState.idle;
  String progressMessage = '';
  double progress = 0;
  String? errorMessage;
  String referenceNumber = '';

  /// Restores a locally saved draft (text answers only).
  Future<void> restoreDraft() async {
    final saved = await _storage.load(userId);
    if (saved != null && !saved.isEmpty) {
      // Keep freshly prefilled guardian values if the draft has none.
      saved.guardianName = saved.guardianName.isEmpty
          ? draft.guardianName
          : saved.guardianName;
      saved.guardianEmail = saved.guardianEmail.isEmpty
          ? draft.guardianEmail
          : saved.guardianEmail;
      saved.guardianPhone = saved.guardianPhone.isEmpty
          ? draft.guardianPhone
          : saved.guardianPhone;
      if (saved.amountPaid.isEmpty) saved.amountPaid = draft.amountPaid;
      draft = saved;
      step = saved.step.clamp(0, stepCount - 1).toInt();
      restoredDraft = true;
      notifyListeners();
    }
  }

  /// Saves the text answers and the current step so the parent can continue
  /// later from the dashboard.
  Future<void> saveDraft() {
    draft.step = step;
    return _storage.save(userId, draft);
  }

  Future<void> discardDraft() => _storage.clear(userId);

  // ------------------------------------------------------------ navigation

  void goNext() {
    if (step < stepCount - 1) {
      step++;
      saveDraft();
      notifyListeners();
    }
  }

  void goBack() {
    if (step > 0) {
      step--;
      notifyListeners();
    }
  }

  void refresh() => notifyListeners();

  /// True when leaving the wizard would lose something the parent entered.
  bool get hasUnsavedWork =>
      !(draft.isEmpty && documents.isEmpty && proof == null);

  // ------------------------------------------------------------- documents

  /// Lets the parent choose a supporting document. Returns an error message
  /// to show, or null on success / cancel.
  Future<String?> pickDocument(DocumentType type) async {
    try {
      final file = await _filePicker.pickDocument();
      if (file != null) setDocument(type, file);
      return null;
    } catch (e) {
      return AppError.message(e);
    }
  }

  /// Lets the parent choose the proof of payment. Returns an error message
  /// to show, or null on success / cancel.
  Future<String?> pickProof() async {
    try {
      final file = await _filePicker.pickDocument();
      if (file != null) setProof(file);
      return null;
    } catch (e) {
      return AppError.message(e);
    }
  }

  void setDocument(DocumentType type, PickedDocument file) {
    documents[type] = file;
    notifyListeners();
  }

  void removeDocument(DocumentType type) {
    documents.remove(type);
    _uploadedPaths.remove('doc_${type.name}');
    notifyListeners();
  }

  void setProof(PickedDocument file) {
    proof = file;
    _uploadedPaths.remove('proof');
    notifyListeners();
  }

  void removeProof() {
    proof = null;
    _uploadedPaths.remove('proof');
    notifyListeners();
  }

  List<DocumentType> get missingRequiredDocuments => DocumentType.values
      .where((t) => t.isRequired && !documents.containsKey(t))
      .toList();

  // ------------------------------------------------------------ submission

  Future<bool> submit() async {
    if (submitState == SubmitState.submitting) return false;
    if (missingRequiredDocuments.isNotEmpty) {
      errorMessage =
          'Please upload: '
          '${missingRequiredDocuments.map((e) => e.label).join(', ')}.';
      submitState = SubmitState.failure;
      notifyListeners();
      return false;
    }
    final p = proof;
    if (p == null) {
      errorMessage = 'Please choose your proof of payment first.';
      submitState = SubmitState.failure;
      notifyListeners();
      return false;
    }
    submitState = SubmitState.submitting;
    errorMessage = null;
    progress = 0;
    progressMessage = 'Preparing your application...';
    notifyListeners();
    try {
      final result = await _repo.submitApplication(
        userId: userId,
        applicationId: applicationId,
        draft: draft,
        documents: Map<DocumentType, PickedDocument>.from(documents),
        proof: p,
        alreadyUploaded: _uploadedPaths,
        onProgress: (msg, fraction) {
          progressMessage = msg;
          progress = fraction;
          notifyListeners();
        },
      );
      referenceNumber = result.referenceNumber;
      await _storage.clear(userId);
      submitState = SubmitState.success;
      notifyListeners();
      onSubmitted?.call();
      return true;
    } catch (e) {
      errorMessage = AppError.message(e);
      submitState = SubmitState.failure;
      notifyListeners();
      return false;
    }
  }

  void resetSubmitState() {
    submitState = SubmitState.idle;
    errorMessage = null;
    notifyListeners();
  }
}
