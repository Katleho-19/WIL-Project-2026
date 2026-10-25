//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: file_picker_service.dart opens the device's file chooser so the parent can pick
// a supporting document or proof of payment, and checks that it is a valid file.

import 'package:file_picker/file_picker.dart';

import '../../models/picked_document.dart';

/// Lets the parent choose a JPG, PNG or PDF (max 5 MB) from the device.
///
/// FilePickerService (class) - wrapper around the file_picker plugin.
class FilePickerService {
  /// pickDocument() - shows the file chooser limited to JPG, JPEG, PNG and PDF, allowing one file
  /// and loading its bytes into memory. If the parent cancels it returns null; otherwise it
  /// validates the file through PickedDocument.create() (type and 5 MB limit) and returns it.
  /// Returns null if the parent cancelled. Throws [AppException] when the
  /// chosen file is the wrong type or too large.
  Future<PickedDocument?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: PickedDocument.allowedExtensions,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.first;
    return PickedDocument.create(f.name, f.bytes);
  }
}
