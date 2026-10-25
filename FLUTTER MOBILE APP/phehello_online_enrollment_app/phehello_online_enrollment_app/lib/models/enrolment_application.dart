//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: enrolment_application.dart defines EnrolmentApplication, the main model for one
// enrolment application together with its learner, medical info, documents, payments and
// status history, plus helpers to read it from a Supabase (PostgREST) response.

import '../utils/formatters.dart';
import 'application_document.dart';
import 'enums.dart';
import 'learner.dart';
import 'payment.dart';
import 'status_history_entry.dart';

/// One enrolment application with its learner, documents and payments.
///
/// EnrolmentApplication (class) - an immutable record of a submitted application.
class EnrolmentApplication {
  /// Constructor - id, reference number, statuses and grade are required;
  /// the learner, medical info and submission date are optional and the lists default to empty.
  const EnrolmentApplication({
    required this.id,
    required this.referenceNumber,
    required this.status,
    required this.paymentStatus,
    required this.gradeApplied,
    this.submittedAt,
    this.learner,
    this.medical,
    this.documents = const [],
    this.payments = const [],
    this.history = const [],
  });

  final String id;
  final String referenceNumber;
  final ApplicationStatus status;
  final PaymentVerificationStatus paymentStatus;
  final String gradeApplied;
  final DateTime? submittedAt;
  final Learner? learner;
  final LearnerMedicalInfo? medical;
  final List<ApplicationDocument> documents;
  final List<Payment> payments;
  final List<StatusHistoryEntry> history;

  /// latestPayment (getter) - returns the newest payment attempt, or null if there are none.
  /// It copies the list, sorts it newest-first by createdAt (missing dates count as the oldest)
  /// and returns the first item.
  /// Most recent payment attempt (a new row is inserted per re-upload).
  Payment? get latestPayment {
    if (payments.isEmpty) return null;
    final sorted = [...payments]
      ..sort((a, b) {
        final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return db.compareTo(da);
      });
    return sorted.first;
  }

  /// documentOfType() - finds the uploaded document of the given DocumentType
  /// (e.g. birth certificate). Returns null if that document has not been uploaded.
  ApplicationDocument? documentOfType(DocumentType t) {
    for (final d in documents) {
      if (d.type == t) return d;
    }
    return null;
  }

  /// subtitle (getter) - the one-line summary shown on application cards, for example
  /// "Grade 8 • Submitted 12 Oct 2026". The grade is left out if empty and the date is left
  /// out (just "Submitted") if there is no submission time.
  String get subtitle {
    final grade = gradeApplied.isEmpty ? '' : '$gradeApplied • ';
    final date = submittedAt == null
        ? 'Submitted'
        : 'Submitted ${Formatters.shortDate(submittedAt!)}';
    return '$grade$date';
  }

  /// _asMap() - private helper that turns a value from the response into a Map.
  /// PostgREST may return an embedded record as a Map or as a one-item List, so both are handled;
  /// anything else returns null.
  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is List && v.isNotEmpty && v.first is Map) {
      return Map<String, dynamic>.from(v.first as Map);
    }
    return null;
  }

  /// _asList() - private helper that turns a value into a list of Maps (only the Map items are kept).
  /// Returns an empty list if the value is not a List.
  static List<Map<String, dynamic>> _asList(dynamic v) {
    if (v is List) {
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  /// Builds an application from a PostgREST row with embedded relations:
  /// `learners(*, learner_medical_info(*))`, `application_documents(*)`,
  /// `payments(*)`, `application_status_history(*)`.
  ///
  /// EnrolmentApplication.fromMap() - factory that reads the application row and converts each
  /// embedded relation (learner, medical info, documents, payments, history) into its model class.
  /// If the row has no reference number, one is generated as "PH-" plus the first 8 characters
  /// of the id in upper case.
  factory EnrolmentApplication.fromMap(Map<String, dynamic> m) {
    final id = (m['application_id'] ?? m['id'] ?? '') as String;
    final learnerMap = _asMap(m['learners']);
    final medicalMap = learnerMap == null
        ? null
        : _asMap(learnerMap['learner_medical_info']);
    final shortId = id.length >= 8 ? id.substring(0, 8).toUpperCase() : id;
    return EnrolmentApplication(
      id: id,
      referenceNumber: (m['reference_number'] as String?) ?? 'PH-$shortId',
      status: ApplicationStatus.fromDb(m['status'] as String?),
      paymentStatus: PaymentVerificationStatus.fromDb(
        m['payment_verification_status'] as String?,
      ),
      gradeApplied: (m['grade_applied_for'] as String?) ?? '',
      submittedAt: Formatters.parseDateTime(m['submitted_at']),
      learner: learnerMap == null ? null : Learner.fromMap(learnerMap),
      medical: medicalMap == null
          ? null
          : LearnerMedicalInfo.fromMap(medicalMap),
      documents: _asList(
        m['application_documents'],
      ).map(ApplicationDocument.fromMap).toList(),
      payments: _asList(m['payments']).map(Payment.fromMap).toList(),
      history: _asList(
        m['application_status_history'],
      ).map(StatusHistoryEntry.fromMap).toList(),
    );
  }
}
