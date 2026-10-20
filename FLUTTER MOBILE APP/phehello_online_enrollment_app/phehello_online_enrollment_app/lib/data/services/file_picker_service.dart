import 'package:file_picker/file_picker.dart';

import '../../models/picked_document.dart';

/// Lets the parent choose a JPG, PNG or PDF (max 5 MB) from the device.
class FilePickerService {
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
