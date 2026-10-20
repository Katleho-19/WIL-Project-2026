//Project name: Phehello Enrolment App
//Group name: Ctrl+Alt+Del
//Group members: KI Makhoali, PIJ Lebusa, RL Mahlatsi, M Lepitla, MM Motaung, DT Adegbola
//Student numbers: 224131387, 221000537, 220049867, 222018199, 224074632, 220042034

/// Central place for Supabase table / bucket / function names, following the
/// SRS ERD (Part D). If the shared database differs, change them here only.
class Db {
  Db._();

  static const String bucket = 'enrolment-documents';

  static const String profiles = 'profiles';
  static const String applications = 'applications';
  static const String notifications = 'notifications';

  static const String rpcSubmit = 'submit_enrolment';
  static const String rpcReplaceDocument = 'replace_document';
  static const String rpcResubmitPayment = 'resubmit_payment_proof';
  static const String rpcResubmitReview = 'resubmit_for_review';
  static const String rpcDeleteApplication = 'delete_application';
}
