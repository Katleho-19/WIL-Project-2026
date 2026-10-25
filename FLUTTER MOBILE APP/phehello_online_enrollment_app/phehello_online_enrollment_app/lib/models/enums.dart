//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

// FILE PURPOSE: enums.dart holds the fixed sets of values used across the app: the application
// status, the payment verification status, the required document types and the notification
// types. Keeping them here means the status text is never scattered through the UI.

/// Application status vocabulary (SRS sequence diagrams / wireframes).
/// All status strings live here so they are never scattered through the UI.
///
/// ApplicationStatus (enum) - the four stages an enrolment application can be in.
/// Each value carries dbValue, the exact text stored in the database.
enum ApplicationStatus {
  pendingAdminReview('Pending Admin Review'),
  correctionsRequested('Corrections Requested'),
  approved('Approved'),
  rejected('Rejected');

  /// Constructor - stores the database text for each enum value.
  const ApplicationStatus(this.dbValue);

  /// dbValue - the status text exactly as stored in the database.
  final String dbValue;

  /// fromDb() - converts the raw status text from the database into an ApplicationStatus.
  /// The text is trimmed and lower-cased so small spelling/casing differences still match;
  /// anything unknown (or null) falls back to pendingAdminReview.
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

  /// chipLabel (getter) - the short label shown on the coloured status chip
  /// ("Pending", "Corrections", "Approved", "Rejected").
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

  /// bannerDescription (getter) - the friendly sentence shown in the status banner on the
  /// application details screen, explaining what the status means for the parent.
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

  /// isPendingGroup (getter) - true for pending and corrections-requested applications.
  /// "Pending" tab on My Applications groups pending + corrections.
  bool get isPendingGroup =>
      this == ApplicationStatus.pendingAdminReview ||
      this == ApplicationStatus.correctionsRequested;
}

/// Verification status of a proof-of-payment record.
///
/// PaymentVerificationStatus (enum) - whether the Financial Clerk has checked the parent's proof of payment.
enum PaymentVerificationStatus {
  pending('Pending'),
  verified('Verified'),
  rejected('Rejected');

  /// Constructor - stores the database text for each value.
  const PaymentVerificationStatus(this.dbValue);

  /// dbValue - the status text exactly as stored in the database.
  final String dbValue;

  /// fromDb() - converts database text to a PaymentVerificationStatus;
  /// "verified" and "rejected" are matched (ignoring case), everything else becomes pending.
  static PaymentVerificationStatus fromDb(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    if (v == 'verified') return PaymentVerificationStatus.verified;
    if (v == 'rejected') return PaymentVerificationStatus.rejected;
    return PaymentVerificationStatus.pending;
  }

  /// chipLabel (getter) - the label for the status chip (same as the database text).
  String get chipLabel => dbValue;

  /// parentLabel (getter) - the wording used on parent-facing screens for each payment status.
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

  /// documentSubtitle (getter) - the small subtitle shown under the proof-of-payment entry
  /// in the documents list.
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
///
/// DocumentType (enum) - the kinds of supporting documents a parent uploads.
/// Each one has a display label, a hint, and whether it is compulsory.
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

  /// Constructor - assigns the label, hint and required flag to each document type.
  const DocumentType({
    required this.label,
    required this.hint,
    required this.isRequired,
  });

  /// label - the name shown to the parent.
  final String label;

  /// hint - short helper text shown under the label (e.g. "Required", "If applicable").
  final String hint;

  /// isRequired - true if the application cannot be submitted without this document.
  final bool isRequired;

  /// dbValue (getter) - the text stored in application_documents.document_type.
  /// It equals the label, except the progress report which is stored as
  /// "Previous School Progress Report".
  String get dbValue {
    switch (this) {
      case DocumentType.progressReport:
        return 'Previous School Progress Report';
      default:
        return label;
    }
  }

  /// fromDb() - converts stored document-type text back into a DocumentType by matching
  /// either dbValue or label (ignoring case). Returns null if nothing matches.
  static DocumentType? fromDb(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    for (final t in DocumentType.values) {
      if (t.dbValue.toLowerCase() == v || t.label.toLowerCase() == v) return t;
    }
    return null;
  }
}

/// notifications.notification_type values.
///
/// NotificationType (class) - string constants for the kinds of notification stored in the database.
/// The private constructor prevents creating instances; use NotificationType.message etc.
class NotificationType {
  NotificationType._();
  static const String message = 'message'; // a direct message from school staff
  static const String reminder = 'reminder'; // a reminder to the parent
  static const String statusUpdate =
      'status_update'; // an application status change
  static const String system = 'system'; // an automatic system message
}
