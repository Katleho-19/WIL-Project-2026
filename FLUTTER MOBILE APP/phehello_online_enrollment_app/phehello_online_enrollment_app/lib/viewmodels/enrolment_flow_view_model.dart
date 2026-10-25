//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: enrolment_flow_view_model.dart holds all state and logic of the six-step enrolment
// wizard (FR2, FR3, FR4, FR15): the form answers, chosen documents and proof of payment, step
// navigation, saving/restoring a draft, validation of required documents and final submission.

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

/// SubmitState (enum) - the stages of submitting: idle (not started), submitting (in progress),
/// success or failure.
enum SubmitState { idle, submitting, success, failure }

/// State of the six-step enrolment wizard (FR2, FR3, FR4, FR15).
/// Steps: 0 Learner, 1 Academic, 2 Medical, 3 Guardian + documents,
/// 4 Payment information, 5 Proof of payment.
///
/// EnrolmentFlowViewModel (class) - the view model behind the enrolment wizard screens.
class EnrolmentFlowViewModel extends BaseViewModel {
  /// Constructor - receives the user id, repository, draft storage, file picker and an optional
  /// onSubmitted callback, plus optional guardian details to pre-fill. In the body it fills the
  /// guardian name, email, phone and relationship from those values and pre-fills the amount
  /// paid with the enrolment fee (e.g. "200.00").
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

  /// stepCount - the number of steps in the wizard (6).
  static const int stepCount = 6;

  /// stepNames - the short names shown in the progress indicator.
  static const List<String> stepNames = [
    'Learner',
    'Academic',
    'Medical',
    'Guardian',
    'Payment',
    'Proof',
  ];

  /// stepTitles - the full heading shown at the top of each step.
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

  /// draft - the text answers entered in the wizard.
  EnrolmentDraft draft = EnrolmentDraft();

  /// documents - the supporting documents chosen so far, keyed by document type.
  final Map<DocumentType, PickedDocument> documents = {};

  /// proof - the chosen proof of payment (null until chosen).
  PickedDocument? proof;

  /// _uploadedPaths - remembers files already uploaded in a failed attempt so a retry does not upload them again.
  final Map<String, String> _uploadedPaths = {};

  /// step - the current step number (0 to 5).
  int step = 0;

  /// restoredDraft - true if a saved draft was loaded when the wizard opened.
  bool restoredDraft = false;

  /// Submission progress: state, message and fraction for the progress bar, an error message
  /// if it failed, and the reference number once it succeeded.
  SubmitState submitState = SubmitState.idle;
  String progressMessage = '';
  double progress = 0;
  String? errorMessage;
  String referenceNumber = '';

  /// restoreDraft() - loads a draft saved on the device. If one exists and is not empty, the
  /// pre-filled guardian name, email, phone and amount are kept wherever the saved draft has them
  /// blank; the saved draft then replaces the current one, the step is restored (kept within
  /// 0-5) and 'restoredDraft' is set to true.
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

  /// saveDraft() - stores the current step in the draft and saves it on the device so the parent
  /// can continue later from the dashboard.
  /// Saves the text answers and the current step so the parent can continue
  /// later from the dashboard.
  Future<void> saveDraft() {
    draft.step = step;
    return _storage.save(userId, draft);
  }

  /// discardDraft() - deletes the saved draft from the device.
  Future<void> discardDraft() => _storage.clear(userId);

  // ------------------------------------------------------------ navigation

  /// goNext() - moves to the next step (if not on the last one), auto-saves the draft and notifies listeners.
  void goNext() {
    if (step < stepCount - 1) {
      step++;
      saveDraft();
      notifyListeners();
    }
  }

  /// goBack() - moves to the previous step (if not on the first one) and notifies listeners.
  void goBack() {
    if (step > 0) {
      step--;
      notifyListeners();
    }
  }

  /// refresh() - tells listening widgets to rebuild (used after form fields change).
  void refresh() => notifyListeners();

  /// hasUnsavedWork (getter) - true unless the draft, documents and proof are all empty;
  /// used to warn the parent before leaving the wizard.
  /// True when leaving the wizard would lose something the parent entered.
  bool get hasUnsavedWork =>
      !(draft.isEmpty && documents.isEmpty && proof == null);

  // ------------------------------------------------------------- documents

  /// pickDocument() - opens the file picker and stores the chosen file for the given document
  /// type. Returns a readable error message if the file is invalid, otherwise null
  /// (also null if the parent cancelled).
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

  /// pickProof() - same as pickDocument() but stores the file as the proof of payment.
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

  /// setDocument() - stores a chosen file for a document type and notifies listeners.
  void setDocument(DocumentType type, PickedDocument file) {
    documents[type] = file;
    notifyListeners();
  }

  /// removeDocument() - removes the file for a document type and forgets any earlier upload of it.
  void removeDocument(DocumentType type) {
    documents.remove(type);
    _uploadedPaths.remove('doc_${type.name}');
    notifyListeners();
  }

  /// setProof() - stores a chosen proof of payment and forgets any earlier upload of it.
  void setProof(PickedDocument file) {
    proof = file;
    _uploadedPaths.remove('proof');
    notifyListeners();
  }

  /// removeProof() - clears the proof of payment and forgets any earlier upload of it.
  void removeProof() {
    proof = null;
    _uploadedPaths.remove('proof');
    notifyListeners();
  }

  /// missingRequiredDocuments (getter) - the required document types that have not been chosen yet.
  List<DocumentType> get missingRequiredDocuments => DocumentType.values
      .where((t) => t.isRequired && !documents.containsKey(t))
      .toList();

  // ------------------------------------------------------------ submission

  /// submit() - submits the application. Steps: ignore the call if a submission is already running;
  /// fail with a message listing any missing required documents; fail if no proof of payment was
  /// chosen; otherwise set the state to submitting and call ApplicationRepository.submitApplication
  /// with a progress callback that updates the message and progress bar. On success it stores the
  /// reference number, deletes the saved draft, sets the state to success, calls onSubmitted and
  /// returns true. On any error it stores a readable message, sets the state to failure and
  /// returns false.
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

  /// resetSubmitState() - returns the submit state to idle and clears the error, so the parent can try again.
  void resetSubmitState() {
    submitState = SubmitState.idle;
    errorMessage = null;
    notifyListeners();
  }
}
