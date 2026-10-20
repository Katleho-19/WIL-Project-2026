//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

import '../utils/formatters.dart';
import 'enums.dart';

class ApplicationDocument {
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

  DocumentType? get type => DocumentType.fromDb(documentType);

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
