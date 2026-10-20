//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import '../data/repositories/application_repository.dart';
import '../data/services/file_picker_service.dart';
import '../models/enrolment_application.dart';
import '../models/enums.dart';
import '../models/picked_document.dart';
import '../utils/app_error.dart';
import 'applications_view_model.dart';
import 'auth_view_model.dart';
import 'base_view_model.dart';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';

/// ViewModel for the Application Details screen (FR5).
///
/// Re-fetches the application when opened and runs the parent's corrective
/// actions (replace a document, resubmit for review). The application itself
/// lives in [ApplicationsViewModel]; this class only tracks screen state.
class ApplicationDetailsViewModel extends BaseViewModel {
  ApplicationDetailsViewModel({
    required this.applicationId,
    required ApplicationRepository repository,
    required FilePickerService filePicker,
    required ApplicationsViewModel applications,
    required AuthViewModel auth,
  }) : _repo = repository,
       _filePicker = filePicker,
       _applications = applications,
       _auth = auth;

  final String applicationId;
  final ApplicationRepository _repo;
  final FilePickerService _filePicker;
  final ApplicationsViewModel _applications;
  final AuthViewModel _auth;

  /// True until the first fetch finishes (also while a refresh is running).
  bool refreshing = true;

  /// True while a replace / resubmit request is running.
  bool working = false;

  bool deleted = false;

  /// The letter PDF, loaded once the application is approved/rejected
  /// and the school has generated the letter. Null = no letter yet.
  Uint8List? letterBytes;
  bool downloadingLetter = false;
  bool _letterPromptShown = false;

  bool get shouldAutoShowLetter => letterBytes != null && !_letterPromptShown;
  void markLetterPromptShown() => _letterPromptShown = true;

  /// The latest copy of this application, or null if not loaded yet.
  EnrolmentApplication? get application => _applications.byId(applicationId);

  Future<void> refresh() async {
    if (!refreshing) {
      refreshing = true;
      notifyListeners();
    }
    await _applications.refreshOne(applicationId);
    await _loadLetter();
    refreshing = false;
    notifyListeners();
  }

  Future<void> _loadLetter() async {
    final app = application;
    final decided =
        app != null &&
        (app.status == ApplicationStatus.approved ||
            app.status == ApplicationStatus.rejected);
    if (!decided) {
      letterBytes = null;
      return;
    }
    if (letterBytes != null) return;
    try {
      letterBytes = await _repo.downloadConfirmationLetter(applicationId);
    } catch (_) {
      letterBytes = null; // school hasn't generated it yet
    }
  }

  /// Lets the parent pick a new file for [type] and uploads it.
  /// Returns a message to show, or null if the parent cancelled.
  Future<String?> replaceDocument(DocumentType type) async {
    final uid = _auth.userId;
    if (uid == null) return null;
    PickedDocument? file;
    try {
      file = await _filePicker.pickDocument();
    } catch (e) {
      return AppError.message(e);
    }
    if (file == null) return null;
    working = true;
    notifyListeners();
    try {
      await _repo.replaceDocument(
        userId: uid,
        applicationId: applicationId,
        type: type,
        file: file,
      );
      await refresh();
      return '${type.label} replaced.';
    } catch (e) {
      return AppError.message(e);
    } finally {
      working = false;
      notifyListeners();
    }
  }

  /// Saves the letter on the phone. Returns true on success.
  Future<bool> saveLetter() async {
    final bytes = letterBytes;
    if (bytes == null) return false;
    downloadingLetter = true;
    notifyListeners();
    try {
      final ref = (application?.referenceNumber ?? applicationId).replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );
      await FileSaver.instance.saveFile(
        name: 'Confirmation-$ref',
        bytes: bytes,
        fileExtension: 'pdf', // older file_saver versions use: ext: 'pdf'
        mimeType: MimeType.pdf,
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      downloadingLetter = false;
      notifyListeners();
    }
  }

  /// Sends a corrected application back to the school. Returns a message.
  Future<String> resubmitForReview() async {
    working = true;
    notifyListeners();
    try {
      await _repo.resubmitForReview(applicationId);
      await refresh();
      return 'Your application was sent back to the school for review.';
    } catch (e) {
      return AppError.message(e);
    } finally {
      working = false;
      notifyListeners();
    }
  }

  /// Returns null on success, otherwise the error message to show.
  Future<String?> deleteApplication() async {
    final app = application;
    if (app == null) return 'This application is not loaded yet.';
    working = true;
    notifyListeners();
    try {
      await _applications.deleteApplication(app);
      deleted = true;
      return null;
    } catch (e) {
      return AppError.message(e);
    } finally {
      working = false;
      notifyListeners();
    }
  }
}
