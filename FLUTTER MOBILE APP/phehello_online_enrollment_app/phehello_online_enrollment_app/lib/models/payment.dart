//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: payment.dart defines Payment, one proof-of-payment record uploaded by the parent
// for an application, including its reference, amount, file details and verification status.

import '../utils/formatters.dart';
import 'enums.dart';

/// Payment (class) - an immutable record of one proof-of-payment submission.
class Payment {
  /// Constructor - the core fields are required; notes and createdAt are optional.
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

  /// Payment.fromMap() - factory that builds a Payment from a database row.
  /// The amount is parsed to a double (0 if invalid), the status text is converted with
  /// PaymentVerificationStatus.fromDb, and the creation time is parsed into a DateTime.
  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
    id: (m['payment_id'] ?? m['id'] ?? '') as String,
    applicationId: (m['application_id'] ?? '') as String,
    reference: (m['payment_reference'] as String?) ?? '',
    amount: double.tryParse('${m['amount'] ?? 0}') ?? 0,
    proofFileName: (m['proof_file_name'] as String?) ?? '',
    proofStoragePath: (m['proof_storage_path'] as String?) ?? '',
    status: PaymentVerificationStatus.fromDb(
      m['verification_status'] as String?,
    ),
    notes: m['verification_notes'] as String?,
    createdAt: Formatters.parseDateTime(m['created_at']),
  );
}
