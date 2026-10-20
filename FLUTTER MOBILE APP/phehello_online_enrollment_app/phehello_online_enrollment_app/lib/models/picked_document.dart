//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import 'dart:typed_data';

import '../config/school_info.dart';
import '../utils/app_error.dart';

/// A file chosen by the parent (kept in memory until it is uploaded).
class PickedDocument {
  const PickedDocument({
    required this.name,
    required this.bytes,
    required this.extension,
  });

  final String name;
  final Uint8List bytes;
  final String extension;

  int get size => bytes.length;
  bool get isImage => const ['jpg', 'jpeg', 'png'].contains(extension);

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

  static const allowedExtensions = ['jpg', 'jpeg', 'png', 'pdf'];

  /// Validates type and size (JPG, PNG or PDF, max 5 MB).
  static PickedDocument create(String name, Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) {
      throw AppException('That file could not be read. Please choose it again.');
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
