//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: application_document.dart defines ApplicationDocument, one supporting document
// (e.g. birth certificate) that has been uploaded for an application.

import '../utils/formatters.dart';
import 'enums.dart';

/// ApplicationDocument (class) - an immutable record of one uploaded document.
class ApplicationDocument {
  /// Constructor - all fields are required except uploadedAt.
  const ApplicationDocument({
    required this.id,
    required this.applicationId,
    required this.documentType,
    required this.fileName,
    required this.storagePath,
    this.uploadedAt,
  });

  final String id;
  final String applicationId;
  final String documentType;
  final String fileName;
  final String storagePath;
  final DateTime? uploadedAt;

  /// type (getter) - converts the stored documentType text into a DocumentType enum value
  /// (or null if it is not recognised).
  DocumentType? get type => DocumentType.fromDb(documentType);

  /// ApplicationDocument.fromMap() - factory that builds a document from a database row,
  /// using empty text for missing values and parsing the upload time into a DateTime.
  factory ApplicationDocument.fromMap(Map<String, dynamic> m) =>
      ApplicationDocument(
        id: (m['document_id'] ?? m['id'] ?? '') as String,
        applicationId: (m['application_id'] ?? '') as String,
        documentType: (m['document_type'] as String?) ?? '',
        fileName: (m['file_name'] as String?) ?? '',
        storagePath: (m['storage_path'] as String?) ?? '',
        uploadedAt: Formatters.parseDateTime(m['uploaded_at']),
      );
}
