import '../utils/formatters.dart';
import 'enums.dart';

class Payment {
  const Payment({
    required this.id,
    required this.applicationId,
    required this.reference,
    required this.amount,
    required this.proofFileName,
    required this.proofStoragePath,
    required this.status,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String applicationId;
  final String reference;
  final double amount;
  final String proofFileName;
  final String proofStoragePath;
  final PaymentVerificationStatus status;
  final String? notes;
  final DateTime? createdAt;

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: (m['payment_id'] ?? m['id'] ?? '') as String,
        applicationId: (m['application_id'] ?? '') as String,
        reference: (m['payment_reference'] as String?) ?? '',
        amount: double.tryParse('${m['amount'] ?? 0}') ?? 0,
        proofFileName: (m['proof_file_name'] as String?) ?? '',
        proofStoragePath: (m['proof_storage_path'] as String?) ?? '',
        status: PaymentVerificationStatus.fromDb(
            m['verification_status'] as String?),
        notes: m['verification_notes'] as String?,
        createdAt: Formatters.parseDateTime(m['created_at']),
      );
}
