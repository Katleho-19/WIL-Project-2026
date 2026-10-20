/// Application status vocabulary (SRS sequence diagrams / wireframes).
/// All status strings live here so they are never scattered through the UI.
enum ApplicationStatus {
  pendingAdminReview('Pending Admin Review'),
  correctionsRequested('Corrections Requested'),
  approved('Approved'),
  rejected('Rejected');

  const ApplicationStatus(this.dbValue);
  final String dbValue;

  static ApplicationStatus fromDb(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    switch (v) {
      case 'approved':
        return ApplicationStatus.approved;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'corrections requested':
      case 'correction requested':
        return ApplicationStatus.correctionsRequested;
      default:
        // 'Pending Admin Review' / 'Pending Admin View' / anything else.
        return ApplicationStatus.pendingAdminReview;
    }
  }

  /// Short label for chips ("Pending", "Approved", "Rejected").
  String get chipLabel {
    switch (this) {
      case ApplicationStatus.pendingAdminReview:
        return 'Pending';
      case ApplicationStatus.correctionsRequested:
        return 'Corrections';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  String get bannerDescription {
    switch (this) {
      case ApplicationStatus.pendingAdminReview:
        return 'Your application is currently being reviewed by the school.';
      case ApplicationStatus.correctionsRequested:
        return 'The school needs corrections. Please check your messages and '
            'replace the documents that were queried.';
      case ApplicationStatus.approved:
        return 'Congratulations! Your application has been approved.';
      case ApplicationStatus.rejected:
        return 'Unfortunately your application was not successful.';
    }
  }

  /// "Pending" tab on My Applications groups pending + corrections.
  bool get isPendingGroup =>
      this == ApplicationStatus.pendingAdminReview ||
      this == ApplicationStatus.correctionsRequested;
}

/// Verification status of a proof-of-payment record.
enum PaymentVerificationStatus {
  pending('Pending'),
  verified('Verified'),
  rejected('Rejected');

  const PaymentVerificationStatus(this.dbValue);
  final String dbValue;

  static PaymentVerificationStatus fromDb(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'verified') return PaymentVerificationStatus.verified;
    if (v == 'rejected') return PaymentVerificationStatus.rejected;
    return PaymentVerificationStatus.pending;
  }

  String get chipLabel => dbValue;

  /// Text used on the parent-facing screens.
  String get parentLabel {
    switch (this) {
      case PaymentVerificationStatus.pending:
        return 'Pending verification';
      case PaymentVerificationStatus.verified:
        return 'Payment verified';
      case PaymentVerificationStatus.rejected:
        return 'Payment rejected - please upload a new proof';
    }
  }

  String get documentSubtitle {
    switch (this) {
      case PaymentVerificationStatus.pending:
        return 'Awaiting Financial Clerk verification';
      case PaymentVerificationStatus.verified:
        return 'Verified by the Financial Clerk';
      case PaymentVerificationStatus.rejected:
        return 'Rejected - please upload a new proof of payment';
    }
  }
}

/// Supporting documents required by the school's enrolment form (FR3).
enum DocumentType {
  birthCertificate(
    label: 'Birth Certificate',
    hint: 'Required',
    isRequired: true,
  ),
  progressReport(
    label: 'Progress Report',
    hint: 'Previous-school report',
    isRequired: true,
  ),
  immunisationRecord(
    label: 'Immunisation Record',
    hint: 'Required',
    isRequired: true,
  ),
  transferLetter(
    label: 'Transfer Letter',
    hint: 'If applicable',
    isRequired: false,
  );

  const DocumentType({
    required this.label,
    required this.hint,
    required this.isRequired,
  });

  final String label;
  final String hint;
  final bool isRequired;

  /// Value stored in application_documents.document_type.

  /// Value stored in application_documents.document_type.
  String get dbValue {
    switch (this) {
      case DocumentType.progressReport:
        return 'Previous School Progress Report';
      default:
        return label;
    }
  }

  static DocumentType? fromDb(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    for (final t in DocumentType.values) {
      if (t.dbValue.toLowerCase() == v || t.label.toLowerCase() == v) return t;
    }
    return null;
  }
}

/// notifications.notification_type values.
class NotificationType {
  NotificationType._();
  static const String message = 'message';
  static const String reminder = 'reminder';
  static const String statusUpdate = 'status_update';
  static const String system = 'system';
}
