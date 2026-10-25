//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: picked_document.dart defines PickedDocument, a file the parent has chosen from
// their device (kept in memory until uploaded), and validates its type and size.

import 'dart:typed_data';

import '../config/school_info.dart';
import '../utils/app_error.dart';

/// A file chosen by the parent (kept in memory until it is uploaded).
///
/// PickedDocument (class) - holds the file's name, raw bytes and extension.
class PickedDocument {
  /// Constructor - all three fields are required.
  const PickedDocument({
    required this.name,
    required this.bytes,
    required this.extension,
  });

  final String name;
  final Uint8List bytes;
  final String extension;

  /// size (getter) - the file size in bytes.
  int get size => bytes.length;

  /// isImage (getter) - true if the extension is jpg, jpeg or png (so a preview can be shown).
  bool get isImage => const ['jpg', 'jpeg', 'png'].contains(extension);

  /// contentType (getter) - the MIME type sent when uploading:
  /// application/pdf for PDFs, image/png for PNGs and image/jpeg for everything else.
  String get contentType {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  /// allowedExtensions - the file types the parent may upload.
  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  /// create() - validates a chosen file and builds a PickedDocument (JPG, PNG or PDF, max 5 MB).
  /// Throws an AppException with a friendly message if the file is empty/unreadable,
  /// has a disallowed extension, or is larger than SchoolInfo.maxFileBytes.
  static PickedDocument create(String name, Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      throw AppException(
        'That file could not be read. Please choose it again.',
      );
    }
    final dot = name.lastIndexOf('.');
    final ext = dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      throw AppException('Please choose a JPG, PNG or PDF file.');
    }
    if (bytes.length > SchoolInfo.maxFileBytes) {
      throw AppException('This file is too large. The maximum size is 5 MB.');
    }
    return PickedDocument(name: name, bytes: bytes, extension: ext);
  }
}
