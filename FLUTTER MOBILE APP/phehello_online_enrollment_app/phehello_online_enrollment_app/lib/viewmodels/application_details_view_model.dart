//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: application_details_view_model.dart holds the state and actions of the
// Application Details screen (FR5): refreshing one application, loading and saving the
// confirmation letter, replacing documents, resubmitting for review and deleting the application.

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
///
/// ApplicationDetailsViewModel (class) - logic for the screen showing one application.
class ApplicationDetailsViewModel extends BaseViewModel {
  /// Constructor - receives the application id and the repository, file picker, applications
  /// view model and auth view model it needs; the services are stored in private fields.
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

  /// deleted - becomes true after this application has been deleted, so the screen can close itself.
  bool deleted = false;

  /// The letter PDF, loaded once the application is approved/rejected
  /// and the school has generated the letter. Null = no letter yet.
  Uint8List? letterBytes;

  /// downloadingLetter - true while the letter is being saved to the phone.
  bool downloadingLetter = false;

  /// _letterPromptShown - remembers that the letter pop-up has already been shown once.
  bool _letterPromptShown = false;

  /// shouldAutoShowLetter (getter) - true when a letter is available and its pop-up has not been shown yet.
  bool get shouldAutoShowLetter => letterBytes != null && !_letterPromptShown;

  /// markLetterPromptShown() - records that the letter pop-up has been shown so it is not repeated.
  void markLetterPromptShown() => _letterPromptShown = true;

  /// The latest copy of this application, or null if not loaded yet.
  EnrolmentApplication? get application => _applications.byId(applicationId);

  /// refresh() - reloads this application from the server (via ApplicationsViewModel) and then
  /// tries to load the confirmation letter; the 'refreshing' flag is on while this runs.
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

  /// _loadLetter() - private method that downloads the confirmation letter PDF, but only when the
  /// application has been decided (approved or rejected). If it is not decided the letter is
  /// cleared; if already downloaded it is kept; if the download fails (the school has not
  /// generated it yet) the letter stays null.
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

  /// replaceDocument() - replaces one supporting document. It opens the file picker (an invalid
  /// file returns a readable error message; cancelling returns null), uploads the new file through
  /// the repository, refreshes the application and returns "<document name> replaced." On failure
  /// it returns a readable message. The 'working' flag is on during the upload.
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

  /// saveLetter() - saves the confirmation letter PDF to the phone using the file_saver plugin.
  /// The file is named "Confirmation-<reference number>" (unsafe characters are replaced with "_").
  /// Returns true on success and false if there is no letter or saving fails.
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

  /// resubmitForReview() - sends the corrected application back to the school through the
  /// repository, refreshes it and returns a confirmation message (or a readable error message).
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

  /// deleteApplication() - deletes this application through ApplicationsViewModel and sets
  /// 'deleted' to true so the screen can close. Returns null on success, otherwise an error
  /// message (including "not loaded yet" if the application is not available).
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
