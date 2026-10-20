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
